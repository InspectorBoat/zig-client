const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;
const ClientState = root.ClientState;

url: []const u8,
hash: []const u8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: ClientState = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    _ = buffer;
    return undefined;
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
