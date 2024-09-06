const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Connection = root.network.Connection;

reason: []const u8,

comptime handle_on_network_thread: bool = true,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    _ = buffer;
    return undefined;
}

pub fn handleOnNetworkThread(self: *@This(), connection: *Connection) !void {
    _ = connection;
    _ = self;
}
