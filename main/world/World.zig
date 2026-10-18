const std = @import("std");

const main = @import("main");

pub const Chunk = @import("Chunk.zig");
pub const ChunkMap = @import("ChunkMap.zig");
pub const EntityTracker = @import("EntityTracker.zig");
pub const Section = @import("Section.zig");
pub const TickTimer = @import("TickTimer.zig");
pub const Difficulty = @import("difficulty.zig").Difficulty;
pub const GameMode = @import("gamemode.zig").GameMode;
pub const GeneratorType = @import("generatortype.zig").GeneratorType;

const Block = main.Block;
const Box = main.Box;
const Client = main.Client;
const Direction = main.Direction;
const Entity = main.Entity;
const LocalPlayerEntity = main.Entity.LocalPlayer;
const EventHandler = main.EventHandler;
const Events = main.Events;
const HitResult = main.HitResult;
const Inventory = main.Inventory;
const Menu = main.Menu;
const Vector2xz = main.Vector2xz;
const Vector3 = main.Vector3;
const S2C = main.network.packet.S2C;

chunks: ChunkMap = .{},
player: LocalPlayerEntity,
entity_tracker: EntityTracker,
tick_timer: TickTimer,
difficulty: Difficulty,
dimension: i8,
hardcore: bool,
game_mode: GameMode = .Survival,

main_inventory: *Inventory,
crafting_inventory: *Inventory,
crafting_result_inventory: *Inventory,

player_inventory_menu: Menu,

menu: union(enum) { none, player_menu, other: Menu } = .none,

crosshair: HitResult = .miss,

mining_state: ?struct {
    block_pos: Vector3(i32),
    progress: f32 = 0,
    face: Direction,
} = null,

pub fn init(
    io: std.Io,
    allocator: std.mem.Allocator,
    info: struct { difficulty: Difficulty, game_mode: GameMode, dimension: i8, hardcore: bool },
    player: LocalPlayerEntity,
) !@This() {
    const main_inventory: *Inventory = try .init(allocator, 40);
    const crafting_inventory: *Inventory = try .init(allocator, 4);
    const crafting_result_inventory: *Inventory = try .init(allocator, 1);

    const player_inventory_menu: Menu = try .initPlayerMenu(allocator, main_inventory, crafting_inventory, crafting_result_inventory);

    return .{
        .entity_tracker = try .init(allocator),
        .tick_timer = try .init(io),
        .difficulty = info.difficulty,
        .game_mode = info.game_mode,
        .dimension = info.dimension,
        .hardcore = info.hardcore,
        .main_inventory = main_inventory,
        .crafting_inventory = crafting_inventory,
        .crafting_result_inventory = crafting_result_inventory,
        .player_inventory_menu = player_inventory_menu,
        .player = player,
    };
}

pub fn pick(self: *@This()) void {
    self.crosshair = .rayTraceWorld(.{}, self, self.player.getEyePos(), self.player.base.rotation, 30);
}

pub fn tick(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = allocator;

    self.entity_tracker.processEntityRemovals();
    var entity_iter = self.entity_tracker.entities.keyIterator();
    while (entity_iter.next()) |maybe_entity| {
        try maybe_entity.*.tick(io, game);
    }
    try self.player.tick(io, game);
}

pub fn loadChunk(self: *@This(), allocator: std.mem.Allocator, chunk_pos: Vector2xz(i32)) !*Chunk {
    std.log.scoped(.world).debug("loaded new chunk at {}", .{chunk_pos});

    const chunk = try allocator.create(Chunk);
    chunk.* = .{
        .sections = @splat(null),
        .biomes = @splat(0),
        .chunk_pos = chunk_pos,
    };

    try self.chunks.put(chunk_pos, chunk);

    return chunk;
}

