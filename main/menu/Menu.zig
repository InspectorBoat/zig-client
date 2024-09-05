const std = @import("std");
const root = @import("root");
const ItemStack = root.ItemStack;

network_id: i32,
stacks: []?ItemStack,

pub fn deinitItemStacks(self: *@This(), allocator: std.mem.Allocator) void {
    for (self.stacks) |*maybe_stack| {
        ((maybe_stack.* orelse continue).nbt orelse continue).deinit(allocator);
    }
}

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    self.deinitItemStacks(allocator);
    allocator.free(self.stacks);
}
