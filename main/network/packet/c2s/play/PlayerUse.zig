const main = @import("main");

const Direction = main.Direction;
const ItemStack = main.ItemStack;
const Vector3 = main.Vector3;
const C2S = main.network.packet.C2S;

block_pos: ?Vector3(i32),
face: ?Direction,
stack: ItemStack,
offset: ?Vector3(f32),

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeBlockPos(self.block_pos orelse .splat(-1));
    try buffer.write(i8, if (self.face) |face| @backingInt(face) else -1);
    try buffer.writeItemStack(self.stack);

    const offset: Vector3(f32) = self.offset orelse .splat(0.0);
    try buffer.write(i8, @intFromFloat(offset.x * 16.0));
    try buffer.write(i8, @intFromFloat(offset.y * 16.0));
    try buffer.write(i8, @intFromFloat(offset.z * 16.0));
}
