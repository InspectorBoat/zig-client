const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Game = root.Game;

owner: []const u8,
objective: []const u8,
score: []const u8,
action: Action,

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

pub const Action = enum {
    Change,
    Remove,
};
