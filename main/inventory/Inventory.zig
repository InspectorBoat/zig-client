const std = @import("std");

const Item = @import("main").Item;

stacks: []?Item.Stack,
type: Type,

pub const Type = enum {
    player,
    player_crafting,
    crafting_result,
    crafting_table,
    chest,
    hopper,
    dispenser,
    anvil,
    brewing_stand,
    horse,
    furnace,
};

pub fn getEmptyIndex(self: @This()) ?usize {
    switch (self.type) {
        // armor slots don't count
        .player => for (self.stacks[0..36], 0..) |stack, i| {
            if (stack == null) return i;
        } else return null,

        else => std.debug.panic("TODO!", .{}),
    }
}

pub fn hasEmptyIndex(self: @This()) bool {
    return self.getEmptyIndex() != null;
}

pub fn init(allocator: std.mem.Allocator, @"type": Type, slot_count: usize) !*@This() {
    const self = try allocator.create(@This());
    const slots = try allocator.alloc(?Item.Stack, slot_count);
    @memset(slots, null);
    self.* = .{ .stacks = slots, .type = @"type" };
    return self;
}

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    for (self.stacks) |*item_stack| {
        Item.Stack.deinit(allocator, item_stack);
    }
    allocator.free(self.stacks);
    allocator.destroy(self);
}
