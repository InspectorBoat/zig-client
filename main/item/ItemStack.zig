const std = @import("std");

const main = @import("main");

const Direction = main.Direction;
const Entity = main.Entity;
const Item = main.Item;
const Nbt = main.Nbt;
const Vector3 = main.Vector3;
const World = main.World;

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

pub fn canPlace(self: @This(), world: *const World, block_pos: Vector3(i32), dir: Direction) bool {
    _ = world;
    _ = block_pos;
    _ = dir;
    std.debug.assert(self.item.isBlock());

    return true;
}

pub fn useOn(self: @This(), world: *const World, player: *const Entity.LocalPlayer, block_pos: Vector3(i32), dir: Direction, pos: Vector3(f64)) bool {
    _ = self;
    _ = world;
    _ = block_pos;
    _ = dir;
    _ = player;
    _ = pos;
    return true;
}
