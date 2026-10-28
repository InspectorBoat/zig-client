/// Takes ownership of resource_pack_dir

pub fn init(
    io: std.Io,
    gpa: std.mem.Allocator,
    arena: std.mem.Allocator,
    resource_pack_dir: std.Io.Dir,
) !struct {
    std.AutoHashMapUnmanaged(Block.VirtualState, BakedModel),
    std.AutoHashMapUnmanaged(u16, BakedItemModel),
    std.array_hash_map.String(ImageError!zigimg.Image),
} {
    const total: std.Io.Timestamp = .now(io, .real);
    defer std.log.scoped(.resource_pack).debug("resource pack loading took {} ms", .{total.untilNow(io, .real).toMilliseconds()});

    var start: std.Io.Timestamp = .now(io, .real);

    const state_to_model_maps = try parseJsonInDir(
        StateToModelMap,
        StateError,
        io,
        arena,
        try resource_pack_dir.openDir(io, "assets/minecraft/blockstates", .{ .iterate = true }),
    );

    std.log.scoped(.resource_pack).debug("state_to_model_maps took {} ms", .{start.untilNow(io, .real).toMilliseconds()});
    start = .now(io, .real);

    const model_templates = try parseJsonInDir(
        ModelTemplate,
        TemplateError,
        io,
        arena,
        try resource_pack_dir.openDir(io, "assets/minecraft/models", .{ .iterate = true }),
    );

    std.log.scoped(.resource_pack).debug("model_templates took {} ms", .{start.untilNow(io, .real).toMilliseconds()});
    start = .now(io, .real);

    try validateTemplates(gpa, model_templates);

    std.log.scoped(.resource_pack).debug("validate took {} ms", .{start.untilNow(io, .real).toMilliseconds()});
    start = .now(io, .real);

    const textures = try loadImagesInDir(
        io,
        arena,
        try resource_pack_dir.openDir(io, "assets/minecraft/textures", .{ .iterate = true }),
    );

    std.log.scoped(.resource_pack).debug("textures took {} ms", .{start.untilNow(io, .real).toMilliseconds()});
    start = .now(io, .real);

    const resolved_models = try resolveModels(arena, model_templates, textures);

    std.log.scoped(.resource_pack).debug("resolve took {} ms", .{start.untilNow(io, .real).toMilliseconds()});
    start = .now(io, .real);

    const block_state_to_model_table = try createBlockStateToModelTable(gpa, textures, resolved_models, state_to_model_maps);

    std.log.scoped(.resource_pack).debug("block_state_to_model took {} ms", .{start.untilNow(io, .real).toMilliseconds()});
    start = .now(io, .real);

    const item_stack_to_model_table = try createItemStackToModelTable(gpa, textures, resolved_models);

    std.log.scoped(.resource_pack).debug("item_stack_to_model took {} ms", .{start.untilNow(io, .real).toMilliseconds()});

    return .{
        block_state_to_model_table,
        item_stack_to_model_table,
        textures,
    };
}

/// Recursively parses all files in a directory from JSON into T
/// Takes ownership of dir
pub fn parseJsonInDir(T: type, E: type, io: std.Io, arena: std.mem.Allocator, dir: std.Io.Dir) !std.array_hash_map.String(E!T) {
    defer dir.close(io);
    var states: std.array_hash_map.String(E!T) = .empty;

    var iter = try dir.walk(arena);
    while (try iter.next(io)) |entry| {
        if (entry.kind != .file) continue;

        const file = try dir.openFile(io, entry.path, .{});
        defer file.close(io);

        var buf: [1024]u8 = undefined;
        var file_reader = file.reader(io, &buf);

        var reader: std.json.Reader = .init(arena, &file_reader.interface);
        defer reader.deinit();
        const parsed_model = std.json.parseFromTokenSourceLeaky(T, arena, &reader, .{ .ignore_unknown_fields = true }) catch |e| switch (e) {
            error.OutOfMemory => return error.OutOfMemory,
            else => error.SyntaxError,
        };

        try states.put(arena, try arena.dupe(u8, entry.path[0 .. entry.path.len - ".json".len]), parsed_model);
    }
    return states;
}

