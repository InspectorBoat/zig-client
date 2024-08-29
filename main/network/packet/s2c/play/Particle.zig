const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Game = root.Game;
const ParticleType = @import("../../../../particle/particletype.zig").ParticleType;
const Vector3 = root.Vector3;

type: ParticleType,
pos: Vector3(f32),
velocity: Vector3(f32),
velocity_scale: f32,
count: i32,
ignore_distance: bool,
parameters: []const i32,

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
