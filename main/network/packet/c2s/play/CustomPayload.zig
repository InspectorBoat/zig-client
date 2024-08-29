const std = @import("std");
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");

channel: []const u8,
data: []const u8,

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    try buffer.writeString(self.channel);
    if (self.data.len > 32767) return error.CustomPayloadTooLarge;
    try buffer.writeBytes(self.data);
}
