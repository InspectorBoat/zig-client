const std = @import("std");
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");
const ChatVisibility = @import("../../../../chat/chatvisibility.zig").ChatVisibility;

status: Status,

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    try buffer.writeEnum(Status, self.status);
}

pub const Status = enum(i32) {
    PerformRespawn = 0,
    RequestStats = 1,
    OpenInventoryAchievement = 2,
};
