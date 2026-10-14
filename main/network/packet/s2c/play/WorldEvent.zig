const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

const Vector3 = root.Vector3;

event: i32,
block_pos: Vector3(i32),
data: i32,
global: bool,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;

    return .{
        .event = try buffer.read(i32),
        .block_pos = try buffer.readBlockPos(),
        .data = try buffer.read(i32),
        .global = try buffer.read(bool),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
