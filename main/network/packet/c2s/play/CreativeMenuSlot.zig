const main = @import("main");

const ItemStack = main.ItemStack;
const C2S = main.network.packet.C2S;

slot_id: i16,
item_stack: ItemStack,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.write(i16, self.slot_id);
    try buffer.writeItemStack(self.item_stack);
}
