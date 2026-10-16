const main = @import("main");
const std = @import("std");

const ItemStack = main.ItemStack;
const Vector3 = main.Vector3;
const Rotation3 = main.Rotation3;

entries: [24]?DataValue = blk: {
    var result: [24]?DataValue = @splat(null);
    result[0] = .{ .i8 = 0 };
    break :blk result;
},

pub fn put(self: *@This(), id: u5, value: DataValue) !void {
    if (self.entries[id] != null) return error.EntryAlreadyExists;
    self.entries[id] = value;
}

pub fn update(self: *@This(), id: u5, value: DataValue) !void {
    if (self.entries[id]) |previous_value| {
        if (std.meta.activeTag(value) == std.meta.activeTag(previous_value)) {
            self.entries[id] = value;
        } else {
            return error.TagMismatch;
        }
    } else {
        return error.MissingEntry;
    }
}

pub const DataTypes = enum(u3) {
    i8,
    i16,
    i32,
    f32,
    String,
    ItemStack,
    BlockPos,
    Rotation,
};

pub const DataValue = union(DataTypes) {
    i8: i8,
    i16: i16,
    i32: i32,
    f32: f32,
    String: []const u8,
    ItemStack: ?ItemStack,
    BlockPos: Vector3(i32),
    Rotation: Rotation3(f32),
};