pub const StateError = error{SyntaxError};

pub const TemplateError = error{
    Malformed,
    Orphaned,
    Cycle,
    SyntaxError,

    MalformedAncestor,
    OrphanedAncestor,
    CyclicAncestor,
    SyntaxErrorAncestor,
};

/// Detects:
/// - Templates that are part of, or feed into cycles
/// - Orphaned (and transitively orphaned) templates
///     - An orphaned template is a template with a missing parent
/// - Malformed (and transitively malformed) templates
///     - A template is malformed if it has both a parent and elements,
///     - or has neither a parent nor elements
pub fn validateTemplates(
    gpa: std.mem.Allocator,
    templates: std.array_hash_map.String(TemplateError!ModelTemplate),
) !void {
    const Node = enum(u8) {
        unvisited,
        current_path,

        ok,

        malformed,
        syntax_error,
        orphaned,
        cycle,
    };
    const nodes: []Node = try gpa.alloc(Node, templates.count());
    defer gpa.free(nodes);
    @memset(nodes, .unvisited);

    var stack: std.ArrayList(usize) = .empty;
    defer stack.deinit(gpa);

    var visited: usize = 0;
    defer std.debug.assert(visited == templates.count());

    for (0..templates.count()) |i| {
        stack.items.len = 0;

        var index: usize = i;

        if (nodes[index] != .unvisited) continue;

        const path_result: Node, const maybe_error_index: ?usize = while (true) switch (nodes[index]) {
            // This is the only branch where we find a *new* cycle
            // as opposed to feeding into an existing one
            .current_path => {
                std.log.scoped(.resource_pack).err("Found cyclic model dependency!", .{});
                // Print all the elements of the cycle

                const cycle_start = std.mem.findScalar(usize, stack.items, index).?;

                for (stack.items[cycle_start..]) |walked_index| {
                    std.log.scoped(.resource_pack).err("{s} depends on {s}", .{
                        templates.keys()[walked_index],
                        (templates.values()[walked_index] catch unreachable).parent.?,
                    });
                }

                break .{ .cycle, cycle_start };
            },
            .cycle => break .{ .cycle, null },
            .malformed => break .{ .malformed, null },
            .orphaned => break .{ .orphaned, null },
            .syntax_error => break .{ .syntax_error, null },
            .ok => break .{ .ok, null },
            .unvisited => {
                try stack.append(gpa, index);
                nodes[index] = .current_path;
                visited += 1;

                if (templates.values()[index]) |*template| {
                    const name = templates.keys()[index];
                    if (template.elements == null and template.parent == null) {
                        std.log.scoped(.resource_pack).err("{s} has no parent or elements", .{name});
                        templates.values()[index] = error.Malformed;
                    } else if (template.elements != null and template.parent != null) {
                        std.log.scoped(.resource_pack).err("{s} declares both parent and elements", .{name});
                        break .{ .malformed, stack.items.len - 1 };
                    } else if (template.elements) |elements| {
                        for (elements, 0..) |element, j| {
                            inline for (std.enums.values(Direction)) |dir| {
                                if (@field(element.faces, @tagName(dir)) != null) break;
                            } else std.log.scoped(.resource_pack).warn("element {} of {s} has no faces", .{ j, name });
                        }
                    }

                    if (template.parent) |parent| {
                        if (std.mem.eql(u8, "builtin/generated", parent) or
                            std.mem.eql(u8, "builtin/entity", parent) or
                            std.mem.eql(u8, "builtin/compass", parent) or
                            std.mem.eql(u8, "builtin/clock", parent))
                            break .{ .ok, null };

                        index = templates.getIndex(parent) orelse break .{ .orphaned, stack.items.len - 1 };
                    } else break .{ .ok, null };
                } else |e| switch (e) {
                    error.SyntaxError => break .{ .syntax_error, stack.items.len - 1 },
                    else => unreachable,
                }
            },
        };

        for (stack.items) |walked_index| nodes[walked_index] = path_result;
        switch (path_result) {
            .cycle, .malformed, .orphaned, .syntax_error => |e| {
                for (stack.items[0 .. maybe_error_index orelse stack.items.len]) |walked_index| {
                    templates.values()[walked_index] = switch (e) {
                        .cycle => error.CyclicAncestor,
                        .malformed => error.MalformedAncestor,
                        .orphaned => error.OrphanedAncestor,
                        .syntax_error => error.SyntaxErrorAncestor,
                        else => unreachable,
                    };
                }
                if (maybe_error_index) |error_index| for (stack.items[error_index..]) |walked_index| {
                    templates.values()[walked_index] = switch (e) {
                        .cycle => error.Cycle,
                        .malformed => error.Malformed,
                        .orphaned => error.Orphaned,
                        .syntax_error => error.SyntaxError,
                        else => unreachable,
                    };
                };
            },
            .ok => {},
            .unvisited, .current_path => unreachable,
        }
    }
}

