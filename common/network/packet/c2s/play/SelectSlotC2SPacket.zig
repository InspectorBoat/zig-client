const std = @import("std");
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");

slot: i16,

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    try buffer.write(i16, self.slot);
}
