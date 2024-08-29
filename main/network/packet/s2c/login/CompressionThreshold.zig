const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Connection = root.network.Connection;

compression_threshold: i32,

comptime handle_on_network_thread: bool = true,

pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return .{
        .compression_threshold = try buffer.readVarInt(),
    };
}

pub fn handleOnNetworkThread(self: *@This(), connection: *Connection) !void {
    connection.setCompressionThreshold(self.compression_threshold);
}
