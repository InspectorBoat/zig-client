const std = @import("std");
const root = @import("root");
const c2s = root.network.packet.c2s;
const ChatVisibility = @import("../../../../chat/chatvisibility.zig").ChatVisibility;

status: Status,

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
    try buffer.writeEnum(Status, self.status);
}

pub const Status = enum(i32) {
    PerformRespawn = 0,
    RequestStats = 1,
    OpenInventoryAchievement = 2,
};
