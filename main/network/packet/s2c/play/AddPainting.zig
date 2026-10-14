const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

const Vector3 = root.Vector3;
const Direction = root.Direction;

network_id: i32,
block_pos: Vector3(i32),
facing: Direction,
painting_identifier: []const u8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    const network_id = try buffer.readVarInt();
    // PaintingEntity.Motive.SKULL_AND_ROSES_LENGTH == "SkullAndRoses".length()
    const painting_identifier = try buffer.readStringAllocating(13, allocator);
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

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, io: std.Io, allocator: std.mem.Allocator) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
