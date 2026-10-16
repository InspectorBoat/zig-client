const std = @import("std");

const main = @import("main");

const Client = main.Client;
const NbtCompound = main.NbtCompound;
const Vector3 = main.Vector3;
const S2C = main.network.packet.S2C;

block_pos: Vector3(i32),
type: i32,
nbt: NbtCompound,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const block_pos = try buffer.readBlockPos();
    const block_entity_type = try buffer.read(u8);
    // const nbt: NbtCompound = try .read(allocator, buffer);
    // TODO: Fix nbt decoding
    const nbt: NbtCompound = try .init(allocator, .{});
    return .{
        .block_pos = block_pos,
        .type = block_entity_type,
        .nbt = nbt,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
