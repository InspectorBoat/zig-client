const std = @import("std");

const main = @import("main");

const ParticleType = @import("../../../../particle/particletype.zig").ParticleType;

const Client = main.Client;
const Vector3 = main.Vector3;
const S2C = main.network.packet.S2C;

type: ParticleType,
pos: Vector3(f32),
velocity: Vector3(f32),
velocity_scale: f32,
count: i32,
ignore_distance: bool,
parameters: []const i32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
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

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
