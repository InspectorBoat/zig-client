const std = @import("std");

const Renderer = @import("../Renderer.zig");
const Block = @import("root").Block;
const allValues = @import("util").allValues;
const BlockModelTemplate = @import("BlockModelTemplate.zig");
const ResolvedBlockModel = @import("ResolvedBlockModel.zig");
const StateToModelMap = @import("StateToModelMap.zig");
const BakedModel = @import("BakedModel.zig");

// Takes ownership of resource_pack_dir
pub fn init(
    io: std.Io,
    gpa: std.mem.Allocator,
    arena: std.mem.Allocator,
    resource_pack_dir: std.Io.Dir,
) !struct {
    std.AutoHashMapUnmanaged(Block.VirtualState, BakedModel),
    std.array_hash_map.String(zigimg.Image),
} {
    const state_to_model_maps = try parseJsonInDir(
        StateToModelMap,
        io,
        arena,
        try resource_pack_dir.openDir(io, "assets/minecraft/blockstates", .{ .iterate = true }),
    );
    const model_templates = try parseJsonInDir(
        BlockModelTemplate,
        io,
        arena,
        try resource_pack_dir.openDir(io, "assets/minecraft/models/block", .{ .iterate = true }),
    );
    const textures = try loadImagesInDir(
        io,
        arena,
        try resource_pack_dir.openDir(io, "assets/minecraft/textures/blocks", .{ .iterate = true }),
    );
    const resolved_models = try resolveBlockModels(arena, model_templates, textures);
    return .{ try createLookupTable(gpa, resolved_models, state_to_model_maps), textures };
}

/// Parses all files in a directory from JSON into T
/// Takes ownership of dir
pub fn parseJsonInDir(T: type, io: std.Io, arena: std.mem.Allocator, dir: std.Io.Dir) !std.StringHashMapUnmanaged(T) {
    defer dir.close(io);
    var states: std.StringHashMapUnmanaged(T) = .empty;

    var iter = dir.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .file) continue;

        const file = try dir.openFile(io, entry.name, .{});
        defer file.close(io);

        var buf: [1024]u8 = undefined;
        var file_reader = file.reader(io, &buf);

        var reader: std.json.Reader = .init(arena, &file_reader.interface);
        defer reader.deinit();
        const parsed_model = try std.json.parseFromTokenSourceLeaky(T, arena, &reader, .{});

        try states.put(arena, try arena.dupe(u8, std.fs.path.stem(entry.name)), parsed_model);
    }
    return states;
}

/// Resolves all block model templates parsed in the previous step.
pub fn resolveBlockModels(
    arena: std.mem.Allocator,
    model_templates: std.StringHashMapUnmanaged(BlockModelTemplate),
    textures: std.array_hash_map.String(zigimg.Image),
) !std.StringHashMapUnmanaged(ResolvedBlockModel) {
    var resolved_models: std.StringHashMapUnmanaged(ResolvedBlockModel) = .empty;
    var iter = model_templates.keyIterator();
    while (iter.next()) |model_name| {
        const resolved_model = resolveBlockModel(arena, model_name.*, model_templates, textures) catch |e| switch (e) {
            // we are iterating the hashmap keys, so this is impossible
            error.MissingModel => unreachable,
            // model is a template, not a problem
            error.MissingTextureVariableReference => {
                std.log.scoped(.resource_pack).debug("incomplete model {s}", .{model_name.*});
                continue;
            },
            error.MissingParent, error.NoElements, error.CyclicVariable => {
                std.log.scoped(.resource_pack).err("{} resolving {s}", .{ e, model_name.* });
                return e;
            },
            else => return e,
        };
        try resolved_models.put(arena, model_name.*, resolved_model);
    }
    return resolved_models;
}

