const main = @import("main");
const std = @import("std");

const S2C = main.network.packet.S2C;
const Client = main.Client;

name: []const u8,
x: i32,
y: i32,
z: i32,
volume: f32,
pitch: i32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    return .{
        .name = try buffer.readStringAllocating(allocator, 256),
        .x = try buffer.read(i32),
        .y = try buffer.read(i32),
        .z = try buffer.read(i32),
        .volume = try buffer.read(f32),
        .pitch = try buffer.read(u8),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
