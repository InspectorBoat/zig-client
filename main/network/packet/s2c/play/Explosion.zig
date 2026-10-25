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

    const block_count: usize = @intCast(try buffer.read(i32));
    const damaged_blocks = try allocator.alloc(Vector3(i32), block_count);
    for (damaged_blocks) |*damaged_block| {
        damaged_block.* = .{
            .x = std.math.lossyCast(i32, pos.x) + try buffer.read(i8),
            .y = std.math.lossyCast(i32, pos.y) + try buffer.read(i8),
            .z = std.math.lossyCast(i32, pos.z) + try buffer.read(i8),
        };
    }

    const player_velocity: Vector3(f32) = .{
        .x = try buffer.read(f32),
        .y = try buffer.read(f32),
        .z = try buffer.read(f32),
    };

    return .{
        .pos = pos,
        .power = power,
        .damaged_blocks = damaged_blocks,
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
