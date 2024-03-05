const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");

const Vector2 = @import("../../../../type/vector.zig").Vector2;
const Vector3 = @import("../../../../type/vector.zig").Vector3;
const BlockState = @import("../../../../block/BlockState.zig");

chunk_pos: Vector2(i32),
updates: []const BlockUpdate,

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

pub const BlockUpdate = struct {
    pos: Vector3(i32),
    state: BlockState,
};
