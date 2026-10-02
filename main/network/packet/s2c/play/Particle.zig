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
    const raw_type = try buffer.read(i32);
    const ignore_distance = try buffer.read(bool);
    const pos: Vector3(f32) = .{
        .x = try buffer.read(f32),
        .y = try buffer.read(f32),
        .z = try buffer.read(f32),
    };
    const velocity: Vector3(f32) = .{
        .x = try buffer.read(f32),
        .y = try buffer.read(f32),
        .z = try buffer.read(f32),
    };
    const velocity_scale = try buffer.read(f32);
    const count = try buffer.read(i32);
    const particle_type = std.enums.fromInt(ParticleType, raw_type) orelse .BARRIER;

    const parameter_count: usize = switch (particle_type) {
        .ITEM_CRACK => 2,
        .BLOCK_CRACK, .BLOCK_DUST => 1,
        else => 0,
    };

    var parameters: std.ArrayList(i32) = .empty;
    try parameters.ensureTotalCapacity(allocator, @intCast(parameter_count));
    for (0..parameter_count) |_| {
        try parameters.append(allocator, try buffer.readVarInt());
    }

    return .{
        .type = particle_type,
        .pos = pos,
        .velocity = velocity,
        .velocity_scale = velocity_scale,
        .count = count,
        .ignore_distance = ignore_distance,
        .parameters = parameters.items,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
