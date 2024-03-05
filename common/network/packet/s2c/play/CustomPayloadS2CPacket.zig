const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");

channel: []const u8,
data: ReadPacketBuffer,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    const channel = try buffer.readStringAllocating(20, allocator);
    const remaining_bytes = buffer.remainingBytes();
    if (remaining_bytes > 1048576) return error.CustomPayloadTooLarge;
    const data = try buffer.readRemainingBytesAllocating(allocator);
    return @This(){
        .channel = channel,
        .data = ReadPacketBuffer.fromOwnedSlice(data),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = self;
    _ = allocator;
    _ = game;
}
