const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Connection = root.network.Connection;

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
