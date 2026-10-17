const std = @import("std");

const main = @import("main");

const Item = main.Item;
const Nbt = main.Nbt;

nbt: ?Nbt.Compound,
item: Item,
size: i32,
metadata: i32,

pub fn dupe(allocator: std.mem.Allocator, maybe_item_stack: ?@This()) !?@This() {
    if (maybe_item_stack) |item_stack| if (item_stack.nbt) |nbt| return .{
        .item = item_stack.item,
        .size = item_stack.size,
        .metadata = item_stack.metadata,
        .nbt = try nbt.dupe(allocator),
    };

    return maybe_item_stack;
}

pub fn deinit(allocator: std.mem.Allocator, maybe_item_stack: *?@This()) void {
    if (maybe_item_stack.*) |*item_stack| if (item_stack.nbt) |*nbt| nbt.deinit(allocator);
}

// TODO: Fix this awful code
pub fn deepEquals(maybe_lhs: ?@This(), maybe_rhs: ?@This()) bool {
    if (maybe_lhs) |lhs| {
        if (maybe_rhs) |rhs| {
            return lhs.item == rhs.item and lhs.metadata == rhs.metadata and lhs.size == rhs.size and blk: {
                break :blk if (lhs.nbt) |lhs_nbt| lhs_nbt.deepEquals(&.{ .compound = rhs.nbt orelse break :blk false }) else rhs.nbt == null;
            };
        } else return false;
    } else return maybe_rhs == null;
}
