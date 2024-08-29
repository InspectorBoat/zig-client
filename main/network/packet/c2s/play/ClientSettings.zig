const std = @import("std");
const root = @import("root");
const c2s = root.network.packet.c2s;
const ChatVisibility = @import("../../../../chat/chatvisibility.zig").ChatVisibility;

language: []const u8,
view_distance: i8,
chat_visibility: ChatVisibility,
chat_colors: bool,
skin_layers: SkinLayersFlags,

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
    try buffer.writeString(self.language);
    try buffer.write(i8, self.view_distance);
    try buffer.write(i8, @intFromEnum(self.chat_visibility));
    try buffer.write(bool, self.chat_colors);
    try buffer.writePacked(SkinLayersFlags, self.skin_layers);
}

pub const SkinLayersFlags = packed struct {
    cape: bool,
    jacket: bool,
    left_sleeve: bool,
    right_sleeve: bool,
    left_pants_leg: bool,
    right_pants_leg: bool,
    hat: bool,
    _: u1,
};
