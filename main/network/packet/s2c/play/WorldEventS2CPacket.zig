const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const Vector3 = @import("../../../../math/vector.zig").Vector3;

event: i32,
block_pos: Vector3(i32),
data: i32,
global: bool,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    _ = buffer; // autofix
    _ = allocator;
    // return .{
    //     .event = try buffer.read(i32),
    //     .pos = try buffer.readBlockPos(),
    //     .data = try buffer.read(i32),
    //     .global = try buffer.read(bool),
    // };
    return undefined;
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
