const std = @import("std");
const root = @import("root");
const c2s = root.network.packet.c2s;
const ItemStack = @import("../../../../item/ItemStack.zig");

slot_id: i16,
item_stack: ItemStack,

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
    try buffer.write(i16, self.slot_id);
    try buffer.writeItemStack(self.item_stack);
}
