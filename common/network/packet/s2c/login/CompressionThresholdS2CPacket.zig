const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const Connection = @import("../../../../network/connection.zig").Connection;

compression_threshold: i32,

comptime handle_on_network_thread: bool = true,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return @This(){
        .compression_threshold = try buffer.readVarInt(),
    };
}

pub fn handleOnNetworkThread(self: *@This(), connection: *Connection) !void {
    connection.setCompressionThreshold(self.compression_threshold);
}
