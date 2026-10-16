const main = @import("main");
const std = @import("std");

const C2S = main.network.packet.C2S;
const Vector3 = main.Vector3;
const Direction = main.Direction;

block_pos: Vector3(i32),
face: Direction,
action: Action,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeEnum(Action, self.action);
    try buffer.writeBlockPos(self.block_pos);
    try buffer.write(i8, @backingInt(self.face));
}

pub const Action = enum(i32) {
    start_breaking_block,
    cancel_breaking_block,
    finish_breaking_block,
    drop_entire_stack,
    drop_single_item,
    stop_using_item,
};
