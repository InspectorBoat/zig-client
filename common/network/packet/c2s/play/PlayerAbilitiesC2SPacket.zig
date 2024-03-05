const std = @import("std");
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");

is_invulnerable: bool,
is_flying: bool,
allow_flying: bool,
creative_mode: bool,
fly_speed: f32,
walk_speed: f32,

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    try buffer.writePacked(AbilityFlags, .{
        .creative_mode = self.creative_mode,
        .allow_flying = self.allow_flying,
        .is_flying = self.is_flying,
        .is_invulnerable = self.is_invulnerable,
    });
    try buffer.write(f32, self.fly_speed);
    try buffer.write(f32, self.walk_speed);
}

pub const AbilityFlags = packed struct {
    _: u4 = 0,
    creative_mode: bool,
    allow_flying: bool,
    is_flying: bool,
    is_invulnerable: bool,
};