/// Takes (the name of) a block model template and walks the parent chain,
/// resolving all texture references, ambient occlusion, and elements
pub fn resolveBlockModel(
    arena: std.mem.Allocator,
    model_name_to_resolve: []const u8,
    models: std.StringHashMapUnmanaged(BlockModelTemplate),
    textures: std.array_hash_map.String(zigimg.Image),
) !ResolvedBlockModel {
    var maybe_ambient_occlusion: ?bool = null;
    var maybe_elements: ?[]BlockModelTemplate.Element = null;
    var texture_variables: std.StringHashMapUnmanaged([]const u8) = .empty;

    if (!models.contains(model_name_to_resolve)) return error.MissingModel;

    // first: walk the parent chain and merge texture variable maps and elements
    var maybe_model_name: ?[]const u8 = model_name_to_resolve;
    while (maybe_model_name) |model_name| {
        const model = models.get(model_name) orelse return error.MissingParent;

        defer maybe_model_name = if (model.parent) |parent| parent["block/".len..] else null;

        // merge texture variables
        if (model.textures) |*model_texture_variables| {
            var iter = model_texture_variables.map.iterator();
            while (iter.next()) |entry| {
                try texture_variables.put(arena, entry.key_ptr.*, entry.value_ptr.*);
            }
        }

        // take elements & ambient occlusion, parent cannot override child
        if (maybe_elements == null) maybe_elements = model.elements;
        if (maybe_ambient_occlusion == null) maybe_ambient_occlusion = model.ambientocclusion;
    }

    const elements = maybe_elements orelse return error.NoElements;
    if (elements.len == 0) return error.NoElements;

    const resolved_elements: []ResolvedBlockModel.Element = try arena.alloc(ResolvedBlockModel.Element, elements.len);

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
        inline for (.{ "north", "south", "west", "east", "up", "down" }) |direction| {
            if (@field(element.faces, direction)) |face| {
                // TODO: All this stem stripping is a shitty hack, we should figure out how vanilla actually does it
                const texture_name = (try resolveTextureVariable(texture_variables, face.texture))["blocks/".len..];
                const texture_handle: Renderer.TextureHandle = @fromBackingInt(@intCast(textures.getIndex(texture_name) orelse {
                    std.log.scoped(.resource_pack).err("model {s} references nonexistent texture {s}", .{ model_name_to_resolve, texture_name });
                    return error.MissingTexture;
                }));
                @field(resolved_element.faces, direction) = .{
                    .uv = face.uv orelse .{ 0, 0, 16, 16 },
                    .texture = texture_handle,
                    .tintindex = face.tintindex,
                    .cullface = face.cullface,
                    .rotation = face.rotation,
                    .cull = face.cull,
                };
            }
        }
    }

    return .{
        .ambientocclusion = maybe_ambient_occlusion orelse true,
        .elements = resolved_elements,
    };
}

/// Recursively resolves a texture variable
pub fn resolveTextureVariable(texture_variables: std.StringHashMapUnmanaged([]const u8), variable: []const u8) ![]const u8 {
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
    // There are only N elements, so if the walk takes more than N steps,
    // we must have revisited a node and have entered a cycle
    return error.CyclicVariable;
}

/// Create a lookup table mapping from Block.VirtualState -> BakedBlockModel
pub fn createLookupTable(
    gpa: std.mem.Allocator,
    resolved_block_models: std.StringHashMapUnmanaged(ResolvedBlockModel),
    state_to_model_maps: std.StringHashMapUnmanaged(StateToModelMap),
) !std.AutoHashMapUnmanaged(Block.VirtualState, BakedModel) {
    var lookup_table: std.AutoHashMapUnmanaged(Block.VirtualState, BakedModel) = .empty;
    @setEvalBranchQuota(1000000);
    var total: usize = 0;
    inline for (std.enums.values(Block)) |block| {
        const all_states = allValues(@FieldType(Block.VirtualState, @tagName(block)));
        for (all_states) |properties| {
            const block_name_key = getNameString(gpa, block, properties) catch |e| switch (e) {
                error.NoModel => continue,
                else => return e,
            };
            defer gpa.free(block_name_key);
            const properties_key = try getPropertiesString(gpa, block, properties);
            defer gpa.free(properties_key);

            const state_to_model_map = state_to_model_maps.get(block_name_key) orelse return error.MapNotFound;
            const model_variants = state_to_model_map.variants.map.get(properties_key) orelse return error.VariantNotFound;
            const model_variant = switch (model_variants) {
                .single => |single| single,
                // TODO: support this
                .multi => |multi| multi[0],
            };
            const resolved_block_model = resolved_block_models.get(model_variant.model) orelse return error.ModelNotFound;

            const baked_model: BakedModel = try .bake(gpa, resolved_block_model, model_variant.x, model_variant.y);

            try lookup_table.put(gpa, @unionInit(Block.VirtualState, @tagName(block), properties), baked_model);

            total += 1;
        }
    }
    std.log.scoped(.resource_pack_states).debug("{} states with models", .{total});
    return lookup_table;
}

