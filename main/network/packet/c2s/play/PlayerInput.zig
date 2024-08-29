const std = @import("std");
const root = @import("root");
const C2S = root.network.packet.C2S;

sideways_input: f32,
forwards_input: f32,
jumping: bool,
sneaking: bool,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
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
