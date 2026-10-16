const std = @import("std");

const main = @import("main");

const Client = main.Client;
const ScaledVector = main.network.ScaledVector;
const S2C = main.network.packet.S2C;

network_id: i32,
pos: ScaledVector(i32, 32.0),
xp: i32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;

    const network_id = try buffer.readVarInt();
    const pos: ScaledVector(i32, 32.0) = .{ .raw = .{
        .x = try buffer.read(i32),
        .y = try buffer.read(i32),
        .z = try buffer.read(i32),
    } };
    const xp = try buffer.read(i16);

    return .{
        .network_id = network_id,
        .pos = pos,
        .xp = xp,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
