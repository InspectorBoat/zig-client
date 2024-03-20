const std = @import("std");
const Vector2 = @import("../math/vector.zig").Vector2;
const Chunk = @import("./Chunk.zig");

metadata: std.bit_set.ArrayBitSet(usize, 32 * 32) = std.bit_set.ArrayBitSet(usize, 32 * 32).initEmpty(),
items: [32 * 32]Chunk = undefined,

pub inline fn contains(self: *const @This(), pos: Vector2(i32)) bool {
    return self.metadata.isSet(toIndex(pos));
}

pub inline fn get(self: *const @This(), pos: Vector2(i32)) ?Chunk {
    if (!self.contains(pos)) return null;
    return self.items[toIndex(pos)];
}

pub inline fn getPtr(self: *@This(), pos: Vector2(i32)) ?*Chunk {
    if (!self.contains(pos)) return null;
    return &self.items[toIndex(pos)];
}

pub inline fn put(self: *@This(), pos: Vector2(i32), chunk: Chunk) !void {
    if (self.contains(pos)) return error.ChunkAlreadyPresent;
    self.metadata.set(toIndex(pos));
    self.items[toIndex(pos)] = chunk;
}

pub inline fn remove(self: *@This(), pos: Vector2(i32)) !void {
    if (!self.contains(pos)) return error.MissingChunk;
    self.metadata.unset(toIndex(pos));
}

pub inline fn fetchRemove(self: *@This(), pos: Vector2(i32)) !*Chunk {
    if (!self.contains(pos)) return error.MissingChunk;
    self.metadata.unset(toIndex(pos));
    return &self.items[toIndex(pos)];
}

pub inline fn toIndex(pos: Vector2(i32)) usize {
    const pos_cast = pos.bitCast(u32);
    return @intCast(((pos_cast.x & 31) << 5) | ((pos_cast.z & 31) << 0));
}

const Self = @This();
const Iterator = struct {
    index: usize = 0,
    map: *Self,
    pub fn next(self: *@This()) ?*Chunk {
        while (true) {
            defer self.index += 1;

            if (self.index >= 32 * 32) return null;
            if (self.map.metadata.isSet(self.index)) {
                return &self.map.items[self.index];
            }
        }
    }
};
pub fn iterator(self: *@This()) Iterator {
    return .{ .map = self };
}

test toIndex {
    var i: usize = 0;
    for (0..32) |x| for (0..32) |z| {
        try std.testing.expectEqual(i, toIndex(.{ .x = @intCast(x), .z = @intCast(z) }));
        i += 1;
    };

    for (0..512) |z| {
        try std.testing.expectEqual(z % 32, toIndex(.{ .x = 0, .z = @intCast(z) }));
    }
    try std.testing.expectEqual(1, toIndex(.{ .x = 0, .z = -31 }));
    try std.testing.expectEqual(1, toIndex(.{ .x = 32, .z = -31 }));
    try std.testing.expectEqual(33, toIndex(.{ .x = 33, .z = -31 }));
}
