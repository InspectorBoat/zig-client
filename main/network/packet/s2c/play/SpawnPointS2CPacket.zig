const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const Vector3 = @import("../../../../math/vector.zig").Vector3;

block_pos: Vector3(i32),

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return @This(){
        .block_pos = try buffer.readBlockPos(),
    };
}

/// Spawn point doesn't do anything for the client, so this is currently unimplemented
pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
