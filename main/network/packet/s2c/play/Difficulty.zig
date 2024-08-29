const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Game = root.Game;
const Difficulty = root.World.Difficulty;

difficulty: Difficulty,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return .{
        .difficulty = (try buffer.readPacked(packed struct { difficulty: Difficulty, _: u6 })).difficulty,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    switch (game.*) {
        .Ingame => |*ingame| {
            ingame.world.difficulty = self.difficulty;
        },
        else => unreachable,
    }
}
