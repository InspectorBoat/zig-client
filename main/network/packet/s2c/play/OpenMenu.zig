menu_network_id: u8,
menu_type: []const u8,
display_name: []const u8,
size: i32,
owner_network_id: i32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const menu_network_id = try buffer.read(u8);
    const menu_type = try buffer.allocString(allocator, 32);
    const display_name = try buffer.allocString(allocator, 32767);
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

    const menu_type_name = self.menu_type;
    const id: i32 = self.menu_network_id;
    const player_inventory = game.world.main_inventory;
    const size: usize = @intCast(@max(self.size, 0));

    const menu: main.Menu = if (std.mem.eql(u8, menu_type_name,"minecraft:chest") or std.mem.eql(u8, menu_type_name,"minecraft:container"))
        try .initChestMenu(allocator, id, player_inventory, @max(size, 9))
    else if (std.mem.eql(u8, menu_type_name,"minecraft:hopper"))
        try .initHopperMenu(allocator, id, player_inventory, @max(size, 5))
    else if (std.mem.eql(u8, menu_type_name,"minecraft:dispenser") or std.mem.eql(u8, menu_type_name,"minecraft:dropper"))
        try .initDispenserMenu(allocator, id, player_inventory, @max(size, 9))
    else if (std.mem.eql(u8, menu_type_name,"minecraft:crafting_table"))
        try .initCraftingTableMenu(allocator, id, player_inventory)
    else if (std.mem.eql(u8, menu_type_name,"minecraft:furnace"))
        try .initFurnaceMenu(allocator, id, player_inventory)
    else if (std.mem.eql(u8, menu_type_name,"minecraft:anvil"))
        try .initAnvilMenu(allocator, id, player_inventory)
    else if (std.mem.eql(u8, menu_type_name,"minecraft:enchanting_table"))
        try .initEnchantingMenu(allocator, id, player_inventory)
    else if (std.mem.eql(u8, menu_type_name,"minecraft:brewing_stand"))
        try .initBrewingMenu(allocator, id, player_inventory)
    else if (std.mem.eql(u8, menu_type_name,"minecraft:beacon"))
        try .initBeaconMenu(allocator, id, player_inventory)
    else if (std.mem.eql(u8, menu_type_name,"minecraft:villager"))
        try .initTraderMenu(allocator, id, player_inventory)
    else if (std.mem.eql(u8, menu_type_name,"EntityHorse"))
        try .initHorseMenu(allocator, id, player_inventory, (size -| 2) / 5)
    else blk: {
        // Vanilla falls back to a generic chest-style menu for unknown types.
        std.log.warn("unsupported menu type {s}, using chest menu", .{menu_type_name});
        break :blk try main.Menu.initChestMenu(allocator, id, player_inventory, @max(size, 9));
    };

    game.world.openMenu(allocator, .{ .other = menu });
}

const std = @import("std");

const main = @import("main");

const Client = main.Client;
const S2C = main.network.packet.S2C;