pub fn getNameString(
    gpa: std.mem.Allocator,
    comptime block: Block,
    properties: @FieldType(Block.VirtualState, @tagName(block)),
) (error{NoModel} || std.mem.Allocator.Error)![]const u8 {
    var string: std.ArrayList(u8) = .empty;
    errdefer string.deinit(gpa);
    switch (block) {
        .air,
        .flowing_water,
        .water,
        .flowing_lava,
        .lava,
        .piston_extension,
        .chest,
        .trapped_chest,
        .ender_chest,
        .standing_sign,
        .wall_sign,
        .standing_banner,
        .wall_banner,
        .skull,
        .end_portal,
        .barrier,

        .flower_pot, // todo
        .quartz_block, // todo
        => return error.NoModel,

        .deadbush => try string.appendSlice(gpa, "dead_bush"),
        .yellow_flower => try string.appendSlice(gpa, "dandelion"),
        .double_stone_slab2 => try string.appendSlice(gpa, "red_sandstone_double_slab"),
        .stone_slab2 => try string.appendSlice(gpa, "red_sandstone_slab"),

        .stone,
        .sand,
        .prismarine,
        .stonebrick,
        .double_plant,
        .dirt,
        .red_flower,
        .red_sandstone,
        .sandstone,
        .tallgrass,
        => try string.appendSlice(gpa, @tagName(properties.variant)),

        .stained_hardened_clay,
        .stained_glass,
        .stained_glass_pane,
        .wool,
        .carpet,
        => try string.print(gpa, "{s}_{s}", .{ @tagName(properties.color), @tagName(block) }),

        .planks,
        .sapling,
        .monster_egg,
        => try string.print(gpa, "{s}_{s}", .{ @tagName(properties.variant), @tagName(block) }),

        .log, .log2 => try string.print(gpa, "{s}_log", .{@tagName(properties.variant)}),
        .leaves, .leaves2 => try string.print(gpa, "{s}_leaves", .{@tagName(properties.variant)}),
        .double_wooden_slab, .double_stone_slab => try string.print(gpa, "{s}_double_slab", .{@tagName(properties.variant)}),
        .wooden_slab, .stone_slab => try string.print(gpa, "{s}_slab", .{@tagName(properties.variant)}),
        .cobblestone_wall => try string.print(gpa, "{s}_wall", .{@tagName(properties.variant)}),

        else => try string.appendSlice(gpa, @tagName(block)),
    }
    return try string.toOwnedSlice(gpa);
}

pub fn getPropertiesString(
    gpa: std.mem.Allocator,
    comptime block: Block,
    properties: @FieldType(Block.VirtualState, @tagName(block)),
) ![]const u8 {
    var string: std.ArrayList(u8) = .empty;
    errdefer string.deinit(gpa);

    const field_names_const = @typeInfo(@FieldType(Block.VirtualState, @tagName(block))).@"struct".field_names;
    comptime var field_names = field_names_const[0..field_names_const.len].*;
    comptime std.mem.sort([:0]const u8, &field_names, {}, struct {
        fn lessThan(_: void, lhs: [:0]const u8, rhs: [:0]const u8) bool {
            return std.mem.lessThanZ(u8, lhs, rhs);
        }
    }.lessThan);
    // TODO: seamless slabs
    inline for (field_names) |field_name| {
        if (!skipField(block, properties, field_name)) {
            if (string.items.len > 0) try string.append(gpa, ',');
            try string.appendSlice(gpa, field_name);
            try string.append(gpa, '=');
            const property = @field(properties, field_name);

            switch (@typeInfo(@TypeOf(property))) {
                .@"enum" => try string.appendSlice(gpa, @tagName(property)),
                .int => try string.print(gpa, "{}", .{property}),
                .bool => try string.appendSlice(gpa, if (property) "true" else "false"),
                else => unreachable,
            }
        }
    }
    if (string.items.len == 0) try string.appendSlice(gpa, "normal");
    return string.toOwnedSlice(gpa);
}

