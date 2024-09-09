const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const C2S = root.network.packet.C2S;
const Client = root.Client;

is_invulnerable: bool,
is_flying: bool,
allow_flying: bool,
creative_mode: bool,
fly_speed: f32,
walk_speed: f32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub const AbilityFlags = C2S.Play.PlayerAbilities.AbilityFlags;

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    const ability_flags = try buffer.readPacked(AbilityFlags);
    const fly_speed = try buffer.read(f32);
    const walk_speed = try buffer.read(f32);

    return .{
        .is_invulnerable = ability_flags.is_invulnerable,
        .is_flying = ability_flags.is_flying,
        .allow_flying = ability_flags.allow_flying,
        .creative_mode = ability_flags.creative_mode,
        .fly_speed = fly_speed,
        .walk_speed = walk_speed,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    game.world.player.abilities = .{
        .is_invulnerable = self.is_invulnerable,
        .is_flying = self.is_flying,
        .allow_flying = self.allow_flying,
        .creative_mode = self.creative_mode,
        .fly_speed = self.fly_speed,
        .walk_speed = self.walk_speed,
    };
}