pub const ModelError = TemplateError || error{
    CyclicVariable,
    FailedUvMapping,
    MissingTexture,
    BrokenTexture,
    Incomplete,
};

/// Resolves all block model templates parsed in the previous step.
pub fn resolveModels(
    arena: std.mem.Allocator,
    templates: std.array_hash_map.String(TemplateError!ModelTemplate),
    textures: std.array_hash_map.String(ImageError!zigimg.Image),
) !std.array_hash_map.String(ModelError!ResolvedModel) {
    var models: std.array_hash_map.String(ModelError!ResolvedModel) = .empty;

    for (templates.keys(), templates.values()) |name, template| {
        if (template) |working_template| {
            const model = resolveTemplate(arena, working_template, templates, textures) catch |e| switch (e) {
                error.OutOfMemory => return error.OutOfMemory,
                error.MissingTextureVariableReference => error.Incomplete,
                inline else => |known_e| known_e,
            };
            try models.put(arena, name, model);
        } else |err| {
            try models.put(arena, name, err);
        }
    }
    return models;
}

/// Takes (the name of) a block model template and walks the parent chain,
/// resolving all texture references, ambient occlusion, and elements
pub fn resolveTemplate(
    arena: std.mem.Allocator,
    template: ModelTemplate,
    templates: std.array_hash_map.String(TemplateError!ModelTemplate),
    textures: std.array_hash_map.String(ImageError!zigimg.Image),
) !ResolvedModel {
    var merged_template: struct {
        texture_variables: std.array_hash_map.String([]const u8) = .empty,
        geometry: ?union(enum) {
            elements: []ModelTemplate.Element,
            generated_item,
        } = null,
        ambient_occlusion: ?bool = null,
        display: ModelTemplate.Display = .{},
    } = .{};

    // first: walk the parent chain and merge texture variable maps and elements
    var template_lineage: ModelTemplate = template;
    while (true) {
        if (template_lineage.textures) |texture_variables| {
            for (texture_variables.map.keys(), texture_variables.map.values()) |key, value| {
                try merged_template.texture_variables.put(arena, key, value);
            }
        }

        std.debug.assert(merged_template.geometry == null);
        if (template_lineage.elements) |elements| merged_template.geometry = .{ .elements = elements };
        if (merged_template.ambient_occlusion == null) merged_template.ambient_occlusion = template_lineage.ambientocclusion;
        if (template_lineage.display) |display| {
            if (merged_template.display.thirdperson == null) merged_template.display.thirdperson = display.thirdperson;
            if (merged_template.display.firstperson == null) merged_template.display.firstperson = display.firstperson;
            if (merged_template.display.gui == null) merged_template.display.gui = display.gui;
            if (merged_template.display.head == null) merged_template.display.head = display.head;
            if (merged_template.display.ground == null) merged_template.display.ground = display.ground;
            if (merged_template.display.fixed == null) merged_template.display.fixed = display.fixed;
        }

        if (template_lineage.parent) |parent| {
            if (std.mem.eql(u8, "builtin/generated", parent) or std.mem.eql(u8, "builtin/entity", parent) or std.mem.eql(u8, "builtin/compass", parent) or std.mem.eql(u8, "builtin/clock", parent)) {
                std.debug.assert(merged_template.geometry == null);
                merged_template.geometry = .generated_item;
                break;
            }
            template_lineage = (templates.get(parent).? catch unreachable);
        } else {
            std.debug.assert(merged_template.geometry != null);
            break;
        }
    }

    return switch (merged_template.geometry.?) {
        .elements => |elements| .{
            .ambientocclusion = merged_template.ambient_occlusion orelse true,
            .geometry = .{ .elements = try resolveElements(arena, merged_template.texture_variables, textures, elements) },
            .display = merged_template.display,
        },
        .generated_item => .{
            .ambientocclusion = merged_template.ambient_occlusion orelse false,
            .geometry = .{ .generated_item = try resolveGeneratedItem(merged_template.texture_variables, textures) },
            .display = merged_template.display,
        },
    };
}

