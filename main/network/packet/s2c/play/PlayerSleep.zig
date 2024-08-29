const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Game = root.Game;
const Vector3 = root.Vector3;

network_id: i32,
block_pos: Vector3(i32),

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
