chunks: ChunkMap = .{},
player: Entity.LocalPlayer,
entity_tracker: EntityTracker,
tick_timer: TickTimer,
difficulty: Difficulty,
dimension: i8,
hardcore: bool,
game_mode: GameMode = .Survival,

main_inventory: *Inventory,
crafting_inventory: *Inventory,
crafting_result_inventory: *Inventory,

maybe_cursor_stack: ?Item.Stack = null,

player_inventory_menu: Menu,

menu: union(enum) { player_menu, other: Menu } = .player_menu,

menu_screen_open: bool = false,

crosshair: HitResult = .miss,

mining_state: ?struct {
    block_pos: Vector3(i32),
    progress: f32 = 0,
    face: Direction,
} = null,

pub fn getMenu(self: *const @This()) *const Menu {
    if (self.menu == .other) std.debug.assert(self.menu_screen_open);
    return if (self.menu == .player_menu) &self.player_inventory_menu else &self.menu.other;
}
pub fn getMenuPtr(self: *@This()) *Menu {
    if (self.menu == .other) std.debug.assert(self.menu_screen_open);
    return if (self.menu == .player_menu) &self.player_inventory_menu else &self.menu.other;
}
pub fn openMenu(self: *@This(), allocator: std.mem.Allocator, menu: @FieldType(@This(), "menu")) void {
    self.closeMenu(allocator);

    // Holy shit this is a disgusting hack, we need to do things right but whatever
    // TODO: Kill notch for making the client with so many bullshit edge cases
    const game: *Client.Game = @fieldParentPtr("world", self);
    game.input_manager.hand = .{};
    game.input_manager.movement = .{};

    self.menu = menu;
    self.menu_screen_open = true;
}
pub fn closeMenu(self: *@This(), allocator: std.mem.Allocator) void {
    if (!self.menu_screen_open) return;

    if (self.menu == .other) self.menu.other.deinit(allocator);

    self.menu = .player_menu;
    self.menu_screen_open = false;
}

pub fn init(
    io: std.Io,
    allocator: std.mem.Allocator,
    info: struct { difficulty: Difficulty, game_mode: GameMode, dimension: i8, hardcore: bool },
    player: Entity.LocalPlayer,
) !@This() {
    const main_inventory: *Inventory = try .init(allocator, .player, 40);
    const crafting_inventory: *Inventory = try .init(allocator, .player_crafting, 4);
    const crafting_result_inventory: *Inventory = try .init(allocator, .crafting_result, 1);

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
    errdefer allocator.destroy(chunk);

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
    @setRuntimeSafety(false);

    if (block_pos.y < 0 or block_pos.y > 255) return .air;

    const chunk = self.chunks.get(.{ .x = @divFloor(block_pos.x, 16), .z = @divFloor(block_pos.z, 16) }) orelse return .air;
    const section = chunk.sections[@intCast(@divFloor(block_pos.y, 16))] orelse return .air;
    const section_block_pos = .{
        .x = @mod(block_pos.x, 16),
        .y = @mod(block_pos.y, 16),
        .z = @mod(block_pos.z, 16),
    };
    return section.block_states[@intCast(section_block_pos.y << 8 | section_block_pos.z << 4 | section_block_pos.x << 0)];
}

pub fn resolveVirtualBlockState(self: *const @This(), block_pos: Vector3(i32)) Block.VirtualState {
    @setRuntimeSafety(false);

    return .resolve(self.getBlockState(block_pos), self, block_pos);
}

pub fn getBlockStatePtr(self: *@This(), block_pos: Vector3(i32)) ?*Block.PhysicalState {
    @setRuntimeSafety(false);

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
    @setRuntimeSafety(false);

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
        const section: *Section = try .create(allocator);
        section.block_states = @splat(.air);
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
    @setRuntimeSafety(false);

    if (block_pos.y < 0 or block_pos.y > 255) return 15;

    const chunk = self.chunks.get(.{ .x = @divFloor(block_pos.x, 16), .z = @divFloor(block_pos.z, 16) }) orelse return 15;
    const section = chunk.sections[@intCast(@divFloor(block_pos.y, 16))] orelse return 15;
    const section_block_pos: Vector3(u4) = .{
        .x = @intCast(@mod(block_pos.x, 16)),
        .y = @intCast(@mod(block_pos.y, 16)),
        .z = @intCast(@mod(block_pos.z, 16)),
    };
    return section.light[section_block_pos.y][section_block_pos.z][section_block_pos.x].block;
}

