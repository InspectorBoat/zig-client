const ItemStack = @import("../../item/ItemStack.zig");
hotbar_slot: u8 = 0,

pub fn getHeldStack(self: *@This()) ?*ItemStack {
    _ = self; // autofix
    return null;
}
