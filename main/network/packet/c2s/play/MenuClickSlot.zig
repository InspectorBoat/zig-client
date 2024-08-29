const std = @import("std");
const root = @import("root");
const C2S = root.network.packet.C2S;
const ItemStack = root.ItemStack;

menu_network_id: i8,
slot_id: i16,
click_data: i8,
action_id: i16,
action: i8,
item_stack: ?ItemStack,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.write(i8, self.menu_network_id);
    try buffer.write(i16, self.slot_id);
    try buffer.write(i8, self.click_data);
    try buffer.write(i16, self.action_id);
    try buffer.write(i8, self.action);
    try buffer.writeItemStack(self.item_stack);
}
