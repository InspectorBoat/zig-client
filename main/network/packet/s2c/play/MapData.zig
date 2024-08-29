const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Game = root.Game;
const MapDecoration = @import("../../../../world/MapDecoration.zig");
const Vector2xy = root.Vector2xy;

map_id: i32,
scale: i8,
decorations: []const MapDecoration,
dirty_min_pos: Vector2xy(i32),
dirty_size: Vector2xy(i32),
colors: []const u8,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    _ = buffer;
    return undefined;
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
