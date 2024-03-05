const std = @import("std");
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");
const Vector3 = @import("../../../../type/vector.zig").Vector3;
const Direction = @import("../../../../type/direction.zig").Direction;

block_pos: Vector3(i32),
face: Direction,
action: Action,

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
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
