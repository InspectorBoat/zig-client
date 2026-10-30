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

/// One might have the following optimization idea:
/// For packets that need to read item stacks, instead of deserializing the item stack,
/// Why not just copy the raw bytes, then only deserialize on the main thread?
/// Thus, instead of deserializing an item stack (on the network thread), then duping it (on the main thread),
/// we would be copying raw bytes (on the network thread), then deserializing them (on the main thread).
/// Copying bytes is faster than duping an item stack, so this would be a net positive.
/// Unfortunately, this would be a detectable difference from vanilla, because a malformed packet
/// would only be detected when the main thread tries to parse it, instead of being immediately
/// caught by the network thread.
pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;
    if (self.menu_network_id == -1) {
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
