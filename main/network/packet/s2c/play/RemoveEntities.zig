const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");

network_ids: []const i32,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    _ = buffer;
    return undefined;
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
