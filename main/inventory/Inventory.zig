const ItemStack = @import("main").ItemStack;
const std = @import("std");

stacks: []?ItemStack,

pub fn init(allocator: std.mem.Allocator, slot_count: usize) !*@This() {
    const self = try allocator.create(@This());
    const slots = try allocator.alloc(?ItemStack, slot_count);
    @memset(slots, null);
    self.* = .{ .stacks = slots };
    return self;
}

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    for (self.stacks) |*item_stack| {
        ItemStack.deinit(allocator, item_stack);
    }
    allocator.free(self.stacks);
    allocator.destroy(self);
}
