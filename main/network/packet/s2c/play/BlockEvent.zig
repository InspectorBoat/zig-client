const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

const Vector3 = root.Vector3;
const Block = root.Block;

block_pos: Vector3(i32),
type: i32,
data: i32,
block: Block,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
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

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, io: std.Io, allocator: std.mem.Allocator) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
