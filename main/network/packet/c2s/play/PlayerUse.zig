const std = @import("std");
const root = @import("root");
const c2s = root.network.packet.c2s;
const Vector3 = @import("../../../../math/vector.zig").Vector3;
const Direction = @import("../../../../math/direction.zig").Direction;
const ItemStack = @import("../../../../item/ItemStack.zig");

block_pos: Vector3(i32),
face: Direction,
stack: ItemStack,
offset: Vector3(f32),

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
    try buffer.writeBlockPos(self.block_pos);
    try buffer.write(i8, @intFromEnum(self.face));
    try buffer.writeItemStack(self.stack);
    try buffer.write(i8, @intFromFloat(self.offset.x * 16.0));
    try buffer.write(i8, @intFromFloat(self.offset.y * 16.0));
    try buffer.write(i8, @intFromFloat(self.offset.z * 16.0));
}
