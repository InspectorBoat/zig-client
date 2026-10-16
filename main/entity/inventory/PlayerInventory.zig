const main = @import("main");

const ItemStack = main.ItemStack;

hotbar_slot: u8 = 0,

pub fn getHeldStack(self: *@This()) ?*ItemStack {
    _ = self; // autofix
    return null;
}
