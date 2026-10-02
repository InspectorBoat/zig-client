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

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    const block_pos = try buffer.readBlockPos();
    const block_entity_type = try buffer.read(u8);
    return .{
        .block_pos = block_pos,
        .type = block_entity_type,
        .nbt = try NbtCompound.read(buffer, allocator),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
