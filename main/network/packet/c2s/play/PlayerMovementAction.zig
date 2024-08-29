const std = @import("std");
const root = @import("root");
const C2S = root.network.packet.C2S;

network_id: i32,
action: Action,
data: i32,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
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
