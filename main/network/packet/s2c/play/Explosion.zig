const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Game = root.Game;
const ScaledVector = @import("../../../../network/type/scaled_vector.zig").ScaledVector;
const Vector3 = @import("../../../../math/vector.zig").Vector3;

pos: Vector3(f64),
power: f32,
damaged_blocks: []const Vector3(i32),
player_velocity: Vector3(f32),

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
