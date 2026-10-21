const std = @import("std");

const main = @import("main");

const Client = main.Client;
const Item = main.Item;
const Menu = main.Menu;
const S2C = main.network.packet.S2C;

menu_network_id: i32,
stacks: []const ?Item.Stack,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const menu_network_id = try buffer.read(u8);
    const stack_count: usize = @intCast(try buffer.read(i16));
    const stacks = try allocator.alloc(?Item.Stack, stack_count);
    for (stacks) |*stack| {
        stack.* = try buffer.readItemStackAllocating(allocator);
    }
    return .{
        .menu_network_id = menu_network_id,
        .stacks = stacks,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;
    const world = &game.world;

    const menu: *Menu = if (self.menu_network_id == 0)
        &world.player_inventory_menu
    else if (world.menu == .other and world.menu.other.network_id == self.menu_network_id)
        &world.menu.other
    else
        return;

    for (self.stacks, 0..) |new_stack, i| {
        menu.setSlot(allocator, @fromBackingInt(@intCast(i)), try .dupe(allocator, new_stack));
    }
}
