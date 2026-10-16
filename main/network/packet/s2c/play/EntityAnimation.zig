const std = @import("std");

const main = @import("main");

const Client = main.Client;
const S2C = main.network.packet.S2C;

network_id: i32,
action: Action,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;

    return .{
        .network_id = try buffer.readVarInt(),
        .action = @fromBackingInt(@intCast(try buffer.read(u8))),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}

pub const Action = enum(u8) {
    SwingHand = 0,
    AnimateDamage = 1,
    WakeUp = 2,
    Crit = 4,
    MagicCrit = 5,
    _,
};
