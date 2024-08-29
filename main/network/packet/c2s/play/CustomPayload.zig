const std = @import("std");
const root = @import("root");
const c2s = root.network.packet.c2s;

channel: []const u8,
data: []const u8,

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
    try buffer.writeString(self.channel);
    if (self.data.len > 32767) return error.CustomPayloadTooLarge;
    try buffer.writeBytes(self.data);
}
