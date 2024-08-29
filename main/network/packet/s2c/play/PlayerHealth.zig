const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Game = root.Game;

health: f32,
hunger: i32,
saturation: f32,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return .{
        .health = try buffer.read(f32),
        .hunger = try buffer.readVarInt(),
        .saturation = try buffer.read(f32),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    switch (game.*) {
        .Ingame => |*ingame| {
            _ = self.health; // TODO
            ingame.world.player.player.hunger.food_level = self.hunger;
            ingame.world.player.player.hunger.saturation_level = self.saturation;
        },
        else => unreachable,
    }
}
