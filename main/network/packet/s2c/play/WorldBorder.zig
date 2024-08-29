const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Game = root.Game;
const Vector2xz = root.Vector2xz;

type: Type,
max_size: i32,
center_pos: Vector2xz(i32),
size_lerp_target: f64,
lerp_size: f64,
lerp_time: i64,
warning_time: i32,
warning_blocks: i32,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    _ = buffer;
    return undefined;
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}

pub const Type = enum {
    SetSize,
    LerpSize,
    SetCenter,
    Initialize,
    SetWarningTime,
    SetWarningBlocks,
};
