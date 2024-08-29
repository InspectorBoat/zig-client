const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Game = root.Game;

network_id: i32,
event: i8,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return .{
        .network_id = try buffer.read(i32),
        .event = try buffer.read(i8),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
