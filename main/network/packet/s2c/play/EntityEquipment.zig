const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Game = root.Game;
const ItemStack = root.ItemStack;

network_id: i32,
equipment_slot: i32,
stack: ?ItemStack,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    return .{
        .network_id = try buffer.readVarInt(),
        .equipment_slot = try buffer.read(i16),
        .stack = try buffer.readItemStackAllocating(allocator),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
