const main = @import("main");
const std = @import("std");

const C2S = main.network.packet.C2S;
const ItemStack = main.ItemStack;

slot_id: i16,
item_stack: ItemStack,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.write(i16, self.slot_id);
    try buffer.writeItemStack(self.item_stack);
}
