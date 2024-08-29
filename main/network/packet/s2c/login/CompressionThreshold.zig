const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Connection = root.network.Connection;

compression_threshold: i32,

comptime handle_on_network_thread: bool = true,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return .{
        .compression_threshold = try buffer.readVarInt(),
    };
}

pub fn handleOnNetworkThread(self: *@This(), connection: *Connection) !void {
    connection.setCompressionThreshold(self.compression_threshold);
}
