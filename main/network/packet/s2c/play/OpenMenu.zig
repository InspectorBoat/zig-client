const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

const Menu = root.Menu;
const ItemStack = root.ItemStack;

menu_network_id: i32,
menu_type: []const u8,
display_name: []const u8,
size: i32,
owner_network_id: i32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const menu_network_id = try buffer.read(u8);
    const menu_type = try buffer.readStringAllocating(allocator, 32);
    const display_name = try buffer.readStringAllocating(allocator, 32767);
    const size = try buffer.read(u8);
    const owner_network_id = if (std.mem.eql(u8, menu_type, "EntityHorse")) try buffer.read(i32) else undefined;
    return .{
        .menu_network_id = menu_network_id,
        .menu_type = menu_type,
        .display_name = display_name,
        .size = size,
        .owner_network_id = owner_network_id,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    const world = &game.world;

    switch (world.menu) {
        .other => |*previous_menu| previous_menu.deinit(allocator),
        else => {},
    }

    const stacks = try allocator.alloc(?ItemStack, @intCast(self.size));
    @memset(stacks, null);

    world.menu = .{ .other = .{
        .network_id = self.menu_network_id,
        .stacks = stacks,
    } };
}
