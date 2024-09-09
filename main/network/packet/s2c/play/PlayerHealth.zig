const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

health: f32,
hunger: i32,
saturation: f32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return .{
        .health = try buffer.read(f32),
        .hunger = try buffer.readVarInt(),
        .saturation = try buffer.read(f32),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = self.health; // TODO
    game.world.player.player.hunger.food_level = self.hunger;
    game.world.player.player.hunger.saturation_level = self.saturation;
}
