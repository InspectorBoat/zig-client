const std = @import("std");

const main = @import("main");

const Self = @This();
const Chunk = main.Chunk;
const Vector2xz = main.Vector2xz;

const Entry = struct {
    pos: Vector2xz(i32),
    chunk: *Chunk,
};

metadata: std.bit_set.ArrayBitSet(usize, 64 * 64) = .empty,
items: [64 * 64]Entry = undefined,

pub inline fn toIndex(pos: Vector2xz(i32)) usize {
    const pos_cast: Vector2xz(u32) = .bitCast(pos);
    return @intCast(((pos_cast.x & 63) << 6) | ((pos_cast.z & 63) << 0));
}

pub inline fn contains(self: *const @This(), pos: Vector2xz(i32)) bool {
    return self.metadata.isSet(toIndex(pos));
}

pub inline fn get(self: *const @This(), pos: Vector2xz(i32)) ?*const Chunk {
    if (!self.contains(pos)) return null;
    return self.items[toIndex(pos)].chunk;
}

pub inline fn getPtr(self: *@This(), pos: Vector2xz(i32)) ?*Chunk {
    if (!self.contains(pos)) return null;
    return self.items[toIndex(pos)].chunk;
}

pub inline fn put(self: *@This(), pos: Vector2xz(i32), chunk: *Chunk) !void {
    if (self.contains(pos)) {
        if (!self.items[toIndex(pos)].pos.equals(pos)) std.debug.panic("Chunk collision: stored={} new={}", .{ self.items[toIndex(pos)].pos, pos });
        return error.ChunkAlreadyPresent;
    }

    self.metadata.set(toIndex(pos));
    self.items[toIndex(pos)] = .{ .pos = pos, .chunk = chunk };
}

pub inline fn remove(self: *@This(), pos: Vector2xz(i32)) !void {
    if (!self.contains(pos)) return error.MissingChunk;
    self.metadata.unset(toIndex(pos));
}

pub inline fn fetchRemove(self: *@This(), pos: Vector2xz(i32)) !*Chunk {
    if (!self.contains(pos)) return error.MissingChunk;
    self.metadata.unset(toIndex(pos));
    return self.items[toIndex(pos)].chunk;
}

const Iterator = struct {
    index: usize = 0,
    map: *Self,
    pub fn next(self: *@This()) ?*Chunk {
        while (true) {
            defer self.index += 1;

            if (self.index >= self.map.metadata.capacity()) return null;
            if (self.map.metadata.isSet(self.index)) {
                return self.map.items[self.index].chunk;
            }
        }
    }
};
pub fn iterator(self: *@This()) Iterator {
    return .{ .map = self };
}

test toIndex {
    var i: usize = 0;
    for (0..64) |x| for (0..64) |z| {
        try std.testing.expectEqual(i, toIndex(.{ .x = @intCast(x), .z = @intCast(z) }));
        i += 1;
    };

    for (0..64 * 64) |z| {
        try std.testing.expectEqual(z % 64, toIndex(.{ .x = 0, .z = @intCast(z) }));
    }
    try std.testing.expectEqual(1, toIndex(.{ .x = 0, .z = -63 }));
    try std.testing.expectEqual(1, toIndex(.{ .x = 64, .z = -63 }));
    try std.testing.expectEqual(65, toIndex(.{ .x = 65, .z = -63 }));
}
