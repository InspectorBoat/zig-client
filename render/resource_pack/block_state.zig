const std = @import("std");

const StateToModelMap = @import("StateToModelMap.zig");

pub fn init(io: std.Io, arena: std.mem.Allocator) !std.StringHashMapUnmanaged(StateToModelMap) {
    const start: @import("llm-code-quarantine").Timer = .init();
    defer std.log.scoped(.resource_pack).info("block states parsed in {d} ms", .{start.ms()});

    return try parseAll(io, arena, "/home/inspectorboat/src/zig-client/vanilla-pack/assets/minecraft/blockstates");
}

pub fn parseAll(io: std.Io, arena: std.mem.Allocator, path: []const u8) !std.StringHashMapUnmanaged(StateToModelMap) {
    var states: std.StringHashMapUnmanaged(StateToModelMap) = .empty;

    const dir: std.Io.Dir = try .openDir(.cwd(), io, path, .{ .iterate = true });
    var iter = dir.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .file) continue;

        const file = try dir.openFile(io, entry.name, .{});
        defer file.close(io);

        var buf: [1024]u8 = undefined;
        var file_reader = file.reader(io, &buf);

        const parsed_model = parseBlockModel(&file_reader.interface, arena) catch |e| {
            std.log.scoped(.resource_pack).err("{} parsing {s}", .{ e, entry.name });
            return e;
        };

        try states.put(
            arena,
            try arena.dupe(u8, entry.name[0 .. entry.name.len - ".json".len]),
            parsed_model,
        );
    }
    return states;
}

pub fn parseBlockModel(file_reader: *std.Io.Reader, arena: std.mem.Allocator) !StateToModelMap {
    var reader: std.json.Reader = .init(arena, file_reader);
    defer reader.deinit();
    const model = try std.json.parseFromTokenSourceLeaky(StateToModelMap, arena, &reader, .{});
    return model;
}
