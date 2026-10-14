const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Connection = root.network.Connection;

key: []const u8,
public_key: []const u8,
nonce: []const u8,

comptime handle_on_network_thread: bool = true,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    return .{
        .key = try buffer.readStringAllocating(allocator, 20),
        .public_key = try buffer.readByteSliceAllocating(allocator),
        .nonce = try buffer.readByteSliceAllocating(allocator),
    };
}

pub fn handleOnNetworkThread(self: *@This(), io: std.Io, connection: *Connection) !void {
    _ = io;

    _ = self;
    _ = connection;
}
