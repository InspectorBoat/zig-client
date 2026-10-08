const std = @import("std");

pub const ParsedBlockModel = @import("ParsedBlockModel.zig");

pub fn init(io: std.Io, allocator: std.mem.Allocator) !void {
    const start: @import("llm-code-quarantine").Timer = .init();
    defer std.log.info("block models parsed in {d} ms\n", .{start.ms()});

    var arena: std.heap.ArenaAllocator = .init(allocator);
    defer arena.deinit();

    const models = try parseAll(io, arena.allocator(), "/home/inspectorboat/src/zig-client/render/resourcepack/vanilla-pack/assets/minecraft/models/block");
    var iter = models.keyIterator();
    while (iter.next()) |model_name| {
        resolveBlockModel(arena.allocator(), model_name.*, models) catch |e| switch (e) {
            error.MissingTextureVariableReference => {
                std.log.debug("incomplete model {s}", .{model_name.*});
            },
            else => {
                std.log.err("{} resolving {s}", .{ e, model_name.* });
                return e;
            },
        };
    }
}

pub fn parseAll(io: std.Io, arena: std.mem.Allocator, path: []const u8) !std.StringHashMapUnmanaged(ParsedBlockModel) {
    var models: std.StringHashMapUnmanaged(ParsedBlockModel) = .empty;

    const dir: std.Io.Dir = try .openDir(.cwd(), io, path, .{ .iterate = true });
    var iter = dir.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .file) continue;

        const file = try dir.openFile(io, entry.name, .{});
        defer file.close(io);

        var buf: [1024]u8 = undefined;
        var file_reader = file.reader(io, &buf);

        const parsed_model = try parseBlockModel(&file_reader.interface, arena);

        try models.put(
            arena,
            try std.fmt.allocPrint(arena, "block/{s}", .{entry.name[0 .. entry.name.len - ".json".len]}),
            parsed_model,
        );
    }
    return models;
}

pub fn resolveBlockModel(arena: std.mem.Allocator, model_name_to_resolve: []const u8, models: std.StringHashMapUnmanaged(ParsedBlockModel)) !void {
    var maybe_elements: ?[]ParsedBlockModel.Element = null;
    var texture_variables: std.StringHashMapUnmanaged([]const u8) = .empty;

    // first: walk the parent chain and merge texture variable maps and elements
    var maybe_model_name: ?[]const u8 = model_name_to_resolve;
    while (maybe_model_name) |model_name| {
        const model = models.get(model_name) orelse {
            std.log.err("{s}", .{model_name});
            return if (std.mem.eql(u8, model_name, model_name_to_resolve)) error.NonExistentModel else return error.NonExistentParent;
        };
        defer maybe_model_name = model.parent;

        // merge texture variables
        if (model.textures) |*textures| {
            var iter = textures.map.iterator();
            while (iter.next()) |entry| {
                try texture_variables.put(arena, entry.key_ptr.*, entry.value_ptr.*);
            }
        }

        // parent element cannot override child element
        if (maybe_elements == null) maybe_elements = model.elements;
    }

    const elements = maybe_elements orelse return error.NoElements;
    if (elements.len == 0) return error.NoElements;
    const BlockModel = @import("BlockModel.zig");
    const resolved_elements: []BlockModel.Element = try arena.alloc(BlockModel.Element, elements.len);
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
            @field(resolved_element.faces, direction) = if (@field(element.faces, direction)) |face| .{
                .uv = face.uv orelse .{ 0, 0, 16, 16 },
                .texture = try resolveTextureVariable(texture_variables, face.texture),
                .tintindex = face.tintindex,
                .cullface = face.cullface,
                .rotation = face.rotation,
                .cull = face.cull,
            } else null;
        }
    }
}

pub fn resolveTextureVariable(texture_variables: std.StringHashMapUnmanaged([]const u8), variable: []const u8) ![]const u8 {
    if (!std.mem.startsWith(u8, variable, "#")) {
        std.log.scoped(.model).warn("variable {s} does not start with #", .{variable});
    }
    if (texture_variables.count() == 0) return error.MissingTextureVariableReference;

    var value = variable;
    for (0..texture_variables.count()) |i| {
        if (std.mem.startsWith(u8, value, "#")) {
            // search for a variable reference
            value = texture_variables.get(value[1..]) orelse return error.MissingTextureVariableReference;
        } else if (i == 0) {
            // on the first variable, search directly if reference is malformed
            value = texture_variables.get(value) orelse return error.MissingTextureVariableReference;
        } else {
            // Found the concrete texture variable
            return value;
        }
    }

    return error.CyclicVariable;
}

pub fn parseBlockModel(file_reader: *std.Io.Reader, arena: std.mem.Allocator) !ParsedBlockModel {
    var reader: std.json.Reader = .init(arena, file_reader);
    defer reader.deinit();
    const model = try std.json.parseFromTokenSourceLeaky(ParsedBlockModel, arena, &reader, .{});
    try validate(&model);
    return model;
}

pub fn validate(model: *const ParsedBlockModel) !void {
    if (model.elements == null and model.parent == null) return error.NoElementsOrParent;
    if (model.elements != null and model.parent != null) return error.BothElementsAndParent;

    if (model.elements) |elements| for (elements) |element| {
        for (element.from) |component| {
            if (component < -16 or component > 32) return error.CoordinateOutOfRange;
        }
        for (element.to) |component| {
            if (component < -16 or component > 32) return error.CoordinateOutOfRange;
        }

        if (element.faces.down == null and
            element.faces.up == null and
            element.faces.east == null and
            element.faces.west == null and
            element.faces.south == null and
            element.faces.north == null)
            return error.EmptyElement;
    };
}

test parseAll {
    try parseAll(std.testing.io, std.testing.allocator, "/home/inspectorboat/src/zig-client/render/resourcepack/vanilla-pack/assets/minecraft/models/block");
}
