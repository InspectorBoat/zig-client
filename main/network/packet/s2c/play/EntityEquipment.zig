network_id: i32,
equipment_slot: i32,
stack: ?Item.Stack,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    return .{
        .network_id = try buffer.readVarInt(),
        .equipment_slot = try buffer.read(i16),
        .stack = try buffer.readItemStackAllocating(allocator),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}

const std = @import("std");

const main = @import("main");

const Client = main.Client;
const Item = main.Item;
const S2C = main.network.packet.S2C;
