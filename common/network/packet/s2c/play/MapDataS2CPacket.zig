const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const MapDecoration = @import("../../../../world/MapDecoration.zig");
const Vector2 = @import("../../../../math/vector.zig").Vector2;

map_id: i32,
scale: i8,
decorations: []const MapDecoration,
dirty_min_pos: Vector2(i32),
dirty_size: Vector2(i32),
colors: []const u8,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    _ = buffer;
    return undefined;
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
