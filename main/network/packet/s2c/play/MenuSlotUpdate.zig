const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Game = root.Game;
const ItemStack = root.ItemStack;

menu_id: i32,
slot_id: i32,
item_stack: ItemStack,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    _ = buffer;
    return undefined;
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
