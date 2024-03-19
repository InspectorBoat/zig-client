const std = @import("std");
const Vector2 = @import("../math/vector.zig").Vector2;
const Vector3 = @import("../math/vector.zig").Vector3;
const Chunk = @import("../world/Chunk.zig");
const Section = @import("./Section.zig");
const Game = @import("../game.zig").Game;
const TickTimer = @import("../world/TickTimer.zig");
const Difficulty = @import("../world/difficulty.zig").Difficulty;
const LocalPlayerEntity = @import("../entity/impl/player/LocalPlayerEntity.zig");
const GameMode = @import("../world/gamemode.zig");
const GeneratorType = @import("../world/generatortype.zig").GeneratorType;
const ConnectionHandle = @import("../network/connection.zig").ConnectionHandle;
const Entity = @import("../entity/entity.zig").Entity;
const PlayerMovePositionAndAngles = @import("../network/packet/c2s/play/PlayerMoveC2SPacket.zig").PositionAndAngles;
const PlayerMovePosition = @import("../network/packet/c2s/play/PlayerMoveC2SPacket.zig").Position;
const PlayerMove = @import("../network/packet/c2s/play/PlayerMoveC2SPacket.zig");
const Box = @import("../math/box.zig").Box;
const Block = @import("../block/block.zig").Block;
const ConcreteBlock = @import("../block/block.zig").ConcreteBlock;
const RawBlockState = @import("../block/block.zig").RawBlockState;
const FilteredBlockState = @import("../block/block.zig").FilteredBlockState;
const ConcreteBlockState = @import("../block/block.zig").ConcreteBlockState;
const WorldChunkS2CPacket = @import("../network/packet/s2c/play/WorldChunkS2CPacket.zig");

chunks: std.AutoHashMap(Vector2(i32), Chunk),
player: LocalPlayerEntity,
entities: std.ArrayList(Entity),
tick_timer: TickTimer,
last_tick: std.time.Instant = .{ .timestamp = 0 },
difficulty: Difficulty,
dimension: i8,
hardcore: bool,

pub fn init(info: struct {
    difficulty: Difficulty,
    dimension: i8,
    hardcore: bool,
}, player: LocalPlayerEntity, allocator: std.mem.Allocator) !@This() {
    return .{
        .chunks = std.AutoHashMap(Vector2(i32), Chunk).init(allocator),
        .entities = std.ArrayList(Entity).init(allocator),
        .tick_timer = try TickTimer.init(),
        .last_tick = try std.time.Instant.now(),
        .difficulty = info.difficulty,
        .dimension = info.dimension,
        .hardcore = info.hardcore,
        .player = player,
    };
}

pub fn tick(self: *@This(), game: *Game.IngameState, allocator: std.mem.Allocator) !void {
    _ = allocator; // autofix
    const now = try std.time.Instant.now();

    try self.player.update(game);

    self.last_tick = now;
}

pub fn loadChunk(self: *@This(), chunk_pos: Vector2(i32)) !*Chunk {
    @import("log").load_new_chunk(.{chunk_pos});

    const maybe_chunk = try self.chunks.getOrPut(chunk_pos);
    std.debug.assert(!maybe_chunk.found_existing);

    const chunk = maybe_chunk.value_ptr;
    chunk.* = Chunk{
        .sections = .{null} ** 16,
        .biomes = .{0} ** 256,
    };
    return chunk;
}

pub fn unloadChunk(self: *@This(), chunk_pos: Vector2(i32), allocator: std.mem.Allocator) void {
    if (self.chunks.fetchRemove(chunk_pos)) |entry| {
        var chunk = entry.value;
        chunk.deinit(allocator);
    } else {
        unreachable;
    }
}

pub fn isChunkLoadedAtBlockPos(self: *const @This(), block_pos: Vector3(i32)) bool {
    return isValidBlockPos(block_pos) and self.chunks.contains(.{
        .x = block_pos.x >> 4,
        .z = block_pos.z >> 4,
    });
}

pub fn isValidBlockPos(block_pos: Vector3(i32)) bool {
    return block_pos.x >= -30000000 and block_pos.z >= -30000000 and block_pos.x < 30000000 and block_pos.z < 30000000 and block_pos.y >= 0 and block_pos.y < 256;
}

pub fn getBlockState(self: *const @This(), block_pos: Vector3(i32)) ConcreteBlockState {
    if (block_pos.y < 0 or block_pos.y > 255) return ConcreteBlockState.AIR;

    if (self.chunks.get(.{
        .x = @divFloor(block_pos.x, 16),
        .z = @divFloor(block_pos.z, 16),
    })) |chunk| {
        if (chunk.sections[@intCast(@divFloor(block_pos.y, 16))]) |section| {
            const section_block_pos = .{
                .x = @mod(block_pos.x, 16),
                .y = @mod(block_pos.y, 16),
                .z = @mod(block_pos.z, 16),
            };
            return section.block_states[@intCast(section_block_pos.y << 8 | section_block_pos.z << 4 | section_block_pos.x << 0)];
        }
    }
    return ConcreteBlockState.AIR;
}

