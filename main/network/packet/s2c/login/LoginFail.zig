const main = @import("main");
const std = @import("std");

const S2C = main.network.packet.S2C;
const Connection = main.network.Connection;

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