pub fn resolveGeneratedItem(
    texture_variables: std.array_hash_map.String([]const u8),
    textures: std.array_hash_map.String(ImageError!zigimg.Image),
) ![5]?Renderer.TextureHandle {
    var resolved_textures: [5]?Renderer.TextureHandle = @splat(null);

    inline for (.{ "#layer0", "#layer1", "#layer2", "#layer3", "#layer4" }, &resolved_textures) |layer, *resolved_texture| {
        const texture_name = resolveTextureVariable(texture_variables, layer) catch |e| switch (e) {
            error.CyclicVariable => return error.CyclicVariable,
            error.MissingTextureVariableReference => break,
        };
        resolved_texture.* = @fromBackingInt(@intCast(textures.getIndex(texture_name) orelse return error.MissingTexture));
    }
    return resolved_textures;
}

pub fn resolveElements(
    arena: std.mem.Allocator,
    texture_variables: std.array_hash_map.String([]const u8),
    textures: std.array_hash_map.String(ImageError!zigimg.Image),
    elements: []const ModelTemplate.Element,
) ![]ResolvedModel.Element {
    const resolved_elements: []ResolvedModel.Element = try arena.alloc(ResolvedModel.Element, elements.len);

    for (elements, resolved_elements) |element, *resolved_element| {
        resolved_element.* = .{
            .from = .{ .x = element.from[0], .y = element.from[1], .z = element.from[2] },
            .to = .{ .x = element.to[0], .y = element.to[1], .z = element.to[2] },
            .faces = .{ .north = null, .south = null, .west = null, .east = null, .up = null, .down = null },
            .rotation = if (element.rotation) |rotation| .{
                .origin = .{ .x = rotation.origin[0], .y = rotation.origin[1], .z = rotation.origin[2] },
                .axis = rotation.axis,
                .angle = rotation.angle,
                .rescale = rotation.rescale,
            } else null,
            .shade = element.shade,
        };
        inline for (.{ .north, .south, .west, .east, .up, .down }) |direction| {
            if (@field(element.faces, @tagName(direction))) |face| {
                const texture_name = try resolveTextureVariable(texture_variables, face.texture);
                _ = (textures.get(texture_name) orelse return error.MissingTexture) catch return error.BrokenTexture;
                const texture_handle: Renderer.TextureHandle = @fromBackingInt(@intCast(textures.getIndex(texture_name).?));
                @field(resolved_element.faces, @tagName(direction)) = .{
                    .uv = face.uv orelse try computeAutoUv(resolved_element.from, resolved_element.to, direction),
                    .texture = texture_handle,
                    .tintindex = face.tintindex,
                    .cullface = face.cullface,
                    .rotation = face.rotation,
                    .cull = face.cull,
                };
            }
        }
    }

    return resolved_elements;
}

/// Recursively resolves a texture variable
pub fn resolveTextureVariable(texture_variables: std.array_hash_map.String([]const u8), variable: []const u8) ![]const u8 {
    if (!std.mem.startsWith(u8, variable, "#")) {
        std.log.scoped(.resource_pack_model).warn("variable {s} does not start with #", .{variable});
    }

    if (texture_variables.count() == 0) return error.MissingTextureVariableReference;

    var value = variable;
    for (0..texture_variables.count()) |i| {
        // search for a variable reference
        // on the first variable, search directly if reference is malformed
        if (std.mem.startsWith(u8, value, "#")) {
            value = texture_variables.get(value[1..]) orelse return error.MissingTextureVariableReference;
        } else if (i == 0) {
            value = texture_variables.get(value) orelse return error.MissingTextureVariableReference;
        } else {
            // Found the concrete texture variable
            return value;
        }
    }
    if (!std.mem.startsWith(u8, value, "#")) return value;
    // There are only N elements, so if the walk takes more than N steps,
    // we must have revisited a node and have entered a cycle
    return error.CyclicVariable;
}

