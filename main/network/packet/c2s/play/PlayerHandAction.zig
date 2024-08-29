const std = @import("std");
const root = @import("root");
const c2s = root.network.packet.c2s;
const Vector3 = @import("../../../../math/vector.zig").Vector3;
const Direction = @import("../../../../math/direction.zig").Direction;

block_pos: Vector3(i32),
face: Direction,
action: Action,

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
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
