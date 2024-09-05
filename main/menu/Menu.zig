const std = @import("std");
const root = @import("root");
const ItemStack = root.ItemStack;

network_id: i32,
stacks: []?ItemStack,

pub fn deinitItemStacks(self: *@This(), allocator: std.mem.Allocator) void {
    for (self.stacks) |*maybe_stack| {
        ItemStack.deinit(maybe_stack, allocator);
    }
}

pub fn init(network_id: i32, size: usize, allocator: std.mem.Allocator) !@This() {
    const stacks = try allocator.alloc(?ItemStack, size);
    @memset(stacks, null);
    return .{
        .network_id = network_id,
        .stacks = stacks,
    };
}

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    self.deinitItemStacks(allocator);
    allocator.free(self.stacks);
}
