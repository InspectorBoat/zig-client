reason: []const u8,

comptime handle_on_network_thread: bool = true,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;
    _ = buffer;
    return undefined;
}

pub fn handleOnNetworkThread(self: *@This(), io: std.Io, connection: *Connection) !void {
    _ = io;

    _ = connection;
    _ = self;
}

const std = @import("std");

const main = @import("main");

const Connection = main.network.Connection;
const S2C = main.network.packet.S2C;
