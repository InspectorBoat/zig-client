const std = @import("std");
const root = @import("root");
const ItemStack = root.ItemStack;
const Vector3 = root.Vector3;
const Rotation3 = root.Rotation3;

entries: [32]?DataValue = .{.{ .i8 = 0 }} ++ .{null} ** 31,

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
