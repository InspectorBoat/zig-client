const main = @import("main");

const Item = main.Item;

hotbar_slot: u8 = 0,

pub fn getHeldStack(self: *@This()) ?*Item.Stack {
    _ = self; // autofix
    return null;
}
