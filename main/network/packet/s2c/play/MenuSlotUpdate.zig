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
    if (self.menu_network_id == -1) {
        std.log.debug("setting cursor stack: {?}", .{self.item_stack});
        game.world.maybe_cursor_stack = try .dupe(allocator, self.item_stack);
    } else if (self.menu_network_id == 0 and self.slot_id >= 36 and self.slot_id < 45) {
        game.world.player_inventory_menu.setSlot(
            allocator,
            @fromBackingInt(@intCast(self.slot_id)),
            try .dupe(allocator, self.item_stack),
        );
    } else if (self.menu_network_id == game.world.getMenuPtr().network_id) {
        game.world.getMenuPtr().setSlot(
            allocator,
            @fromBackingInt(@intCast(self.slot_id)),
            try .dupe(allocator, self.item_stack),
        );
    }
}

const std = @import("std");

const main = @import("main");

const Client = main.Client;
const Item = main.Item;
const S2C = main.network.packet.S2C;
