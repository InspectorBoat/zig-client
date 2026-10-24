pos: Vector3(f64),
power: f32,
damaged_blocks: []const Vector3(i32),
player_velocity: Vector3(f32),

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const pos: Vector3(f64) = .{
        .x = try buffer.read(f32),
        .y = try buffer.read(f32),
        .z = try buffer.read(f32),
    };
    const power = try buffer.read(f32);

    const block_count = try buffer.read(i32);
    var damaged_blocks: std.ArrayList(Vector3(i32)) = .empty;
    try damaged_blocks.ensureTotalCapacity(allocator, @intCast(block_count));
    for (0..@intCast(block_count)) |_| {
        try damaged_blocks.append(allocator, .{
            .x = @as(i32, @intFromFloat(pos.x)) + try buffer.read(i8),
            .y = @as(i32, @intFromFloat(pos.y)) + try buffer.read(i8),
            .z = @as(i32, @intFromFloat(pos.z)) + try buffer.read(i8),
        });
    }

    const player_velocity: Vector3(f32) = .{
        .x = try buffer.read(f32),
        .y = try buffer.read(f32),
        .z = try buffer.read(f32),
    };

    return .{
        .pos = pos,
        .power = power,
        .damaged_blocks = damaged_blocks.items,
        .player_velocity = player_velocity,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}

const std = @import("std");

const main = @import("main");

const Client = main.Client;
const Vector3 = main.Vector3;
const S2C = main.network.packet.S2C;
