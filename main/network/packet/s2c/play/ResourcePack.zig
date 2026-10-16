const main = @import("main");
const std = @import("std");

const S2C = main.network.packet.S2C;
const Client = main.Client;

url: []const u8,
hash: []const u8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    return .{
        .url = try buffer.readStringAllocating(allocator, 32767),
        .hash = try buffer.readStringAllocating(allocator, 40),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
