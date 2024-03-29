const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");

is_invulnerable: bool,
is_flying: bool,
allow_flying: bool,
creative_mode: bool,
fly_speed: f32,
walk_speed: f32,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    const ability_flags = try buffer.readPacked(AbilityFlags);
    const fly_speed = try buffer.read(f32);
    const walk_speed = try buffer.read(f32);

    return @This(){
        .is_invulnerable = ability_flags.is_invulnerable,
        .is_flying = ability_flags.is_flying,
        .allow_flying = ability_flags.allow_flying,
        .creative_mode = ability_flags.creative_mode,
        .fly_speed = fly_speed,
        .walk_speed = walk_speed,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    switch (game.*) {
        .Ingame => |*ingame| {
            ingame.world.player.abilities = .{
                .is_invulnerable = self.is_invulnerable,
                .is_flying = self.is_flying,
                .allow_flying = self.allow_flying,
                .creative_mode = self.creative_mode,
                .fly_speed = self.fly_speed,
                .walk_speed = self.walk_speed,
            };
        },
        else => unreachable,
    }
}

pub const AbilityFlags = @import("../../../../network/packet/c2s/play/PlayerAbilitiesC2SPacket.zig").AbilityFlags;
