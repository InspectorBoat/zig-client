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

test "performance" {
    std.debug.print("\n\n", .{});

    var gpa_impl = std.heap.GeneralPurposeAllocator(.{ .safety = false }){};
    const gpa = gpa_impl.allocator();

    var rand_impl = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = rand_impl.random();
    const HashMap = std.AutoHashMap(Vector2(i32), Chunk);
    var hash_map_world: DummyWorld(HashMap) = .{ .chunks = HashMap.init(gpa) };
    for (0..1) |x| for (0..1) |z| {
        try hash_map_world.makeChunk(.{ .x = @intCast(x), .z = @intCast(z) }, rand, gpa);
    };
    {
        const start = try std.time.Instant.now();
        defer {
            const end = std.time.Instant.now() catch unreachable;
            std.debug.print("hash_map: {d} ms\n", .{@as(f64, @floatFromInt(end.since(start))) / @as(f64, @floatFromInt(std.time.ns_per_ms))});
        }

        hash_map_world.updateRegion(.{
            .min = .{ .x = 0, .y = 0, .z = 0 },
            .max = .{ .x = 16, .y = 255, .z = 16 },
        });
    }

    var chunk_map_world: DummyWorld(@This()) = .{ .chunks = .{} };
    for (0..1) |x| for (0..1) |z| {
        try chunk_map_world.makeChunk(.{ .x = @intCast(x), .z = @intCast(z) }, rand, gpa);
    };
    {
        const start = try std.time.Instant.now();
        defer {
            const end = std.time.Instant.now() catch unreachable;
            std.debug.print("chunk_map: {d} ms\n", .{@as(f64, @floatFromInt(end.since(start))) / @as(f64, @floatFromInt(std.time.ns_per_ms))});
        }
        chunk_map_world.updateRegion(.{
            .min = .{ .x = 0, .y = 0, .z = 0 },
            .max = .{ .x = 16, .y = 255, .z = 16 },
        });
    }
}

pub fn DummyWorld(comptime MapType: type) type {
    return struct {
        chunks: MapType,
        const Section = @import("./Section.zig");
        const ConcreteBlock = @import("../block/block.zig").ConcreteBlock;
        const Block = @import("../block/block.zig").Block;
        const ConcreteBlockState = @import("../block/block.zig").ConcreteBlockState;
        const RawBlockState = @import("../block/block.zig").RawBlockState;
        const Box = @import("../math/box.zig").Box;
        const Vector3 = @import("../math/vector.zig").Vector3;

        pub fn updateRegion(self: *@This(), region: Box(i32)) void {
            var x = region.min.x;
            while (x <= region.max.x) : (x += 1) {
                var y = region.min.y;
                while (y <= region.max.y) : (y += 1) {
                    var z = region.min.z;
                    while (z <= region.max.z) : (z += 1) {
                        const block_pos: Vector3(i32) = .{ .x = x, .y = y, .z = z };
                        const block_state = self.getBlockStatePtr(block_pos) orelse continue;
                        // std.mem.doNotOptimizeAway(block_state);
                        block_state.updateDummy(self, block_pos);
                    }
                }
            }
        }
        pub fn makeChunk(self: *@This(), chunk_pos: Vector2(i32), rand: std.Random, allocator: std.mem.Allocator) !void {
            var chunk: Chunk = .{
                .biomes = undefined,
                .chunk_pos = chunk_pos,
                .sections = .{null} ** 16,
            };

            for (0..16) |section_y| {
                const section = try allocator.create(Section);
                errdefer allocator.destroy(section);

                for (&section.block_states) |*block_state| {
                    const state: RawBlockState = .{ .block = @intFromEnum(rand.enumValue(Block)), .metadata = rand.int(u4) };
                    block_state.* = state.toFiltered().toConcrete();
                }

                chunk.sections[section_y] = section;
            }
            try self.chunks.put(chunk_pos, chunk);
        }
        pub fn getBlock(self: *@This(), block_pos: Vector3(i32)) ConcreteBlock {
            if (block_pos.y < 0 or block_pos.y > 255) return .air;

            const chunk = self.chunks.getPtr(.{ .x = @divFloor(block_pos.x, 16), .z = @divFloor(block_pos.z, 16) }) orelse return .air;
            const section = chunk.sections[@intCast(@divFloor(block_pos.y, 16))] orelse return .air;
            const section_block_pos = .{
                .x = @mod(block_pos.x, 16),
                .y = @mod(block_pos.y, 16),
                .z = @mod(block_pos.z, 16),
            };
            return section.block_states[@intCast(section_block_pos.y << 8 | section_block_pos.z << 4 | section_block_pos.x << 0)].block;
        }
        pub fn getBlockState(self: *const @This(), block_pos: Vector3(i32)) ConcreteBlockState {
            if (block_pos.y < 0 or block_pos.y > 255) return ConcreteBlockState.AIR;

            const chunk = self.chunks.getPtr(.{ .x = @divFloor(block_pos.x, 16), .z = @divFloor(block_pos.z, 16) }) orelse return ConcreteBlockState.AIR;
            const section = chunk.sections[@intCast(@divFloor(block_pos.y, 16))] orelse return ConcreteBlockState.AIR;
            const section_block_pos = .{
                .x = @mod(block_pos.x, 16),
                .y = @mod(block_pos.y, 16),
                .z = @mod(block_pos.z, 16),
            };
            return section.block_states[@intCast(section_block_pos.y << 8 | section_block_pos.z << 4 | section_block_pos.x << 0)];
        }

        pub fn getBlockStatePtr(self: *@This(), block_pos: Vector3(i32)) ?*ConcreteBlockState {
            if (block_pos.y < 0 or block_pos.y > 255) return null;

            const chunk = self.chunks.getPtr(.{ .x = @divFloor(block_pos.x, 16), .z = @divFloor(block_pos.z, 16) }) orelse return null;
            const section = chunk.sections[@intCast(@divFloor(block_pos.y, 16))] orelse return null;
            const section_block_pos = .{
                .x = @mod(block_pos.x, 16),
                .y = @mod(block_pos.y, 16),
                .z = @mod(block_pos.z, 16),
            };
            return &section.block_states[@intCast(section_block_pos.y << 8 | section_block_pos.z << 4 | section_block_pos.x << 0)];
        }
    };
}
