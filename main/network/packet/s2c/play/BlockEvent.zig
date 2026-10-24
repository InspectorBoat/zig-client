block_pos: Vector3(i32),
type: i32,
data: i32,
block: Block,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;

    const block_pos = try buffer.readBlockPos();
    const event_type = try buffer.read(u8);
    const data = try buffer.read(u8);
    const block = std.enums.fromInt(Block, try buffer.readVarInt() & 4095) orelse return error.InvalidBlockId;

    return .{
        .block_pos = block_pos,
        .type = event_type,
        .data = data,
        .block = block,
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

const Block = main.Block;
const Client = main.Client;
const Vector3 = main.Vector3;
const S2C = main.network.packet.S2C;
