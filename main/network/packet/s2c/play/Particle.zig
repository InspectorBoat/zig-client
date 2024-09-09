const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

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
comptime required_client_state: Client.State = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    _ = buffer;
    return undefined;
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
