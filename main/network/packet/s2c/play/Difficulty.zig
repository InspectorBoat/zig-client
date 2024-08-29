const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const Difficulty = @import("../../../../world/difficulty.zig").Difficulty;

difficulty: Difficulty,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
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
