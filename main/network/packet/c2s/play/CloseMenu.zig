const std = @import("std");
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");

menu_network_id: i8,

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    try buffer.write(i8, self.menu_network_id);
}
