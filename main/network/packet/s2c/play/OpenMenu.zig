const std = @import("std");

const main = @import("main");

const Client = main.Client;
const S2C = main.network.packet.S2C;

menu_network_id: u8,
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

    const menu: main.Menu = if (std.mem.eql(u8, "minecraft:chest", self.menu_type)) try .initChestMenu(
        allocator,
        self.menu_network_id,
        game.world.main_inventory,
        try .init(allocator, .chest, @intCast(self.size)),
    ) else if (std.mem.eql(u8, "minecraft:hopper", self.menu_type)) try .initHopperMenu(
        allocator,
        self.menu_network_id,
        game.world.main_inventory,
        try .init(allocator, .hopper, @intCast(self.size)),
    ) else if (std.mem.eql(u8, "minecraft:dispenser", self.menu_type) or std.mem.eql(u8, "minecraft:dropper", self.menu_type)) try .initDispenserMenu(
        allocator,
        self.menu_network_id,
        game.world.main_inventory,
        try .init(allocator, .dispenser, @intCast(self.size)),
    ) else std.debug.panic("TODO!", .{});

    game.world.openMenu(allocator, .{ .other = menu });
}
