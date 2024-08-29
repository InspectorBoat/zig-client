const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const Stat = @import("../../../../stat/Stat.zig");

stats: []const StatEntry,

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

pub const StatEntry = struct {
    stat: Stat,
    value: i32,
};
