const std = @import("std");
const root = @import("root");
const c2s = root.network.packet.c2s;

network_id: i32,
action: Action,
data: i32,

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
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
