const std = @import("std");

const main = @import("main");

const Client = main.Client;
const S2C = main.network.packet.S2C;

// this packet is literally useless

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = try buffer.readVarInt();
    _ = try main.NbtCompound.read(allocator, buffer);
    return .{};
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