pub fn unloadChunk(self: *@This(), allocator: std.mem.Allocator, chunk_pos: Vector2xz(i32)) !void {
    std.log.scoped(.world).debug("unloaded chunk at {}", .{chunk_pos});

    (try self.chunks.fetchRemove(chunk_pos)).deinit(allocator);
    try EventHandler.dispatch(Events.UnloadChunk, .{ .chunk_pos = chunk_pos });
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

pub fn getBlockState(self: *const @This(), block_pos: Vector3(i32)) Block.PhysicalState {
    if (block_pos.y < 0 or block_pos.y > 255) return .air_blockstate;

    const chunk = self.chunks.get(.{ .x = @divFloor(block_pos.x, 16), .z = @divFloor(block_pos.z, 16) }) orelse return .air_blockstate;
    const section = chunk.sections[@intCast(@divFloor(block_pos.y, 16))] orelse return .air_blockstate;
    const section_block_pos = .{
        .x = @mod(block_pos.x, 16),
        .y = @mod(block_pos.y, 16),
        .z = @mod(block_pos.z, 16),
    };
    return section.block_states[@intCast(section_block_pos.y << 8 | section_block_pos.z << 4 | section_block_pos.x << 0)];
}

pub fn resolveVirtualBlockState(self: *const @This(), block_pos: Vector3(i32)) Block.VirtualState {
    return .resolve(self.getBlockState(block_pos), self, block_pos);
}

pub fn getBlockStatePtr(self: *@This(), block_pos: Vector3(i32)) ?*Block.PhysicalState {
    if (block_pos.y < 0 or block_pos.y > 255) return null;

    const chunk = self.chunks.getPtr(.{ .x = @divFloor(block_pos.x, 16), .z = @divFloor(block_pos.z, 16) }) orelse return null;
    const section = chunk.sections[@intCast(@divFloor(block_pos.y, 16))] orelse return null;
    const section_block_pos: Vector3(i32) = .{
        .x = @mod(block_pos.x, 16),
        .y = @mod(block_pos.y, 16),
        .z = @mod(block_pos.z, 16),
    };
    return &section.block_states[@intCast(section_block_pos.y << 8 | section_block_pos.z << 4 | section_block_pos.x << 0)];
}

pub fn getBlock(self: *const @This(), block_pos: Vector3(i32)) Block {
    if (block_pos.y < 0 or block_pos.y > 255) return .air;

    const chunk = self.chunks.get(.{ .x = @divFloor(block_pos.x, 16), .z = @divFloor(block_pos.z, 16) }) orelse return .air;
    const section = chunk.sections[@intCast(@divFloor(block_pos.y, 16))] orelse return .air;
    const section_block_pos: Vector3(i32) = .{
        .x = @mod(block_pos.x, 16),
        .y = @mod(block_pos.y, 16),
        .z = @mod(block_pos.z, 16),
    };
    return section.block_states[@intCast(section_block_pos.y << 8 | section_block_pos.z << 4 | section_block_pos.x << 0)].block;
}

pub fn setBlockState(self: *@This(), allocator: std.mem.Allocator, block_pos: Vector3(i32), state: Block.PhysicalState) !void {
    const chunk: *Chunk = self.chunks.getPtr(.{ .x = @divFloor(block_pos.x, 16), .z = @divFloor(block_pos.z, 16) }) orelse {
        std.log.scoped(.world).warn("attempted to set block in missing chunk {any}!", .{.{ .x = @divFloor(block_pos.x, 16), .z = @divFloor(block_pos.z, 16) }});
        return;
    };
    const section = chunk.sections[@intCast(@divFloor(block_pos.y, 16))] orelse blk: {
        const section = try allocator.create(Section);
        section.block_states = @splat(.air_blockstate);
        chunk.sections[@intCast(@divFloor(block_pos.y, 16))] = section;
        break :blk section;
    }; // TODO: Check if this is accurate compared to vanilla
    const section_block_pos: Vector3(i32) = .{
        .x = @mod(block_pos.x, 16),
        .y = @mod(block_pos.y, 16),
        .z = @mod(block_pos.z, 16),
    };

    const ptr = &section.block_states[@intCast(section_block_pos.y << 8 | section_block_pos.z << 4 | section_block_pos.x << 0)];
    const prev = ptr.*;
    ptr.* = state;
    if (prev != state) {
        try EventHandler.dispatch(Events.BlockUpdate, .{ .block_pos = block_pos, .world = self });
    }
}

pub fn getBlockLight(self: *const @This(), block_pos: Vector3(i32)) u4 {
    if (block_pos.y < 0 or block_pos.y > 255) return 15;

    const chunk = self.chunks.get(.{ .x = @divFloor(block_pos.x, 16), .z = @divFloor(block_pos.z, 16) }) orelse return 15;
    const section = chunk.sections[@intCast(@divFloor(block_pos.y, 16))] orelse return 15;
    const section_block_pos: Vector3(u4) = .{
        .x = @intCast(@mod(block_pos.x, 16)),
        .y = @intCast(@mod(block_pos.y, 16)),
        .z = @intCast(@mod(block_pos.z, 16)),
    };
    return section.block_light.get(section_block_pos.x, section_block_pos.y, section_block_pos.z);
}

pub fn getSkyLight(self: *const @This(), block_pos: Vector3(i32)) u4 {
    if (block_pos.y < 0 or block_pos.y > 255) return 15;

    const chunk = self.chunks.get(.{ .x = @divFloor(block_pos.x, 16), .z = @divFloor(block_pos.z, 16) }) orelse return 15;
    const section = chunk.sections[@intCast(@divFloor(block_pos.y, 16))] orelse return 15;
    const section_block_pos: Vector3(u4) = .{
        .x = @intCast(@mod(block_pos.x, 16)),
        .y = @intCast(@mod(block_pos.y, 16)),
        .z = @intCast(@mod(block_pos.z, 16)),
    };
    return section.sky_light.get(section_block_pos.x, section_block_pos.y, section_block_pos.z);
}

pub fn receiveChunk(
    self: *@This(),
    allocator: std.mem.Allocator,
    chunk_pos: Vector2xz(i32),
    chunk_data: *S2C.Play.WorldChunk.ChunkData,
    full: bool,
    has_sky_light: bool,
) !void {
    std.log.scoped(.world).debug("updating chunk at {}", .{chunk_pos});

    const chunk = self.chunks.getPtr(chunk_pos).?;
    // copy block state data
    for (0..16) |section_y| {
        if (chunk_data.sections.isSet(@intCast(section_y))) {
            if (chunk.sections[section_y] == null) {
                chunk.sections[section_y] = try allocator.create(Section);
            }
            const section = chunk.sections[section_y].?;

            const raw_block_states = @as(*align(1) const [4096]u16, @ptrCast(try chunk_data.buffer.readArrayNonAllocating(4096 * 2)));
            for (raw_block_states, &section.block_states) |raw_block_state, *concrete_block_state| {
                concrete_block_state.* = .validateRaw(raw_block_state);
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

    try EventHandler.dispatch(Events.ChunkUpdate, .{ .chunk_pos = chunk_pos, .chunk = chunk, .world = self });
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
                const pos: Vector3(i32) = .{ .x = x, .y = y, .z = z };
                const virtual_state: Block.VirtualState = .resolve(
                    self.getBlockState(pos),
                    self,
                    pos,
                );
                var hitboxes_buffer: [5]Box(f64) = undefined;
                var hitboxes: std.ArrayList(Box(f64)) = .initBuffer(&hitboxes_buffer);
                virtual_state.getCollisionHitboxes(&hitboxes);

                for (hitboxes.items) |_| {
                    collisions_count += 1;
                }
            }
        }
    }
    return collisions_count;
}

pub fn getCollisions(self: *const @This(), allocator: std.mem.Allocator, hitbox: Box(f64)) ![]const Box(f64) {
    var collisions: std.ArrayList(Box(f64)) = .empty;
    const min_pos: Vector3(i32) = .{
        .x = @floor(hitbox.min.x),
        .y = @floor(hitbox.min.y),
        .z = @floor(hitbox.min.z),
    };
    const max_pos: Vector3(i32) = .{
        .x = @ceil(hitbox.max.x),
        .y = @ceil(hitbox.max.y),
        .z = @ceil(hitbox.max.z),
    };
    var x = min_pos.x;
    while (x < max_pos.x) : (x += 1) {
        var y = min_pos.y;
        while (y < max_pos.y) : (y += 1) {
            var z = min_pos.z;
            while (z < max_pos.z) : (z += 1) {
                const pos: Vector3(i32) = .{ .x = x, .y = y, .z = z };
                const virtual: Block.VirtualState = .resolve(
                    self.getBlockState(pos),
                    self,
                    pos,
                );
                var local_hitboxes_buffer: [5]Box(f64) = undefined;
                var local_hitboxes: std.ArrayList(Box(f64)) = .initBuffer(&local_hitboxes_buffer);
                virtual.getCollisionHitboxes(&local_hitboxes);
                for (local_hitboxes.items) |block_hitbox| {
                    try collisions.append(allocator, block_hitbox.move(.{ .x = x, .y = y, .z = z }));
                }
            }
        }
    }
    // TODO: Include entities
    return try collisions.toOwnedSlice(allocator);
}

/// Only tests entities
/// TODO: Implement this
pub fn isUnobstructed(self: *const @This(), hitbox: Box(f64)) bool {
    _ = self;
    _ = hitbox;
    return false;
}

/// returns intersecting hitboxes originating from blocks
pub fn getIntersectingBlockHitboxes(self: *@This(), allocator: std.mem.Allocator, hitbox: Box(f64)) []const Box(f64) {
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

pub fn addEntity(self: *@This(), entity: Entity) !*Entity {
    return try self.entity_tracker.addEntity(entity);
}
pub fn queueEntityRemoval(self: *@This(), network_id: i32) !void {
    try self.entity_tracker.queueEntityRemoval(network_id);
}

pub fn getEntityByNetworkId(self: *@This(), network_id: i32) ?*Entity {
    return self.entity_tracker.getEntityByNetworkId(network_id);
}

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    // free chunks
    var chunks = self.chunks.iterator();
    while (chunks.next()) |chunk| {
        std.log.scoped(.world).debug("freeing chunk at {}", .{chunk.chunk_pos});
        chunk.deinit(allocator);
    }
    self.main_inventory.deinit(allocator);
    self.crafting_inventory.deinit(allocator);
    self.crafting_result_inventory.deinit(allocator);
    self.player_inventory_menu.deinit(allocator);

    self.entity_tracker.deinit();

    // TODO
    const milliseconds_elapsed: f64 = 0;
    std.log.scoped(.world).info("average ms/tick: {d} ms", .{milliseconds_elapsed / @as(f64, @floatFromInt(self.tick_timer.total_ticks))});
}
