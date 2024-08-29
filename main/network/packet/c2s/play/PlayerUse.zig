const std = @import("std");
const root = @import("root");
const C2S = root.network.packet.C2S;
const Vector3 = root.Vector3;
const Direction = root.Direction;
const ItemStack = root.ItemStack;

block_pos: Vector3(i32),
face: Direction,
stack: ItemStack,
offset: Vector3(f32),

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeBlockPos(self.block_pos);
    try buffer.write(i8, @intFromEnum(self.face));
    try buffer.writeItemStack(self.stack);
    try buffer.write(i8, @intFromFloat(self.offset.x * 16.0));
    try buffer.write(i8, @intFromFloat(self.offset.y * 16.0));
    try buffer.write(i8, @intFromFloat(self.offset.z * 16.0));
}
