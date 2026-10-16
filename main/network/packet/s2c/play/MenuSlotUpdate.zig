const main = @import("main");
const std = @import("std");

const S2C = main.network.packet.S2C;
const Client = main.Client;

const ItemStack = main.ItemStack;

menu_network_id: i32,
slot_id: i32,
item_stack: ?ItemStack,

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

    const stack: *?ItemStack = switch (self.menu_network_id) {
        0 => &world.player_inventory_menu.stacks[@intCast(self.slot_id)],
        else => |menu_network_id| blk: {
            if (world.menu != .other or world.menu.other.network_id != menu_network_id) return;
            break :blk &world.menu.other.stacks[@intCast(self.slot_id)];
        },
    };
    stack.* = try .dupe(self.item_stack, allocator);
}
