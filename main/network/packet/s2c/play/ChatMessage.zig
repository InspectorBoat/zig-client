const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Game = root.Game;

message: []const u8,
type: i8,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    return .{
        .message = try buffer.readStringAllocating(32767, allocator),
        .type = try buffer.read(i8),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    std.debug.print("message: {s} type: {}", .{ self.message, self.type });
    _ = allocator;
    _ = game;
}
