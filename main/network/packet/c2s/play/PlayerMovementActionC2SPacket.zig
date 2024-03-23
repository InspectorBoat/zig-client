const std = @import("std");
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");

network_id: i32,
action: Action,
data: i32,

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    try buffer.writeVarInt(self.network_id);
    try buffer.writeEnum(Action, self.action);
    try buffer.writeVarInt(self.data);
}

pub const Action = enum(i32) {
    StartSneaking,
    StopSneaking,
    StopSleeping,
    StartSprinting,
    StopSprinting,
    RidingJump,
    OpenHorseInventory,
};
