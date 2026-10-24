slot_id: i16,
item_stack: Item.Stack,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.write(i16, self.slot_id);
    try buffer.writeItemStack(self.item_stack);
}

const main = @import("main");

const Item = main.Item;
const C2S = main.network.packet.C2S;