pub fn getBlockStatePtr(self: *@This(), block_pos: Vector3(i32)) ?*ConcreteBlockState {
    if (block_pos.y < 0 or block_pos.y > 255) return null;

    if (self.chunks.get(.{
        .x = @divFloor(block_pos.x, 16),
        .z = @divFloor(block_pos.z, 16),
    })) |chunk| {
        if (chunk.sections[@intCast(@divFloor(block_pos.y, 16))]) |section| {
            const section_block_pos = .{
                .x = @mod(block_pos.x, 16),
                .y = @mod(block_pos.y, 16),
                .z = @mod(block_pos.z, 16),
            };
            return &section.block_states[@intCast(section_block_pos.y << 8 | section_block_pos.z << 4 | section_block_pos.x << 0)];
        }
    }
    return null;
}

pub fn getBlock(self: *const @This(), block_pos: Vector3(i32)) ConcreteBlock {
    if (self.chunks.get(.{
        .x = @divFloor(block_pos.x, 16),
        .z = @divFloor(block_pos.z, 16),
    })) |chunk| {
        if (block_pos.y < 0 or block_pos.y > 255) return .air;
        if (chunk.sections[@intCast(@divFloor(block_pos.y, 16))]) |section| {
            const section_block_pos = .{
                .x = @mod(block_pos.x, 16),
                .y = @mod(block_pos.y, 16),
                .z = @mod(block_pos.z, 16),
            };
            return section.block_states[@intCast(section_block_pos.y << 8 | section_block_pos.z << 4 | section_block_pos.x << 0)].block;
        }
    }
    return .air;
}

pub fn setBlockState(self: *@This(), block_pos: Vector3(i32), state: ConcreteBlockState) void {
    if (self.chunks.getPtr(.{
        .x = @divFloor(block_pos.x, 16),
        .z = @divFloor(block_pos.z, 16),
    })) |chunk| {
        if (chunk.sections[@intCast(@divFloor(block_pos.y, 16))]) |section| {
            const section_block_pos = .{
                .x = @mod(block_pos.x, 16),
                .y = @mod(block_pos.y, 16),
                .z = @mod(block_pos.z, 16),
            };
            section.block_states[@intCast(section_block_pos.y << 8 | section_block_pos.z << 4 | section_block_pos.x << 0)] = state;
        } else {
            // std.log.warn("TODO!", .{});
        }
    } else {
        @import("log").set_block_in_missing_chunk(.{Vector2(i32){ .x = @divFloor(block_pos.x, 16), .z = @divFloor(block_pos.z, 16) }});
    }
}

pub fn receiveChunk(
    self: *@This(),
    chunk_pos: Vector2(i32),
    chunk_data: *WorldChunkS2CPacket.ChunkData,
    full: bool,
    has_sky_light: bool,
    allocator: std.mem.Allocator,
) !void {
    @import("log").update_chunk(.{chunk_pos});

    const start = try std.time.Instant.now();
    const chunk = self.chunks.getPtr(chunk_pos).?;
    // copy block state data
    for (0..16) |section_y| {
        if (chunk_data.sections.isSet(@intCast(section_y))) {
            if (chunk.sections[section_y] == null) {
                chunk.sections[section_y] = try allocator.create(Section);
            }
            const section = chunk.sections[section_y].?;

            const raw_block_states = @as(*align(1) const [4096]RawBlockState, @ptrCast(try chunk_data.buffer.readArrayNonAllocating(4096 * 2)));
            for (raw_block_states, &section.block_states) |raw_block_state, *concrete_block_state| {
                concrete_block_state.* = raw_block_state.toFiltered().toConcrete();
            }
        } else {
            if (full) {
                if (chunk.sections[section_y]) |section| {
                    allocator.destroy(section);
                    chunk.sections[section_y] = null;
                }
            }
        }
    }
    // copy block light data
    for (0..16) |section_y| {
        if (chunk_data.sections.isSet(@intCast(section_y))) {
            const section = chunk.sections[section_y].?;
            @memcpy(&section.block_light.bytes, try chunk_data.buffer.readArrayNonAllocating(2048));
        }
    }
    // copy sky light data
    if (has_sky_light) {
        for (0..16) |section_y| {
            if (chunk_data.sections.isSet(@intCast(section_y))) {
                const section = chunk.sections[section_y].?;
                @memcpy(&section.sky_light.bytes, try chunk_data.buffer.readBytesNonAllocating(2048));
            }
        }
    }
    // copy biome data
    if (full) {
        @memcpy(&chunk.biomes, try chunk_data.buffer.readBytesNonAllocating(256));
    }

    self.updateRegion(.{
        .min = .{
            .x = chunk_pos.x * 16 - 1,
            .y = 0,
            .z = chunk_pos.z * 16 - 1,
        },
        .max = .{
            .x = chunk_pos.x * 16 + 16 + 1,
            .y = 255,
            .z = chunk_pos.z * 16 + 16 + 1,
        },
    });

    @import("log").recieved_chunk(.{@as(f64, @floatFromInt((try std.time.Instant.now()).since(start))) / @as(f64, std.time.ns_per_ms)});
    try @import("render").onChunkUpdate(chunk_pos, chunk);
}

