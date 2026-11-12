comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}

const std = @import("std");

const main = @import("main");
const Uuid = @import("util").Uuid;

const Client = main.Client;
const S2C = main.network.packet.S2C;