pub fn computeAutoUv(from: Vector3(f32), to: Vector3(f32), direction: Direction) ![4]f32 {
    // zig fmt: off
    if (from.x < 0 or from.y < 0 or from.z < 0 or from.x > 16 or from.y > 16 or from.z > 16) return error.FailedUvMapping;
    if (  to.x < 0 or   to.y < 0 or   to.z < 0 or   to.x > 16 or   to.y > 16 or   to.z > 16) return error.FailedUvMapping;
    return switch (direction) {
        .up =>    .{    from.x,    from.z, to.x,               to.z },
        .down =>  .{    from.x, 16 - to.z, to.x,        16 - from.z },
        .west =>  .{    from.z, 16 - to.y, to.z,        16 - from.y },
        .south => .{    from.x, 16 - to.y, to.x,        16 - from.y },
        .east =>  .{ 16 - to.x, 16 - to.y, 16 - from.x, 16 - from.y },
        .north => .{ 16 - to.x, 16 - to.y, 16 - from.x, 16 - from.y },

    };
    // zig fmt: on
}

/// Decodes every image in a directory
/// Takes ownership of dir
pub fn loadImagesInDir(io: std.Io, arena: std.mem.Allocator, dir: std.Io.Dir) !std.array_hash_map.String(ImageError!zigimg.Image) {
    @setRuntimeSafety(false);
    defer dir.close(io);

    var images: std.array_hash_map.String(ImageError!zigimg.Image) = .empty;

    var group: std.Io.Group = .init;
    errdefer group.cancel(io);

    var walker = try dir.walk(arena);
    while (try walker.next(io)) |entry| {
        if (entry.kind != .file) continue;

        // some animated textures may also have an
        // associated `.png.mcmeta` metadata file
        // we skip those for now
        if (!std.mem.eql(u8, std.fs.path.extension(entry.basename), ".png")) continue;

        const path = try arena.dupe(u8, entry.path);
        try images.put(arena, path[0 .. path.len - ".png".len], undefined);
    }
    for (images.keys(), images.values()) |path, *image| {
        group.async(io, loadImageFromFile, .{ io, arena, dir, path.ptr[0 .. path.len + ".png".len], image });
    }
    try group.await(io);

    return images;
}

pub const ImageError = error{
    FileError,
    BrokenImage,
    OutOfMemory,
};

pub fn loadImageFromFile(
    io: std.Io,
    arena: std.mem.Allocator,
    dir: std.Io.Dir,
    path: []const u8,
    image_out: *ImageError!zigimg.Image,
) !void {
    const file = dir.openFile(io, path, .{}) catch {
        image_out.* = error.FileError;
        return;
    };
    defer file.close(io);

    var buf: [1024]u8 = undefined;

    image_out.* = zigimg.Image.fromFile(arena, io, file, &buf) catch |e| switch (e) {
        error.EndOfStream, error.StreamTooLong, error.InvalidData => error.BrokenImage,
        error.OutOfMemory => error.OutOfMemory,
        else => error.FileError,
    };
}

const std = @import("std");

const main = @import("main");
const render = @import("render");
const zigimg = @import("zigimg");
const allValues = @import("util").allValues;

pub const BakedModel = @import("BakedModel.zig");
pub const ModelTemplate = @import("ModelTemplate.zig");
pub const ResolvedModel = @import("ResolvedModel.zig");
pub const StateToModelMap = @import("StateToModelMap.zig");
const createBlockStateToModelTable = @import("block.zig").createBlockStateToModelTable;
const createItemStackToModelTable = @import("item.zig").createItemStackToModelTable;
pub const BakedItemModel = @import("item.zig").BakedItemModel;

const Block = main.Block;
const Direction = main.Direction;
const Vector3 = main.Vector3;
const Renderer = render.Renderer;
