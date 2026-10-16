const main = @import("main");
const std = @import("std");

const S2C = main.network.packet.S2C;
const Client = main.Client;

type: i32,
network_id: i32,
holder_network_id: i32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;

    return .{
        .network_id = try buffer.read(i32),
        .holder_network_id = try buffer.read(i32),
        .type = try buffer.read(u8),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