pub fn getSkyLight(self: *const @This(), block_pos: Vector3(i32)) u4 {
    @setRuntimeSafety(false);

    if (block_pos.y < 0 or block_pos.y > 255) return 15;

    const chunk = self.chunks.get(.{ .x = @divFloor(block_pos.x, 16), .z = @divFloor(block_pos.z, 16) }) orelse return 15;
    const section = chunk.sections[@intCast(@divFloor(block_pos.y, 16))] orelse return 15;
    const section_block_pos: Vector3(u4) = .{
        .x = @intCast(@mod(block_pos.x, 16)),
        .y = @intCast(@mod(block_pos.y, 16)),
        .z = @intCast(@mod(block_pos.z, 16)),
    };
    return section.light[section_block_pos.y][section_block_pos.z][section_block_pos.x].sky;
}

fn interleaveMask(comptime len: usize) @Vector(2 * len, i32) {
    var mask: [2 * len]i32 = undefined;
    for (0..len) |i| {
        mask[2 * i + 0] = @intCast(i);
        mask[2 * i + 1] = ~@as(i32, @intCast(i));
    }
    return mask;
}

inline fn expandNibbles(bytes: @Vector(64, u8), comptime shift: u3) @Vector(128, u8) {
    const low = (bytes & @as(@Vector(64, u8), @splat(0x0F))) << @as(@Vector(64, u3), @splat(shift));
    const high = (bytes >> @as(@Vector(64, u3), @splat(4))) << @as(@Vector(64, u3), @splat(shift));
    return @shuffle(u8, low, high, interleaveMask(64));
}

pub fn receiveChunk(
    self: *@This(),
    gpa: std.mem.Allocator,
    chunk_pos: Vector2xz(i32),
    chunk_data: S2C.Play.WorldChunk.ChunkData,
    load_or_unload: bool,
    has_sky_light: bool,
) !void {
    @setRuntimeSafety(false);

    std.log.scoped(.world).debug("updating chunk at {}", .{chunk_pos});

    const chunk = self.chunks.getPtr(chunk_pos).?;
    var buffer: S2C.ReadBuffer = .fromOwnedSlice(chunk_data.buffer);
    // copy block state data
    for (0..16) |section_y| {
        if (chunk_data.sections.isSet(@intCast(section_y))) {
            if (chunk.sections[section_y] == null) {
                chunk.sections[section_y] = try .create(gpa);
            }
            const section = chunk.sections[section_y].?;

            const raw_block_states: *align(1) const [4096]u16 = @ptrCast(try buffer.readBytes(4096 * @sizeOf(u16)));
            for (raw_block_states, &section.block_states) |raw_block_state, *block_state| {
                block_state.* = .validate(raw_block_state);
            }
        } else if (load_or_unload) {
            if (chunk.sections[section_y]) |section| {
                section.destroy(gpa);
                chunk.sections[section_y] = null;
            }
        }
    }
    // expand nibbles into bytes, copy into section.light
    for (0..16) |section_y| {
        if (chunk_data.sections.isSet(@intCast(section_y))) {
            const section = chunk.sections[section_y].?;
            const light_bytes = try buffer.readBytes(2048);
            const dst: *[4096]u8 = @ptrCast(&section.light);
            var i: usize = 0;
            while (i < 2048) : (i += 64) {
                const src: @Vector(64, u8) = light_bytes[i..][0..64].*;
                dst[2 * i ..][0..128].* = expandNibbles(src, 0);
            }
        }
    }
    // expand nibbles into bytes, shift right by 4, OR into section.light
    if (has_sky_light) {
        for (0..16) |section_y| {
            if (chunk_data.sections.isSet(@intCast(section_y))) {
                const section = chunk.sections[section_y].?;
                const light_bytes = try buffer.readBytes(2048);
                const dst: *[4096]u8 = @ptrCast(&section.light);
                var i: usize = 0;
                while (i < 2048) : (i += 64) {
                    const src: @Vector(64, u8) = light_bytes[i..][0..64].*;
                    const sky: @Vector(128, u8) = expandNibbles(src, 4);
                    const current: @Vector(128, u8) = dst[2 * i ..][0..128].*;
                    dst[2 * i ..][0..128].* = current | sky;
                }
            }
        }
    }

    // copy biome data
    if (load_or_unload) {
        @memcpy(&chunk.biomes, try buffer.readBytes(256));
    }

    try EventHandler.dispatch(Events.ChunkUpdate, .{ .gpa = gpa, .chunk_pos = chunk_pos, .chunk = chunk, .world = self });
}

