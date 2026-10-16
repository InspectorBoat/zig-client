const std = @import("std");

const main = @import("main");

const Client = main.Client;
const S2C = main.network.packet.S2C;

message: []const u8,
type: i8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    return .{
        .message = try buffer.readStringAllocating(allocator, 32767),
        .type = try buffer.read(i8),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    std.debug.print("message: {s} type: {}\n", .{ self.message, self.type });
    _ = allocator;
    _ = game;
}
