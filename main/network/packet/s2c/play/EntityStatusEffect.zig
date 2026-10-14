const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

network_id: i32,
effect: i8,
amplifier: i8,
duration: i32,
flags: i8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;

    return .{
        .network_id = try buffer.readVarInt(),
        .effect = try buffer.read(i8),
        .amplifier = try buffer.read(i8),
        .duration = try buffer.readVarInt(),
        .flags = try buffer.read(i8),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, io: std.Io, allocator: std.mem.Allocator) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