pub fn getCollisionCount(self: *const @This(), hitbox: Box(f64)) usize {
    var collisions_count: usize = 0;
    const min: Vector3(i32) = .floor(hitbox.min);
    const max: Vector3(i32) = .ceil(hitbox.max);

    var x = min.x;
    while (x < max.x) : (x += 1) {
        var y = min.y - 1;
        while (y < max.y) : (y += 1) {
            var z = min.z;
            while (z < max.z) : (z += 1) {
                const pos: Vector3(i32) = .{ .x = x, .y = y, .z = z };
                const virtual_state: Block.VirtualState = self.resolveVirtualBlockState(pos);
                var hitboxes_buffer: [5]Box(f64) = undefined;
                var hitboxes: std.ArrayList(Box(f64)) = .initBuffer(&hitboxes_buffer);
                virtual_state.getCollisionHitboxes(&hitboxes);

                for (hitboxes.items) |local_hitbox| {
                    if (hitbox.intersects(local_hitbox.move(.{ .x = x, .y = y, .z = z }))) {
                        collisions_count += 1;
                    }
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
        var y = min_pos.y - 1;
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

pub const Chunk = struct {
    sections: [16]?*Section,
    biomes: [256]u8,
    chunk_pos: Vector2xz(i32),

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        for (self.sections) |maybe_section| if (maybe_section) |section| section.destroy(allocator);
        allocator.destroy(self);
    }
};

pub const Light = packed struct {
    block: u4,
    sky: u4,
};

pub const Section = struct {
    block_states: [16 * 16 * 16]Block.PhysicalState,
    light: [16][16][16]Light,
    borrowers: u32,
    orphaned: bool,

    pub fn create(allocator: std.mem.Allocator) !*@This() {
        @setRuntimeSafety(false);
        const section = try allocator.create(@This());
        section.* = .{
            .block_states = undefined,
            .light = undefined,
            .borrowers = 0,
            .orphaned = false,
        };
        return section;
    }

    pub fn destroy(self: *@This(), allocator: std.mem.Allocator) void {
        std.debug.assert(!self.orphaned);

        self.orphaned = true;
        if (self.borrowers > 0) return;

        std.log.scoped(.world).debug("freeing section", .{});
        allocator.destroy(self);
    }

    pub fn borrow(self: *@This()) *@This() {
        self.borrowers += 1;
        if (self.orphaned) std.log.scoped(.world).warn("borrowing orphaned section", .{});
        return self;
    }

    pub fn release(self: *@This(), allocator: std.mem.Allocator) void {
        self.borrowers -= 1;
        if (self.orphaned and self.borrowers == 0) allocator.destroy(self);
    }
};

const std = @import("std");

const main = @import("main");

pub const ChunkMap = @import("ChunkMap.zig");
pub const EntityTracker = @import("EntityTracker.zig");
pub const TickTimer = @import("TickTimer.zig");
pub const Difficulty = @import("difficulty.zig").Difficulty;
pub const GameMode = @import("gamemode.zig").GameMode;
pub const GeneratorType = @import("generatortype.zig").GeneratorType;

const Block = main.Block;
const Box = main.Box;
const Client = main.Client;
const Direction = main.Direction;
const Entity = main.Entity;
const EventHandler = main.EventHandler;
const Events = main.Events;
const HitResult = main.HitResult;
const Inventory = main.Inventory;
const Item = main.Item;
const Menu = main.Menu;
const Vector2xz = main.Vector2xz;
const Vector3 = main.Vector3;
const S2C = main.network.packet.S2C;
