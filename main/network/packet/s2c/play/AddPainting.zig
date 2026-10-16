const std = @import("std");

const main = @import("main");

const Client = main.Client;
const Direction = main.Direction;
const Vector3 = main.Vector3;
const S2C = main.network.packet.S2C;

network_id: i32,
block_pos: Vector3(i32),
facing: Direction,
painting_identifier: []const u8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const network_id = try buffer.readVarInt();
    // PaintingEntity.Motive.SKULL_AND_ROSES_LENGTH == "SkullAndRoses".length()
    const painting_identifier = try buffer.readStringAllocating(allocator, 13);
    const block_pos = try buffer.readBlockPos();
    const horizontal_directions: []const Direction = &.{ .south, .west, .north, .east };
    const facing_id = try buffer.read(u8);
    const facing = horizontal_directions[@intCast(facing_id % horizontal_directions.len)];

    return .{
        .network_id = network_id,
        .block_pos = block_pos,
        .facing = facing,
        .painting_identifier = painting_identifier,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
