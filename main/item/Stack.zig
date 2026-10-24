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

pub fn split(self: *@This(), allocator: std.mem.Allocator, items_to_split: i32) !@This() {
    var new_stack: @This() = (try dupe(allocator, self.*)).?;
    self.size -= items_to_split;
    new_stack.size = items_to_split;
    return new_stack;
}

/// Check for item, metadata, and nbt equality
pub fn canMerge(lhs: @This(), rhs: @This()) bool {
    if (lhs.item == rhs.item and lhs.metadata == rhs.metadata) {
        const lhs_has_nbt = lhs.nbt != null;
        const rhs_has_nbt = rhs.nbt != null;
        if (lhs_has_nbt and rhs_has_nbt) return Nbt.deepEquals(&.{ .compound = lhs.nbt.? }, &.{ .compound = rhs.nbt.? });
        return lhs_has_nbt == rhs_has_nbt;
    }
    return false;
}

pub fn deinit(allocator: std.mem.Allocator, maybe_item_stack: *?@This()) void {
    if (maybe_item_stack.*) |*item_stack| if (item_stack.nbt) |*nbt| nbt.deinit(allocator);
}

pub fn deepEquals(lhs: @This(), rhs: @This()) bool {
    return lhs.size == rhs.size and canMerge(lhs, rhs);
}

pub fn useOn(self: @This(), world: *const World, player: *const Entity.LocalPlayer, block_pos: Vector3(i32), dir: Direction, pos: Vector3(f64)) bool {
    _ = self;
    _ = world;
    _ = block_pos;
    _ = dir;
    _ = player;
    _ = pos;
    return false;
}

const std = @import("std");

const main = @import("main");

const Direction = main.Direction;
const Entity = main.Entity;
const Item = main.Item;
const Nbt = main.Nbt;
const Vector3 = main.Vector3;
const World = main.World;