// Recomputes virtual properties for all blockstates within region
pub fn updateRegion(self: *@This(), region: Box(i32)) void {
    var x = region.min.x;
    while (x <= region.max.x) : (x += 1) {
        var y = region.min.y;
        while (y <= region.max.y) : (y += 1) {
            var z = region.min.z;
            while (z <= region.max.z) : (z += 1) {
                const block_pos: Vector3(i32) = .{ .x = x, .y = y, .z = z };
                (self.getBlockStatePtr(block_pos) orelse return).update(self.*, block_pos);
            }
        }
    }
}

pub fn getCollisionCount(self: *const @This(), hitbox: Box(f64)) usize {
    var collisions_count: usize = 0;
    const min_pos: Vector3(i32) = .{
        .x = @intFromFloat(@floor(hitbox.min.x)),
        .y = @intFromFloat(@floor(hitbox.min.y)),
        .z = @intFromFloat(@floor(hitbox.min.z)),
    };
    const max_pos: Vector3(i32) = .{
        .x = @intFromFloat(@floor(hitbox.max.x + 1)),
        .y = @intFromFloat(@floor(hitbox.max.y + 1)),
        .z = @intFromFloat(@floor(hitbox.max.z + 1)),
    };
    var x = min_pos.x;
    while (x < max_pos.x) : (x += 1) {
        var y = min_pos.y;
        while (y < max_pos.y) : (y += 1) {
            var z = min_pos.z;
            while (z < max_pos.z) : (z += 1) {
                if (self.getBlockState(.{ .x = x, .y = y, .z = z }).block != .air) {
                    collisions_count += 1;
                }
            }
        }
    }
    return collisions_count;
}

pub fn getCollisions(self: *const @This(), hitbox: Box(f64), allocator: std.mem.Allocator) ![]const Box(f64) {
    var collisions = std.ArrayList(Box(f64)).init(allocator);
    const min_pos: Vector3(i32) = .{
        .x = @intFromFloat(@floor(hitbox.min.x)),
        .y = @intFromFloat(@floor(hitbox.min.y)),
        .z = @intFromFloat(@floor(hitbox.min.z)),
    };
    const max_pos: Vector3(i32) = .{
        .x = @intFromFloat(@floor(hitbox.max.x + 1)),
        .y = @intFromFloat(@floor(hitbox.max.y + 1)),
        .z = @intFromFloat(@floor(hitbox.max.z + 1)),
    };
    var x = min_pos.x;
    while (x < max_pos.x) : (x += 1) {
        var y = min_pos.y;
        while (y < max_pos.y) : (y += 1) {
            var z = min_pos.z;
            while (z < max_pos.z) : (z += 1) {
                if (self.getBlockState(.{ .x = x, .y = y, .z = z }).block != .air) {
                    try collisions.append(Box(f64){
                        .min = .{
                            .x = @floatFromInt(x),
                            .y = @floatFromInt(y),
                            .z = @floatFromInt(z),
                        },
                        .max = .{
                            .x = @floatFromInt(x + 1),
                            .y = @floatFromInt(y + 1),
                            .z = @floatFromInt(z + 1),
                        },
                    });
                }
            }
        }
    }
    // TODO: Include entities
    return try collisions.toOwnedSlice();
}

/// returns intersecting hitboxes originating from blocks
pub fn getIntersectingBlockHitboxes(self: *@This(), hitbox: Box(f64), allocator: std.mem.Allocator) []const Box(f64) {
    const min_pos = Vector3(i32){
        .x = @intFromFloat(hitbox.min.x),
        .y = @intFromFloat(hitbox.min.y),
        .z = @intFromFloat(hitbox.min.z),
    };
    const max_pos = Vector3(i32){
        .x = @intFromFloat(hitbox.min.x),
        .y = @intFromFloat(hitbox.min.y),
        .z = @intFromFloat(hitbox.min.z),
    };
    _ = max_pos; // autofix
    _ = min_pos; // autofix
    _ = allocator; // autofix
    _ = self; // autofix
}

pub fn addEntity(self: *@This(), entity: Entity) !void {
    try self.entities.append(entity);
}

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    // free chunks
    {
        var entries = self.chunks.iterator();
        while (entries.next()) |entry| {
            @import("log").free_chunk(.{entry.key_ptr.*});
            entry.value_ptr.deinit(allocator);
        }
    }
    self.chunks.deinit();
    const milliseconds_elapsed = @as(f64, @floatFromInt(self.tick_timer.timer.read())) / std.time.ns_per_ms;
    @import("log").display_average_tick_ms(.{milliseconds_elapsed / @as(f64, @floatFromInt(self.tick_timer.total_ticks))});
}
