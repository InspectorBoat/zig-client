const main = @import("main");
const std = @import("std");

const S2C = main.network.packet.S2C;
const Client = main.Client;

name: []const u8,
display_name: []const u8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const name = try buffer.readStringAllocating(allocator, 16);

    const action = try buffer.read(i8);

    var display_name: []const u8 = "";
    if (action == 0 or action == 2) {
        display_name = try buffer.readStringAllocating(allocator, 32);
        _ = try buffer.readStringNonAllocating(16);
    }

    return .{
        .name = name,
        .display_name = display_name,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
