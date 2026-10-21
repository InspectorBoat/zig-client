const std = @import("std");

const main = @import("main");

const Client = main.Client;
const Item = main.Item;
const S2C = main.network.packet.S2C;

menu_network_id: i32,
slot_id: i16,
item_stack: ?Item.Stack,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    return .{
        .menu_network_id = try buffer.read(i8),
        .slot_id = try buffer.read(i16),
        .item_stack = try buffer.readItemStackAllocating(allocator),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;
    const world = &game.world;

    switch (self.menu_network_id) {
        0 => {
            world.player_inventory_menu.setSlot(
                allocator,
                @fromBackingInt(@intCast(self.slot_id)),
                try .dupe(allocator, self.item_stack),
            );
        },
        else => |menu_network_id| {
            if (world.menu != .other or world.menu.other.network_id != menu_network_id) return;
            world.menu.other.setSlot(
                allocator,
                @fromBackingInt(@intCast(self.slot_id)),
                try .dupe(allocator, self.item_stack),
            );
        },
    }
}
