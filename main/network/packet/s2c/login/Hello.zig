const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Connection = root.network.Connection;

key: []const u8,
public_key: []const u8,
nonce: []const u8,

comptime handle_on_network_thread: bool = true,

pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    return .{
        .key = try buffer.readStringAllocating(20, allocator),
        .public_key = try buffer.readByteSliceAllocating(allocator),
        .nonce = try buffer.readByteSliceAllocating(allocator),
    };
}

pub fn handleOnNetworkThread(self: *@This(), connection: *Connection) !void {
    _ = self;
    _ = connection;
}