pub fn skipField(comptime block: Block, properties: @FieldType(Block.VirtualState, @tagName(block)), comptime field_name: []const u8) bool {
    if (block == .dirt and properties.variant != .podzol and std.mem.eql(u8, field_name, "snowy")) return true;
    if ((block == .leaves or block == .leaves2) and (std.mem.eql(u8, field_name, "not_decayable") or std.mem.eql(u8, field_name, "check_decay"))) return true;
    if ((block == .double_stone_slab or block == .double_stone_slab2) and std.mem.eql(u8, field_name, "seamless")) return true;
    switch (block) {
        .bed => if (std.mem.eql(u8, field_name, "occupied")) return true,

        .tnt => if (std.mem.eql(u8, field_name, "explode")) return true,

        .fire => if (std.mem.eql(u8, field_name, "age")) return true,

        .redstone_wire => if (std.mem.eql(u8, field_name, "power")) return true,

        .flower_pot => if (std.mem.eql(u8, field_name, "legacy_data")) return true,

        .jukebox => if (std.mem.eql(u8, field_name, "has_record")) return true,

        .cactus, .reeds => if (std.mem.eql(u8, field_name, "age")) return true,

        .pumpkin_stem, .melon_stem => if (properties.facing != .up and std.mem.eql(u8, field_name, "age")) return true,

        .tripwire => if (std.mem.eql(u8, field_name, "powered") or std.mem.eql(u8, field_name, "disarmed")) return true,

        .hopper => if (std.mem.eql(u8, field_name, "enabled")) return true,

        .wooden_door,
        .spruce_door,
        .birch_door,
        .jungle_door,
        .acacia_door,
        .dark_oak_door,
        .iron_door,
        .fence_gate,
        .spruce_fence_gate,
        .birch_fence_gate,
        .jungle_fence_gate,
        .dark_oak_fence_gate,
        .acacia_fence_gate,
        => if (std.mem.eql(u8, field_name, "powered")) return true,

        .dispenser,
        .dropper,
        .command_block,
        => if (std.mem.eql(u8, field_name, "triggered")) return true,

        .stained_hardened_clay,
        .stained_glass,
        .stained_glass_pane,
        .wool,
        .carpet,
        => if (std.mem.eql(u8, field_name, "color")) return true,

        .stone,
        .sand,
        .prismarine,
        .stonebrick,
        .double_plant,
        .dirt,
        .red_flower,
        .red_sandstone,
        .sandstone,
        .tallgrass,
        .planks,
        .sapling,
        .monster_egg,
        .log,
        .log2,
        .leaves,
        .leaves2,
        .double_wooden_slab,
        .double_stone_slab,
        .wooden_slab,
        .stone_slab,
        .cobblestone_wall,
        => if (std.mem.eql(u8, field_name, "variant")) return true,

        else => {},
    }

    return false;
}

const zigimg = @import("zigimg");

/// Decodes every image in a directory
/// Takes ownership of dir
pub fn loadImagesInDir(io: std.Io, arena: std.mem.Allocator, dir: std.Io.Dir) !std.array_hash_map.String(zigimg.Image) {
    defer dir.close(io);
    var images: std.array_hash_map.String(zigimg.Image) = .empty;
    var iter = dir.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .file) continue;

        // vanilla ships a `.png.mcmeta` metadata file for some sprites (animated ones),
        // so this directory is not all-png and the extension must be filtered
        if (!std.mem.eql(u8, std.fs.path.extension(entry.name), ".png")) continue;

        const file = try dir.openFile(io, entry.name, .{});
        defer file.close(io);

        var buf: [1024]u8 = undefined;
        const image: zigimg.Image = try .fromFile(arena, io, file, &buf);

        try images.put(arena, try arena.dupe(u8, std.fs.path.stem(entry.name)), image);
    }
    return images;
}
