const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Connection = @import("../../../connection.zig").Connection;

reason: []const u8,

comptime handle_on_network_thread: bool = true,

pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    _ = buffer;
    return undefined;
}

pub fn handleOnNetworkThread(self: *@This(), connection: *Connection) !void {
    connection.disconnected.* = true;
    _ = self;
}
