const std = @import("std");
const root = @import("root");
const C2S = root.network.packet.C2S;

channel: []const u8,
data: []const u8,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeString(self.channel);
    if (self.data.len > 32767) return error.CustomPayloadTooLarge;
    try buffer.writeBytes(self.data);
}
