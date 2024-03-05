const std = @import("std");
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");
const Uuid = @import("../../../../type/Uuid.zig");

targetUuid: Uuid,

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    try buffer.writeUuid(self.targetUuid);
}
