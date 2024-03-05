const std = @import("std");
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");

time_millis: i32,

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    try buffer.writeVarInt(self.time_millis);
}
