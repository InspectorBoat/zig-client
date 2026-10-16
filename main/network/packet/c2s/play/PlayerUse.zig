const main = @import("main");
const std = @import("std");

const C2S = main.network.packet.C2S;
const Vector3 = main.Vector3;
const Direction = main.Direction;
const ItemStack = main.ItemStack;

block_pos: Vector3(i32),
face: Direction,
stack: ItemStack,
offset: Vector3(f32),

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeBlockPos(self.block_pos);
    try buffer.write(i8, @backingInt(self.face));
    try buffer.writeItemStack(self.stack);
    try buffer.write(i8, @intFromFloat(self.offset.x * 16.0));
    try buffer.write(i8, @intFromFloat(self.offset.y * 16.0));
    try buffer.write(i8, @intFromFloat(self.offset.z * 16.0));
}
