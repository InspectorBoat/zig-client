const std = @import("std");
const root = @import("root");
const C2S = root.network.packet.C2S;
const ItemStack = root.ItemStack;

slot_id: i16,
item_stack: ItemStack,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.write(i16, self.slot_id);
    try buffer.writeItemStack(self.item_stack);
}
