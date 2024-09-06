const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;
const ClientState = root.ClientState;
const ItemStack = root.ItemStack;

menu_network_id: i32,
slot_id: i32,
item_stack: ?ItemStack,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: ClientState = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    return .{
        .menu_network_id = try buffer.read(i8),
        .slot_id = try buffer.read(i16),
        .item_stack = try buffer.readItemStackAllocating(allocator),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
    const world = &game.world;

    const stack: *?ItemStack = switch (self.menu_network_id) {
        0 => &world.player_inventory_menu.stacks[@intCast(self.slot_id)],
        else => |menu_network_id| blk: {
            if (world.menu != .other or world.menu.other.network_id != menu_network_id) return;
            break :blk &world.menu.other.stacks[@intCast(self.slot_id)];
        },
    };
    stack.* = try ItemStack.dupe(self.item_stack, allocator);
}
