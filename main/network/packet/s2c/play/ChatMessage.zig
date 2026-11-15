message: []const u8,
type: Type,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    return .{
        .message = try buffer.allocString(allocator, 32767),
        .type = @fromBackingInt(try buffer.read(i8)),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    std.log.scoped(.chat).info("{s}", .{self.message});
    _ = allocator;
    _ = game;
}

const Type = enum(i8) {
    chat = 0,
    system = 1,
    overlay = 2,
    _,
};

const std = @import("std");

const main = @import("main");

const Client = main.Client;
const S2C = main.network.packet.S2C;
