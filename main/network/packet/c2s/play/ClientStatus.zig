const std = @import("std");
const root = @import("root");
const C2S = root.network.packet.C2S;
const ChatVisibility = @import("../../../../chat/chatvisibility.zig").ChatVisibility;

status: Status,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeEnum(Status, self.status);
}

pub const Status = enum(i32) {
    PerformRespawn = 0,
    RequestStats = 1,
    OpenInventoryAchievement = 2,
};
