const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Game = root.Game;
const Vector3 = @import("../../../../math/vector.zig").Vector3;

block_pos: Vector3(i32),

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return .{
        .block_pos = try buffer.readBlockPos(),
    };
}

/// Spawn point doesn't do anything for the client, so this is currently unimplemented
pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
