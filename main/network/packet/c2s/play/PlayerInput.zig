const std = @import("std");
const root = @import("root");
const c2s = root.network.packet.c2s;

sideways_input: f32,
forwards_input: f32,
jumping: bool,
sneaking: bool,

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
    try buffer.write(f32, self.sideways_input);
    try buffer.write(f32, self.forwards_input);
    try buffer.writePacked(JumpSneakFlags, .{
        .jumping = self.jumping,
        .sneaking = self.sneaking,
    });
}

pub const JumpSneakFlags = packed struct {
    _: u6 = 0,
    jumping: bool,
    sneaking: bool,
};
