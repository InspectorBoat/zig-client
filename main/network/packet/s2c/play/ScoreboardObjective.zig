const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

name: []const u8,
display_name: []const u8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    const name = try buffer.readStringAllocating(16, allocator);

    const action = try buffer.read(i8);

    var display_name: []const u8 = "";
    if (action == 0 or action == 2) {
        display_name = try buffer.readStringAllocating(32, allocator);
        _ = try buffer.readStringNonAllocating(16);
    }

    return .{
        .name = name,
        .display_name = display_name,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, io: std.Io, allocator: std.mem.Allocator) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
