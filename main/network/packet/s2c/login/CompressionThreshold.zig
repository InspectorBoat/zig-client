const main = @import("main");
const std = @import("std");

const S2C = main.network.packet.S2C;
const Connection = main.network.Connection;

compression_threshold: i32,

comptime handle_on_network_thread: bool = true,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;
    return .{
        .compression_threshold = try buffer.readVarInt(),
    };
}

pub fn handleOnNetworkThread(self: *@This(), io: std.Io, connection: *Connection) !void {
    _ = io;

    connection.setCompressionThreshold(self.compression_threshold);
}
