const std = @import("std");
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");
const ItemStack = @import("../../../../item/ItemStack.zig");

slot_id: i16,
item_stack: ItemStack,

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    try buffer.write(i16, self.slot_id);
    try buffer.writeItemStack(self.item_stack);
}
