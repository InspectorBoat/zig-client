const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const ScaledVector = @import("../../../../network/type/scaled_vector.zig").ScaledVector;
const ScaledRotation = @import("../../../../network/type/scaled_rotation.zig").ScaledRotation;

network_id: i32,
pos: ScaledVector(i32, 32.0),
rotation: ScaledRotation(i32, 32.0),

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
