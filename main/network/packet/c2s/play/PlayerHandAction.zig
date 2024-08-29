const std = @import("std");
const root = @import("root");
const C2S = root.network.packet.C2S;
const Vector3 = root.Vector3;
const Direction = root.Direction;

block_pos: Vector3(i32),
face: Direction,
action: Action,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeEnum(Action, self.action);
    try buffer.writeBlockPos(self.block_pos);
    try buffer.write(i8, @intFromEnum(self.face));
}

pub const Action = enum(i32) {
    StartDestroyBlock,
    CancelDestroyBlock,
    FinishDestroyBlock,
    DropAllItems,
    DropItem,
    ReleaseUseItem,
};
