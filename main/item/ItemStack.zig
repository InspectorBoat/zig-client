const std = @import("std");
const root = @import("root");
const NbtCompound = root.NbtCompound;
const Item = root.Item;

nbt: ?NbtCompound,
item: Item,
size: i32,
metadata: i32,

pub fn dupe(maybe_item_stack: ?@This(), allocator: std.mem.Allocator) !?@This() {
    if (maybe_item_stack) |item_stack| if (item_stack.nbt) |nbt| return .{
        .item = item_stack.item,
        .size = item_stack.size,
        .metadata = item_stack.metadata,
        .nbt = try nbt.dupe(allocator),
    };

    return maybe_item_stack;
}

pub fn deinit(maybe_item_stack: *?@This(), allocator: std.mem.Allocator) void {
    ((maybe_item_stack.* orelse return).nbt orelse return).deinit(allocator);
}
