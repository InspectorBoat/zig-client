const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Game = root.Game;
const Stat = @import("../../../../stat/Stat.zig");

stats: []const StatEntry,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
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
