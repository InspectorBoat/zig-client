const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const Connection = @import("../../../../network/connection.zig").Connection;

key: []const u8,
public_key: []const u8,
nonce: []const u8,

comptime handle_on_network_thread: bool = true,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    return @This(){
        .key = try buffer.readStringAllocating(20, allocator),
        .public_key = try buffer.readByteSliceAllocating(allocator),
        .nonce = try buffer.readByteSliceAllocating(allocator),
    };
}

pub fn handleOnNetworkThread(self: *@This(), connection: *Connection) !void {
    _ = self;
    _ = connection;
}
