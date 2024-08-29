const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Game = root.Game;

channel: []const u8,
data: s2c.ReadBuffer,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    const channel = try buffer.readStringAllocating(20, allocator);
    const remaining_bytes = buffer.remainingBytes();
    if (remaining_bytes > 1048576) return error.CustomPayloadTooLarge;
    const data = try buffer.readRemainingBytesAllocating(allocator);
    return .{
        .channel = channel,
        .data = s2c.ReadBuffer.fromOwnedSlice(data),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = self;
    _ = allocator;
    _ = game;
}
