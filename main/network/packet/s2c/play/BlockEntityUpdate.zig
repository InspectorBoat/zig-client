const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

const Vector3 = root.Vector3;
const NbtCompound = root.NbtCompound;

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
