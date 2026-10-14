const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

slot: i32,
objective: []const u8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    return .{
        .slot = try buffer.read(i8),
        .objective = try buffer.readStringAllocating(16, allocator),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, io: std.Io, allocator: std.mem.Allocator) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
