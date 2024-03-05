const std = @import("std");
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");
const Vector3 = @import("../../../../type/vector.zig").Vector3;
const Direction = @import("../../../../type/direction.zig").Direction;
const ItemStack = @import("../../../../item/ItemStack.zig");

block_pos: Vector3(i32),
face: Direction,
stack: ItemStack,
offset: Vector3(f32),

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    try buffer.writeBlockPos(self.block_pos);
    try buffer.write(i8, @intFromEnum(self.face));
    try buffer.writeItemStack(self.stack);
    try buffer.write(i8, @intFromFloat(self.offset.x * 16.0));
    try buffer.write(i8, @intFromFloat(self.offset.y * 16.0));
    try buffer.write(i8, @intFromFloat(self.offset.z * 16.0));
}
