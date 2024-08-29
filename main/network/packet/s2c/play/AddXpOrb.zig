const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Game = root.Game;
const ScaledVector = root.network.ScaledVector;

network_id: i32,
pos: ScaledVector(i32, 32.0),
xp: i32,

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
