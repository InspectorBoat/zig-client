const std = @import("std");
const root = @import("root");
const World = root.World;
const Vector3 = root.Vector3;
const Box = root.Box;
const Direction = root.Direction;

// In minecraft versions <1.13, chunks store block(states) packed in 16 bits:
// <block type: 12 bits>|<block metadata: 4 bits>
// Block type denotes well, the specific type of the block, such as dirt,
// water, torches, packed ice, etc.
// Metadata denotes the state the block it is in - e.g. for levers, powered vs
// unpowered and what face it is attached to.
// Of course, there are some stupid exceptions, like stone, where
// andesite, diorite, granite, and their polished variants are all metadata
// of the same block type (stone).
// So sometimes metadata only determines the transient state of the block
// (like the shape of a fence), but other times metadata actually
// persists after breaking the block and placing it back down.

// As if this system wasn't bad enough, you may notice that
// some blocks should actually require more than 4 bits to
// store their block state! For example, redstone dust
// stores power level (0-15), then for each cardinal direction,
// whether there is a flat, rising, or no connection.
// That's 16 * 3 * 3 * 3 * 3, or 1296 states, which obviously
// can't fit within 4 bits.
// What actually happens is that the game just recomputes them on demand
// based on the neighboring blocks. See Block.resolveVirtualProperties (in java).
// (Note that Block.resolveVirtualProperties is only called for rendering
// and in the client debug overlay, but essentially similar logic is used
// throughout for other tasks like getting collisions.)
// For an especially convoluted example: Doors have facing (n/e/s/w),
// open (bool), hinge (left/right), powered (bool), and half (upper/lower).
// Half is always a stored property, but only the lower half stores facing
// and open, and only the upper half stores hinge and powered.
// So each half has to look at the other to retrieve the state it doesn't
// have.

/// The types of each block
pub const Block = enum(u8) {
    air,
    stone,
    grass,
    dirt,
    cobblestone,
    planks,
    sapling,
    bedrock,
    flowing_water,
    water,
    flowing_lava,
    lava,
    sand,
    gravel,
    gold_ore,
    iron_ore,
    coal_ore,
    log,
    leaves,
    sponge,
    glass,
    lapis_ore,
    lapis_block,
    dispenser,
    sandstone,
    noteblock,
    bed,
    golden_rail,
    detector_rail,
    sticky_piston,
    web,
    tallgrass,
    deadbush,
    piston,
    piston_head,
    wool,
    piston_extension,
    yellow_flower,
    red_flower,
    brown_mushroom,
    red_mushroom,
    gold_block,
    iron_block,
    double_stone_slab,
    stone_slab,
    brick_block,
    tnt,
    bookshelf,
    mossy_cobblestone,
    obsidian,
    torch,
    fire,
    mob_spawner,
    oak_stairs,
    chest,
    redstone_wire,
    diamond_ore,
    diamond_block,
    crafting_table,
    wheat,
    farmland,
    furnace,
    lit_furnace,
    standing_sign,
    wooden_door,
    ladder,
    rail,
    stone_stairs,
    wall_sign,
    lever,
    stone_pressure_plate,
    iron_door,
    wooden_pressure_plate,
    redstone_ore,
    lit_redstone_ore,
    unlit_redstone_torch,
    redstone_torch,
    stone_button,
    snow_layer,
    ice,
    snow,
    cactus,
    clay,
    reeds,
    jukebox,
    fence,
    pumpkin,
    netherrack,
    soul_sand,
    glowstone,
    portal,
    lit_pumpkin,
    cake,
    unpowered_repeater,
    powered_repeater,
    stained_glass,
    trapdoor,
    monster_egg,
    stonebrick,
    brown_mushroom_block,
    red_mushroom_block,
    iron_bars,
    glass_pane,
    melon_block,
    pumpkin_stem,
    melon_stem,
    vine,
    fence_gate,
    brick_stairs,
    stone_brick_stairs,
    mycelium,
    waterlily,
    nether_brick,
    nether_brick_fence,
    nether_brick_stairs,
    nether_wart,
    enchanting_table,
    brewing_stand,
    cauldron,
    end_portal,
    end_portal_frame,
    end_stone,
    dragon_egg,
    redstone_lamp,
    lit_redstone_lamp,
    double_wooden_slab,
    wooden_slab,
    cocoa,
    sandstone_stairs,
    emerald_ore,
    ender_chest,
    tripwire_hook,
    tripwire,
    emerald_block,
    spruce_stairs,
    birch_stairs,
    jungle_stairs,
    command_block,
    beacon,
    cobblestone_wall,
    flower_pot,
    carrots,
    potatoes,
    wooden_button,
    skull,
    anvil,
    trapped_chest,
    light_weighted_pressure_plate,
    heavy_weighted_pressure_plate,
    unpowered_comparator,
    powered_comparator,
    daylight_detector,
    redstone_block,
    quartz_ore,
    hopper,
    quartz_block,
    quartz_stairs,
    activator_rail,
    dropper,
    stained_hardened_clay,
    stained_glass_pane,
    leaves2,
    log2,
    acacia_stairs,
    dark_oak_stairs,
    slime,
    barrier,
    iron_trapdoor,
    prismarine,
    sea_lantern,
    hay_block,
    carpet,
    hardened_clay,
    coal_block,
    packed_ice,
    double_plant,
    standing_banner,
    wall_banner,
    daylight_detector_inverted,
    red_sandstone,
    red_sandstone_stairs,
    double_stone_slab2,
    stone_slab2,
    spruce_fence_gate,
    birch_fence_gate,
    jungle_fence_gate,
    dark_oak_fence_gate,
    acacia_fence_gate,
    spruce_fence,
    birch_fence,
    jungle_fence,
    dark_oak_fence,
    acacia_fence,
    spruce_door,
    birch_door,
    jungle_door,
    acacia_door,
    dark_oak_door,

    pub fn getFriction(self: @This()) f32 {
        return switch (self) {
            .slime => 0.8,
            .ice, .packed_ice => 0.98,
            else => 0.6,
        };
    }

    pub fn isFullCube(self: @This()) bool {
        return @import("full_cube_table.zig").@"export".get(self);
    }

    pub fn isSolid(self: @This()) bool {
        return self.isFullCube();
    }
};

pub const PhysicalBlockState = packed struct(u16) {
    _: u4 = 0,
    block: Block,
    properties: PhysicalProperties,

    pub const air_blockstate: @This() = .{
        .block = .air,
        .properties = .{ .air = .{} },
    };

    pub fn validateRaw(raw: u16) @This() {
        const high_bits: u12 = @intCast(raw >> 4);
        const block: Block = if (high_bits <= 197) @enumFromInt(high_bits) else return .air_blockstate;
        const low_bits: u4 = @intCast(raw & 0b1111);
        if (!@import("valid_metadata_table.zig").@"export".get(block).isSet(low_bits)) {
            return .air_blockstate;
        }
        return @bitCast(raw);
    }
    pub fn payload(self: @This(), comptime block: Block) @TypeOf(@field(self.properties, @tagName(block))) {
        std.debug.assert(self.block == block);
        return @field(self.properties, @tagName(block));
    }
};

const virtual_properties = @import("virtual_properties.zig");
pub const VirtualProperties = virtual_properties.VirtualProperties;
pub const StairShape = virtual_properties.StairShape;
pub const StemFacing = virtual_properties.StemFacing;
pub const DoorFacing = virtual_properties.DoorFacing;

const StairPhysical = @FieldType(PhysicalProperties, "oak_stairs");

fn stairProps(state: PhysicalBlockState) StairPhysical {
    return state.properties.oak_stairs;
}

fn isSnow(block: Block) bool {
    return block == .snow or block == .snow_layer;
}

fn isFence(block: Block) bool {
    return switch (block) {
        .fence, .nether_brick_fence, .spruce_fence, .birch_fence, .jungle_fence, .dark_oak_fence, .acacia_fence => true,
        else => false,
    };
}

fn isFenceGate(block: Block) bool {
    return switch (block) {
        .fence_gate, .spruce_fence_gate, .birch_fence_gate, .jungle_fence_gate, .dark_oak_fence_gate, .acacia_fence_gate => true,
        else => false,
    };
}

fn isStair(block: Block) bool {
    return switch (block) {
        .oak_stairs, .stone_stairs, .brick_stairs, .stone_brick_stairs, .nether_brick_stairs, .sandstone_stairs, .spruce_stairs, .birch_stairs, .jungle_stairs, .quartz_stairs, .acacia_stairs, .dark_oak_stairs, .red_sandstone_stairs => true,
        else => false,
    };
}

// STUB
fn isSolidCube(block: Block) bool {
    return block.isFullCube() and block != .pumpkin and block != .lit_pumpkin;
}

fn fenceShouldConnectTo(world: *const World, block_pos: Vector3(i32), self_block: Block) bool {
    const neighbour = world.getBlock(block_pos);
    if (neighbour == .barrier) return false;
    if (isFence(neighbour)) return (neighbour == .nether_brick_fence) == (self_block == .nether_brick_fence);
    if (isFenceGate(neighbour)) return true;
    return isSolidCube(neighbour);
}

fn paneShouldConnectTo(neighbour: Block) bool {
    return switch (neighbour) {
        .iron_bars, .glass_pane, .stained_glass_pane, .glass, .stained_glass => true,
        else => isSolidCube(neighbour),
    };
}

fn wallShouldConnectTo(world: *const World, block_pos: Vector3(i32)) bool {
    const neighbour = world.getBlock(block_pos);
    if (neighbour == .barrier) return false;
    if (neighbour == .cobblestone_wall or isFenceGate(neighbour)) return true;
    return isSolidCube(neighbour);
}

fn tripwireShouldConnectTo(world: *const World, block_pos: Vector3(i32), suspended: bool, dir: HorizontalFacing) bool {
    const neighbour = world.getBlockState(block_pos.dir(.from(dir)));
    return switch (neighbour.block) {
        .tripwire_hook => {
            const neighbor_facing = neighbour.payload(.tripwire_hook).facing;
            return switch (dir) {
                .north => neighbor_facing == .south,
                .south => neighbor_facing == .north,
                .west => neighbor_facing == .east,
                .east => neighbor_facing == .west,
            };
        },
        .tripwire => neighbour.payload(.tripwire).suspended == suspended,
        else => false,
    };
}

/// `World.hasSolidTop`. The cube test is approximated by `isFullCube()`.
fn hasSolidTop(world: *const World, block_pos: Vector3(i32)) bool {
    const state = world.getBlockState(block_pos);
    switch (state.block) {
        .hopper => return true,
        .snow_layer => return state.payload(.snow_layer).layers == 7,
        .stone_slab => return state.payload(.stone_slab).half == .top,
        .wooden_slab => return state.payload(.wooden_slab).half == .top,
        .stone_slab2 => return state.payload(.stone_slab2).half == .top,
        else => {},
    }
    if (isStair(state.block)) return stairProps(state).half == .top;
    return state.block.isFullCube();
}

fn stemFacingFor(world: *const World, block_pos: Vector3(i32), self_block: Block) u3 {
    const plant: Block = if (self_block == .pumpkin_stem) .melon_block else .pumpkin;
    const dirs: []const Direction = &.{ .north, .south, .west, .east };
    for (dirs, 0..) |dir, i| {
        if (world.getBlock(block_pos.dir(dir)) == plant) return @intCast(i + 1);
    }
    return 0; // up
}

fn isStairSameHalfSameFacing(world: *const World, other_pos: Vector3(i32), self_props: anytype) bool {
    const other = world.getBlockState(other_pos);
    if (!isStair(other.block)) return false;
    const p = stairProps(other);
    return p.half == self_props.half and p.facing == self_props.facing;
}

fn isInnerStair(world: *const World, block_pos: Vector3(i32), self_props: anytype) bool {
    const facing = self_props.facing;
    // Where a same-half neighbour is looked for, and which two facings it may present.
    const first: StairFacing, const second: StairFacing = switch (facing) {
        .east, .west => .{ .north, .south },
        .south, .north => .{ .west, .east },
    };

    const neighbour = world.getBlockState(block_pos.dir(switch (facing) {
        .east => .east,
        .west => .west,
        .south => .south,
        .north => .north,
    }));
    if (!isStair(neighbour.block) or stairProps(neighbour).half != self_props.half) return true;
    const neighbour_facing = stairProps(neighbour).facing;
    if (neighbour_facing == first and
        !isStairSameHalfSameFacing(world, block_pos.dir(.from(second)), self_props)) return false;
    if (neighbour_facing == second and
        !isStairSameHalfSameFacing(world, block_pos.dir(.from(first)), self_props)) return false;
    return true;
}

fn stairCorner(world: *const World, block_pos: Vector3(i32), self_props: anytype, inner: bool) u2 {
    const top = self_props.half == .top;
    const facing = self_props.facing;

    const neighbour_dir: StairFacing = if (inner) switch (facing) {
        .east => .west,
        .west => .east,
        .south => .north,
        .north => .south,
    } else facing;
    const first: StairFacing, const second: StairFacing = switch (facing) {
        .east, .west => .{ .north, .south },
        .south, .north => .{ .west, .east },
    };

    const check_first = if (inner) first else second;
    const check_second = if (inner) second else first;

    const neighbour = world.getBlockState(block_pos.dir(.from(neighbour_dir)));
    if (!isStair(neighbour.block) or stairProps(neighbour).half != self_props.half) return 0;
    const neighbour_facing = stairProps(neighbour).facing;

    const first_value: u2, const second_value: u2 = switch (facing) {
        .east, .north => .{ if (top) 1 else 2, if (top) 2 else 1 },
        .west, .south => .{ if (top) 2 else 1, if (top) 1 else 2 },
    };

    if (neighbour_facing == first and !isStairSameHalfSameFacing(world, block_pos.dir(.from(check_first)), self_props)) {
        return first_value;
    }
    if (neighbour_facing == second and !isStairSameHalfSameFacing(world, block_pos.dir(.from(check_second)), self_props)) {
        return second_value;
    }
    return 0;
}

fn resolveStairShape(world: *const World, block_pos: Vector3(i32)) StairShape {
    const props = stairProps(world.getBlockState(block_pos));
    if (isInnerStair(world, block_pos, props)) {
        return switch (stairCorner(world, block_pos, props, true)) {
            1 => .inner_right,
            2 => .inner_left,
            else => .straight,
        };
    }
    return switch (stairCorner(world, block_pos, props, false)) {
        1 => .outer_right,
        2 => .outer_left,
        else => .straight,
    };
}

/// Constructed per read. Do NOT store it anywhere! Invalidates on neighboring block changes
pub const VirtualBlockState = struct {
    block: Block,
    properties: PhysicalProperties,
    virtual: VirtualProperties,

    pub const air_blockstate: @This() = .{
        .block = .air,
        .properties = .{ .air = .{} },
        .virtual = .{ .air = .{} },
    };

    pub fn payload(self: @This(), comptime block: Block) @TypeOf(@field(self.properties, @tagName(block))) {
        std.debug.assert(self.block == block);
        return @field(self.properties, @tagName(block));
    }

    /// Computes the virtual properties of `physical` at `block_pos`.
    pub fn resolve(physical: PhysicalBlockState, world: *const World, block_pos: Vector3(i32)) @This() {
        var self: @This() = .{
            .block = physical.block,
            .properties = physical.properties,
            .virtual = undefined,
        };

        switch (self.block) {
            .grass => self.virtual = .{ .grass = .{ .snowy = isSnow(world.getBlockState(block_pos.up()).block) } },
            .mycelium => self.virtual = .{ .mycelium = .{ .snowy = isSnow(world.getBlockState(block_pos.up()).block) } },
            .dirt => self.virtual = .{ .dirt = .{ .snowy = physical.payload(.dirt).variant == .podzol and isSnow(world.getBlockState(block_pos.up()).block) } },
            .bed => {
                var occupied = false;
                if (physical.payload(.bed).part == .foot) {
                    const other = world.getBlockState(block_pos.dir(.from(physical.payload(.bed).facing)));
                    if (other.block == .bed) occupied = other.payload(.bed).occupied;
                }
                self.virtual = .{ .bed = .{ .occupied = occupied } };
            },
            .vine => self.virtual = .{ .vine = .{ .up = world.getBlock(block_pos.up()).isFullCube() } },
            .tripwire_hook => self.virtual = .{ .tripwire_hook = .{ .suspended = !hasSolidTop(world, block_pos.down()) } },

            inline .fence_gate,
            .spruce_fence_gate,
            .birch_fence_gate,
            .jungle_fence_gate,
            .dark_oak_fence_gate,
            .acacia_fence_gate,
            => |block| {
                const facing = physical.payload(block).facing;
                const in_wall = switch (facing) {
                    .north, .south => world.getBlock(block_pos.west()) == .cobblestone_wall or
                        world.getBlock(block_pos.east()) == .cobblestone_wall,
                    .west, .east => world.getBlock(block_pos.north()) == .cobblestone_wall or
                        world.getBlock(block_pos.south()) == .cobblestone_wall,
                };
                self.virtual = @unionInit(VirtualProperties, @tagName(block), .{ .in_wall = in_wall });
            },

            inline .wooden_door,
            .iron_door,
            .spruce_door,
            .birch_door,
            .jungle_door,
            .acacia_door,
            .dark_oak_door,
            => |block| {
                const half = physical.payload(block).half;
                const own = physical.payload(block);
                const other = world.getBlockState(if (half == .lower) block_pos.up() else block_pos.down());
                const joined = other.block == self.block;
                const other_props = other.payload(block);
                self.virtual = @unionInit(
                    VirtualProperties,
                    @tagName(block),
                    if (half == .lower) .{
                        .open = own.other.when_lower.open,
                        .facing = @enumFromInt(@intFromEnum(own.other.when_lower.facing)),
                        .hinge_right = joined and other_props.other.when_upper.hinge_right,
                        .powered = joined and other_props.other.when_upper.powered,
                    } else .{
                        .open = joined and other_props.other.when_lower.open,
                        .facing = @enumFromInt(@as(u2, if (joined) @intFromEnum(other_props.other.when_lower.facing) else 0)),
                        .hinge_right = own.other.when_upper.hinge_right,
                        .powered = own.other.when_upper.powered,
                    },
                );
            },

            .pumpkin_stem => self.virtual = .{ .pumpkin_stem = .{ .facing = @enumFromInt(stemFacingFor(world, block_pos, .pumpkin_stem)) } },
            .melon_stem => self.virtual = .{ .melon_stem = .{ .facing = @enumFromInt(stemFacingFor(world, block_pos, .melon_stem)) } },

            .double_plant => {
                if (physical.payload(.double_plant).half == .upper) {
                    const below = world.getBlockState(block_pos.down());
                    if (below.block == .double_plant) {
                        self.virtual = .{ .double_plant = .{ .variant = below.payload(.double_plant).variant } };
                    }
                }
            },

            inline .fence,
            .nether_brick_fence,
            .spruce_fence,
            .birch_fence,
            .jungle_fence,
            .dark_oak_fence,
            .acacia_fence,
            => |block| self.virtual = @unionInit(VirtualProperties, @tagName(block), .{
                .north = fenceShouldConnectTo(world, block_pos.north(), block),
                .east = fenceShouldConnectTo(world, block_pos.east(), block),
                .south = fenceShouldConnectTo(world, block_pos.south(), block),
                .west = fenceShouldConnectTo(world, block_pos.west(), block),
            }),

            .iron_bars => self.virtual = .{ .iron_bars = .{
                .north = paneShouldConnectTo(world.getBlock(block_pos.north())),
                .south = paneShouldConnectTo(world.getBlock(block_pos.south())),
                .west = paneShouldConnectTo(world.getBlock(block_pos.west())),
                .east = paneShouldConnectTo(world.getBlock(block_pos.east())),
            } },
            .glass_pane => self.virtual = .{ .glass_pane = .{
                .north = paneShouldConnectTo(world.getBlock(block_pos.north())),
                .south = paneShouldConnectTo(world.getBlock(block_pos.south())),
                .west = paneShouldConnectTo(world.getBlock(block_pos.west())),
                .east = paneShouldConnectTo(world.getBlock(block_pos.east())),
            } },
            .stained_glass_pane => self.virtual = .{ .stained_glass_pane = .{
                .north = paneShouldConnectTo(world.getBlock(block_pos.north())),
                .south = paneShouldConnectTo(world.getBlock(block_pos.south())),
                .west = paneShouldConnectTo(world.getBlock(block_pos.west())),
                .east = paneShouldConnectTo(world.getBlock(block_pos.east())),
            } },

            .cobblestone_wall => self.virtual = .{ .cobblestone_wall = .{
                .up = world.getBlock(block_pos.up()) != .air,
                .north = wallShouldConnectTo(world, block_pos.north()),
                .east = wallShouldConnectTo(world, block_pos.east()),
                .south = wallShouldConnectTo(world, block_pos.south()),
                .west = wallShouldConnectTo(world, block_pos.west()),
            } },

            .tripwire => {
                const suspended = physical.payload(.tripwire).suspended;
                self.virtual = .{ .tripwire = .{
                    .north = tripwireShouldConnectTo(world, block_pos, suspended, .north),
                    .east = tripwireShouldConnectTo(world, block_pos, suspended, .east),
                    .south = tripwireShouldConnectTo(world, block_pos, suspended, .south),
                    .west = tripwireShouldConnectTo(world, block_pos, suspended, .west),
                } };
            },

            inline .oak_stairs,
            .stone_stairs,
            .brick_stairs,
            .stone_brick_stairs,
            .nether_brick_stairs,
            .sandstone_stairs,
            .spruce_stairs,
            .birch_stairs,
            .jungle_stairs,
            .quartz_stairs,
            .acacia_stairs,
            .dark_oak_stairs,
            .red_sandstone_stairs,
            => |block| self.virtual = @unionInit(VirtualProperties, @tagName(block), .{
                .shape = resolveStairShape(world, block_pos),
            }),

            else => {},
        }
        return self;
    }

    pub fn getCollisionHitbox(self: @This()) [3]?Box(f64) {
        const NONE: [3]?Box(f64) = .{ null, null, null };
        return switch (self.block) {
            .sapling,
            .flowing_water,
            .water,
            .flowing_lava,
            .lava,
            .rail,
            .golden_rail,
            .detector_rail,
            .web,
            .tallgrass,
            .double_plant,
            .deadbush,
            .yellow_flower,
            .red_flower,
            .brown_mushroom,
            .red_mushroom,
            .torch,
            .wheat,
            .carrots,
            .potatoes,
            .standing_sign,
            .wall_sign,
            .lever,
            .stone_pressure_plate,
            .wooden_pressure_plate,
            .heavy_weighted_pressure_plate,
            .light_weighted_pressure_plate,
            .redstone_torch,
            .redstone_wire,
            .reeds,
            .vine,
            .tripwire_hook,
            .tripwire,
            .wooden_button,
            .stone_button,
            .unpowered_comparator,
            .powered_comparator,
            .activator_rail,
            .standing_banner,
            .wall_banner,
            => NONE,
            else => self.getRaytraceHitbox(),
        };
    }

    pub fn getRaytraceHitbox(self: @This()) [3]?Box(f64) {
        const cube: Box(f64) = .{
            .min = .{ .x = 0, .y = 0, .z = 0 },
            .max = .{ .x = 1, .y = 1, .z = 1 },
        };
        const none: [3]?Box(f64) = .{ null, null, null };
        const full: [3]?Box(f64) = .{ cube, null, null };
        return switch (self.block) {
            .air => none,
            .stone => full,
            .grass => full,
            .dirt => full,
            .cobblestone => full,
            .planks => full,
            .sapling => .{
                .{
                    .min = .{ .x = 0.1, .y = 0.1, .z = 0.1 },
                    .max = .{ .x = 0.9, .y = 0.8, .z = 0.9 },
                },
                null,
                null,
            },
            .bedrock => full,
            .flowing_water => full, // TODO
            .water => full, // TODO
            .flowing_lava => full, // TODO
            .lava => full, // TODO
            .sand => full,
            .gravel => full,
            .gold_ore => full,
            .iron_ore => full,
            .coal_ore => full,
            .log => full,
            .leaves => full,
            .sponge => full,
            .glass => full,
            .lapis_ore => full,
            .lapis_block => full,
            .dispenser => full,
            .sandstone => full,
            .noteblock => full,
            .bed => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.5625, .z = 1.0 },
                },
                null,
                null,
            },
            .golden_rail => {
                const golden_rail = self.properties.golden_rail;
                return .{
                    .{
                        .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                        .max = .{ .x = 1.0, .y = if (golden_rail.shape == .ascending_east or golden_rail.shape == .ascending_north or golden_rail.shape == .ascending_south or golden_rail.shape == .ascending_west) 0.625 else 0.125, .z = 1.0 },
                    },
                    null,
                    null,
                };
            },
            .detector_rail => {
                const detector_rail = self.properties.detector_rail;
                return .{
                    .{
                        .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                        .max = .{ .x = 1.0, .y = if (detector_rail.shape == .ascending_east or detector_rail.shape == .ascending_north or detector_rail.shape == .ascending_south or detector_rail.shape == .ascending_west) 0.625 else 0.125, .z = 1.0 },
                    },
                    null,
                    null,
                };
            },
            .sticky_piston => {
                const sticky_piston = self.properties.sticky_piston;
                return .{
                    if (sticky_piston.extended) switch (sticky_piston.facing) {
                        .down => .{
                            .min = .{ .x = 0.0, .y = 0.25, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
                        },
                        .up => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 0.75, .z = 1.0 },
                        },
                        .north => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.25 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
                        },
                        .south => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 0.75 },
                        },
                        .west => .{
                            .min = .{ .x = 0.25, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
                        },
                        .east => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 0.75, .y = 1.0, .z = 1.0 },
                        },
                    } else cube,
                    null,
                    null,
                };
            },
            .web => full,
            .tallgrass => .{
                .{
                    .min = .{ .x = 0.1, .y = 0.1, .z = 0.1 },
                    .max = .{ .x = 0.9, .y = 0.8, .z = 0.9 },
                },
                null,
                null,
            },
            .deadbush => .{
                .{
                    .min = .{ .x = 0.1, .y = 0.1, .z = 0.1 },
                    .max = .{ .x = 0.9, .y = 0.8, .z = 0.9 },
                },
                null,
                null,
            },
            .piston => {
                const piston = self.properties.piston;
                return .{
                    if (piston.extended) switch (piston.facing) {
                        .down => .{
                            .min = .{ .x = 0.0, .y = 0.25, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
                        },
                        .up => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 0.75, .z = 1.0 },
                        },
                        .north => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.25 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
                        },
                        .south => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 0.75 },
                        },
                        .west => .{
                            .min = .{ .x = 0.25, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
                        },
                        .east => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 0.75, .y = 1.0, .z = 1.0 },
                        },
                    } else cube,
                    null,
                    null,
                };
            },
            .piston_head => {
                const piston_head = self.properties.piston_head;
                return .{
                    switch (piston_head.facing) {
                        .down => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 0.25, .z = 1.0 },
                        },
                        .up => .{
                            .min = .{ .x = 0.0, .y = 0.75, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
                        },
                        .north => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 0.25 },
                        },
                        .south => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.75 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
                        },
                        .west => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 0.25, .y = 1.0, .z = 1.0 },
                        },
                        .east => .{
                            .min = .{ .x = 0.75, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
                        },
                    },
                    null,
                    null,
                };
            },
            .wool => full,
            .piston_extension => none,
            .yellow_flower => .{
                .{
                    .min = .{ .x = 0.3, .y = 0.0, .z = 0.3 },
                    .max = .{ .x = 0.7, .y = 0.6, .z = 0.7 },
                },
                null,
                null,
            },
            .red_flower => .{
                .{
                    .min = .{ .x = 0.3, .y = 0.0, .z = 0.3 },
                    .max = .{ .x = 0.7, .y = 0.6, .z = 0.7 },
                },
                null,
                null,
            },
            .brown_mushroom => .{
                .{
                    .min = .{ .x = 0.3, .y = 0.0, .z = 0.3 },
                    .max = .{ .x = 0.7, .y = 0.6, .z = 0.7 },
                },
                null,
                null,
            },
            .red_mushroom => .{
                .{
                    .min = .{ .x = 0.3, .y = 0.0, .z = 0.3 },
                    .max = .{ .x = 0.7, .y = 0.6, .z = 0.7 },
                },
                null,
                null,
            },
            .gold_block => full,
            .iron_block => full,
            .double_stone_slab => full,
            .stone_slab => {
                const stone_slab = self.payload(.stone_slab);
                return .{
                    .{
                        .min = .{ .x = 0, .y = if (stone_slab.half == .top) 0.5 else 0.0, .z = 0 },
                        .max = .{ .x = 1, .y = if (stone_slab.half == .top) 1.0 else 0.5, .z = 1 },
                    },
                    null,
                    null,
                };
            },
            .brick_block => full,
            .tnt => full,
            .bookshelf => full,
            .mossy_cobblestone => full,
            .obsidian => full,
            .torch => {
                const torch = self.payload(.torch);
                return .{
                    blk: {
                        const wall_width: f32 = 0.15;
                        const floor_width: f32 = 0.1;
                        if (true) break :blk .{
                            .min = .{ .x = 0.0, .y = 0.2, .z = 0.5 - wall_width },
                            .max = .{ .x = wall_width * 2.0, .y = 0.8, .z = 0.5 + wall_width },
                        };
                        break :blk switch (torch.facing) {
                            .east => .{
                                .min = .{ .x = 0.0, .y = 0.2, .z = 0.5 - wall_width },
                                .max = .{ .x = wall_width * 2.0, .y = 0.8, .z = 0.5 + wall_width },
                            },
                            .west => .{
                                .min = .{ .x = 1.0 - wall_width * 2.0, .y = 0.2, .z = 0.5 - wall_width },
                                .max = .{ .x = 1.0, .y = 0.8, .z = 0.5 + wall_width },
                            },
                            .south => .{
                                .min = .{ .x = 0.5 - wall_width, .y = 0.2, .z = 0.0 },
                                .max = .{ .x = 0.5 + wall_width, .y = 0.8, .z = wall_width * 2.0 },
                            },
                            .north => .{
                                .min = .{ .x = 0.5 - wall_width, .y = 0.2, .z = 1.0 - wall_width * 2.0 },
                                .max = .{ .x = 0.5 + wall_width, .y = 0.8, .z = 1.0 },
                            },
                            .up => .{
                                .min = .{ .x = 0.5 - floor_width, .y = 0.0, .z = 0.5 - floor_width },
                                .max = .{ .x = 0.5 + floor_width, .y = 0.6, .z = 0.5 + floor_width },
                            },
                        };
                    },
                    null,
                    null,
                };
            },

            .fire => none,

            .mob_spawner => full,
            .oak_stairs => {
                const stair = self.payload(.oak_stairs);
                return .{
                    if (stair.half == .top) .{
                        .min = .{ .x = 0.0, .y = 0.5, .z = 0.0 },
                        .max = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
                    } else .{
                        .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                        .max = .{ .x = 1.0, .y = 0.5, .z = 1.0 },
                    },
                    null,
                    null,
                };
            }, // TODO
            .chest => .{
                .{
                    .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 0.9375, .y = 0.875, .z = 0.9375 },
                },
                null,
                null,
            },

            .redstone_wire => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.0625, .z = 1.0 },
                },
                null,
                null,
            },

            .diamond_ore => full,
            .diamond_block => full,
            .crafting_table => full,
            .wheat => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.25, .z = 1.0 },
                },
                null,
                null,
            },
            .farmland => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.9375, .z = 1.0 },
                },
                null,
                null,
            },
            .furnace => full,
            .lit_furnace => full,
            .standing_sign => .{
                .{
                    .min = .{ .x = 0.25, .y = 0.0, .z = 0.25 },
                    .max = .{ .x = 0.75, .y = 1.0, .z = 0.75 },
                },
                null,
                null,
            },
            .wooden_door => full, // TODO
            .ladder => {
                const ladder = self.payload(.ladder);
                return .{
                    switch (ladder.facing) {
                        .north => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.875 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
                        },
                        .south => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 0.125 },
                        },
                        .west => .{
                            .min = .{ .x = 0.875, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
                        },
                        .east => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 0.125, .y = 1.0, .z = 1.0 },
                        },
                    },
                    null,
                    null,
                };
            },
            .rail => {
                const rail = self.payload(.rail);
                return .{
                    .{
                        .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                        .max = .{ .x = 1.0, .y = if (rail.shape == .ascending_east or rail.shape == .ascending_north or rail.shape == .ascending_south or rail.shape == .ascending_west) 0.625 else 0.125, .z = 1.0 },
                    },
                    null,
                    null,
                };
            },
            .stone_stairs => full, // TODO
            .wall_sign => {
                const wall_sign = self.payload(.wall_sign);
                return .{
                    switch (wall_sign.facing) {
                        .north => .{
                            .min = .{ .x = 0.0, .y = 0.28125, .z = 0.875 },
                            .max = .{ .x = 1.0, .y = 0.78125, .z = 1.0 },
                        },
                        .south => .{
                            .min = .{ .x = 0.0, .y = 0.28125, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 0.78125, .z = 0.125 },
                        },
                        .west => .{
                            .min = .{ .x = 0.875, .y = 0.28125, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 0.78125, .z = 1.0 },
                        },
                        .east => .{
                            .min = .{ .x = 0.0, .y = 0.28125, .z = 0.0 },
                            .max = .{ .x = 0.125, .y = 0.78125, .z = 1.0 },
                        },
                    },
                    null,
                    null,
                };
            },
            .lever => {
                const lever = self.payload(.lever);
                return .{
                    switch (lever.facing) {
                        .east => .{
                            .min = .{ .x = 0.0, .y = 0.2, .z = 0.3125 },
                            .max = .{ .x = 0.375, .y = 0.8, .z = 0.6875 },
                        },
                        .west => .{
                            .min = .{ .x = 0.625, .y = 0.2, .z = 0.3125 },
                            .max = .{ .x = 1.0, .y = 0.8, .z = 0.6875 },
                        },
                        .south => .{
                            .min = .{ .x = 0.3125, .y = 0.2, .z = 0.0 },
                            .max = .{ .x = 0.6875, .y = 0.8, .z = 0.375 },
                        },
                        .north => .{
                            .min = .{ .x = 0.3125, .y = 0.2, .z = 0.625 },
                            .max = .{ .x = 0.6875, .y = 0.8, .z = 1.0 },
                        },
                        .up_z, .up_x => .{
                            .min = .{ .x = 0.25, .y = 0.0, .z = 0.25 },
                            .max = .{ .x = 0.75, .y = 0.6, .z = 0.75 },
                        },
                        .down_x, .down_z => .{
                            .min = .{ .x = 0.25, .y = 0.4, .z = 0.25 },
                            .max = .{ .x = 0.75, .y = 1.0, .z = 0.75 },
                        },
                    },
                    null,
                    null,
                };
            },
            .stone_pressure_plate => {
                const stone_pressure_plate = self.payload(.stone_pressure_plate);
                return .{
                    .{
                        .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                        .max = .{ .x = 0.9375, .y = if (stone_pressure_plate.powered) 0.03125 else 0.0625, .z = 0.9375 },
                    },
                    null,
                    null,
                };
            },
            .iron_door => full, // TODO
            .wooden_pressure_plate => {
                const wooden_pressure_plate = self.payload(.wooden_pressure_plate);
                return .{
                    .{
                        .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                        .max = .{ .x = 0.9375, .y = if (wooden_pressure_plate.powered) 0.03125 else 0.0625, .z = 0.9375 },
                    },
                    null,
                    null,
                };
            },
            .redstone_ore => full,
            .lit_redstone_ore => full,
            .unlit_redstone_torch => {
                const unlit_redstone_torch = self.payload(.unlit_redstone_torch);
                return .{
                    blk: {
                        const wall_width: f32 = 0.15;
                        const floor_width: f32 = 0.1;
                        if (true) break :blk .{
                            .min = .{ .x = 0.0, .y = 0.2, .z = 0.5 - wall_width },
                            .max = .{ .x = wall_width * 2.0, .y = 0.8, .z = 0.5 + wall_width },
                        };
                        break :blk switch (unlit_redstone_torch.facing) {
                            .east => .{
                                .min = .{ .x = 0.0, .y = 0.2, .z = 0.5 - wall_width },
                                .max = .{ .x = wall_width * 2.0, .y = 0.8, .z = 0.5 + wall_width },
                            },
                            .west => .{
                                .min = .{ .x = 1.0 - wall_width * 2.0, .y = 0.2, .z = 0.5 - wall_width },
                                .max = .{ .x = 1.0, .y = 0.8, .z = 0.5 + wall_width },
                            },
                            .south => .{
                                .min = .{ .x = 0.5 - wall_width, .y = 0.2, .z = 0.0 },
                                .max = .{ .x = 0.5 + wall_width, .y = 0.8, .z = wall_width * 2.0 },
                            },
                            .north => .{
                                .min = .{ .x = 0.5 - wall_width, .y = 0.2, .z = 1.0 - wall_width * 2.0 },
                                .max = .{ .x = 0.5 + wall_width, .y = 0.8, .z = 1.0 },
                            },
                            .up => .{
                                .min = .{ .x = 0.5 - floor_width, .y = 0.0, .z = 0.5 - floor_width },
                                .max = .{ .x = 0.5 + floor_width, .y = 0.6, .z = 0.5 + floor_width },
                            },
                        };
                    },
                    null,
                    null,
                };
            },
            .redstone_torch => {
                const redstone_torch = self.payload(.redstone_torch);
                return .{
                    blk: {
                        const wall_width: f32 = 0.15;
                        const floor_width: f32 = 0.1;
                        break :blk switch (redstone_torch.facing) {
                            .east => .{
                                .min = .{ .x = 0.0, .y = 0.2, .z = 0.5 - wall_width },
                                .max = .{ .x = wall_width * 2.0, .y = 0.8, .z = 0.5 + wall_width },
                            },
                            .west => .{
                                .min = .{ .x = 1.0 - wall_width * 2.0, .y = 0.2, .z = 0.5 - wall_width },
                                .max = .{ .x = 1.0, .y = 0.8, .z = 0.5 + wall_width },
                            },
                            .south => .{
                                .min = .{ .x = 0.5 - wall_width, .y = 0.2, .z = 0.0 },
                                .max = .{ .x = 0.5 + wall_width, .y = 0.8, .z = wall_width * 2.0 },
                            },
                            .north => .{
                                .min = .{ .x = 0.5 - wall_width, .y = 0.2, .z = 1.0 - wall_width * 2.0 },
                                .max = .{ .x = 0.5 + wall_width, .y = 0.8, .z = 1.0 },
                            },
                            .up => .{
                                .min = .{ .x = 0.5 - floor_width, .y = 0.0, .z = 0.5 - floor_width },
                                .max = .{ .x = 0.5 + floor_width, .y = 0.6, .z = 0.5 + floor_width },
                            },
                        };
                    },
                    null,
                    null,
                };
            },
            .stone_button => {
                const stone_button = self.payload(.stone_button);
                return .{
                    blk: {
                        const button_depth = (if (stone_button.powered) @as(f32, 1.0) else @as(f32, 2.0)) / 16.0;
                        break :blk switch (stone_button.facing) {
                            .east => .{
                                .min = .{ .x = 0.0, .y = 0.375, .z = 0.3125 },
                                .max = .{ .x = button_depth, .y = 0.625, .z = 0.6875 },
                            },
                            .west => .{
                                .min = .{ .x = 1.0 - button_depth, .y = 0.375, .z = 0.3125 },
                                .max = .{ .x = 1.0, .y = 0.625, .z = 0.6875 },
                            },
                            .south => .{
                                .min = .{ .x = 0.3125, .y = 0.375, .z = 0.0 },
                                .max = .{ .x = 0.6875, .y = 0.625, .z = button_depth },
                            },
                            .north => .{
                                .min = .{ .x = 0.3125, .y = 0.375, .z = 1.0 - button_depth },
                                .max = .{ .x = 0.6875, .y = 0.625, .z = 1.0 },
                            },
                            .up => .{
                                .min = .{ .x = 0.3125, .y = 0.0, .z = 0.375 },
                                .max = .{ .x = 0.6875, .y = button_depth, .z = 0.625 },
                            },
                            .down => .{
                                .min = .{ .x = 0.3125, .y = 1.0 - button_depth, .z = 0.375 },
                                .max = .{ .x = 0.6875, .y = 1.0, .z = 0.625 },
                            },
                        };
                    },
                    null,
                    null,
                };
            },
            .snow_layer => {
                const snow_layer = self.payload(.snow_layer);
                return .{
                    .{
                        .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                        .max = .{ .x = 1.0, .y = @as(f32, @floatFromInt(@as(u4, snow_layer.layers) + 1)) / 8.0, .z = 1.0 },
                    },
                    null,
                    null,
                };
            },
            .ice => full,
            .snow => full,
            .cactus => full,
            .clay => full,
            .reeds => .{
                .{
                    .min = .{ .x = 0.125, .y = 0.0, .z = 0.125 },
                    .max = .{ .x = 0.875, .y = 1.0, .z = 0.875 },
                },
                null,
                null,
            },
            .jukebox => full,
            .fence,
            .nether_brick_fence,
            .spruce_fence,
            .birch_fence,
            .jungle_fence,
            .dark_oak_fence,
            .acacia_fence,
            => .{
                .{
                    .min = .{ .x = 0.375, .y = 0.0, .z = 0.375 },
                    .max = .{ .x = 0.625, .y = 1.0, .z = 0.625 },
                },
                null,
                null,
            },
            .pumpkin => full,
            .netherrack => full,
            .soul_sand => full,
            .glowstone => full,
            .portal => {
                const portal = self.payload(.portal);
                return .{
                    switch (portal.axis) {
                        .x => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.375 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 0.625 },
                        },
                        .z => .{
                            .min = .{ .x = 0.375, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 0.625, .y = 1.0, .z = 1.0 },
                        },
                    },
                    null,
                    null,
                };
            },
            .lit_pumpkin => full,
            .cake => {
                const cake = self.payload(.cake);
                return .{
                    .{
                        .min = .{ .x = @as(f32, @floatFromInt(cake.bites * 2 + 1)) / 16.0, .y = 0.0, .z = 0.0625 },
                        .max = .{ .x = 0.9375, .y = 1.0, .z = 0.9375 },
                    },
                    null,
                    null,
                };
            },
            .unpowered_repeater => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.125, .z = 1.0 },
                },
                null,
                null,
            },
            .powered_repeater => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.125, .z = 1.0 },
                },
                null,
                null,
            },
            .stained_glass => full,
            .trapdoor => full, // TODO
            .monster_egg => full,
            .stonebrick => full,
            .brown_mushroom_block => full,
            .red_mushroom_block => full,
            .iron_bars => full,
            .glass_pane => full,
            .melon_block => full,
            .pumpkin_stem => {
                const pumpkin_stem = self.payload(.pumpkin_stem);
                return .{
                    .{
                        .min = .{ .x = 0.375, .y = 0.0, .z = 0.375 },
                        .max = .{ .x = 0.625, .y = @as(f32, @floatFromInt(pumpkin_stem.age * 2 + 2)) / 16.0, .z = 0.625 },
                    },
                    null,
                    null,
                };
            },
            .melon_stem => {
                const melon_stem = self.payload(.melon_stem);
                return .{
                    .{
                        .min = .{ .x = 0.375, .y = 0.0, .z = 0.375 },
                        .max = .{ .x = 0.625, .y = @as(f32, @floatFromInt(melon_stem.age * 2 + 2)) / 16.0, .z = 0.625 },
                    },
                    null,
                    null,
                };
            },
            .vine => full, // TODO
            .fence_gate => {
                const fence_gate = self.payload(.fence_gate);
                return .{
                    switch (fence_gate.facing) {
                        .north, .south => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.375 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 0.625 },
                        },
                        .west, .east => .{
                            .min = .{ .x = 0.375, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 0.625, .y = 1.0, .z = 1.0 },
                        },
                    },
                    null,
                    null,
                };
            },
            .brick_stairs => full, // TODO
            .stone_brick_stairs => full, // TODO
            .mycelium => full,
            .waterlily => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.375 },
                    .max = .{ .x = 1.0, .y = 0.015625, .z = 0.625 },
                },
                null,
                null,
            },
            .nether_brick => full,
            // .nether_brick_fence,
            .nether_brick_stairs => full, // TODO
            .nether_wart => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.375 },
                    .max = .{ .x = 1.0, .y = 0.25, .z = 0.625 },
                },
                null,
                null,
            },
            .enchanting_table => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.375 },
                    .max = .{ .x = 1.0, .y = 0.75, .z = 0.625 },
                },
                null,
                null,
            },
            .brewing_stand => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.375 },
                    .max = .{ .x = 1.0, .y = 0.125, .z = 0.625 },
                },
                null,
                null,
            },
            .cauldron => full,
            .end_portal => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.0625, .z = 1.0 },
                },
                null,
                null,
            },
            .end_portal_frame => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.8125, .z = 0.0 },
                },
                null,
                null,
            },
            .end_stone => full,
            .dragon_egg => .{
                .{
                    .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                    .max = .{ .x = 0.9375, .y = 1.0, .z = 0.9375 },
                },
                null,
                null,
            },
            .redstone_lamp => full,
            .lit_redstone_lamp => full,
            .double_wooden_slab => full,
            .wooden_slab => {
                const wooden_slab = self.payload(.wooden_slab);
                return .{
                    .{
                        .min = .{ .x = 0, .y = if (wooden_slab.half == .top) 0.5 else 0.0, .z = 0 },
                        .max = .{ .x = 1, .y = if (wooden_slab.half == .top) 1.0 else 0.5, .z = 1 },
                    },
                    null,
                    null,
                };
            },
            .cocoa => {
                const cocoa = self.payload(.cocoa);
                return .{
                    blk: {
                        const width = @as(f32, @floatFromInt(4 + @as(u8, @intCast(cocoa.age)) * 2));
                        const height = @as(f32, @floatFromInt(5 + @as(u8, @intCast(cocoa.age)) * 2));
                        break :blk switch (cocoa.facing) {
                            .south => .{
                                .min = .{
                                    .x = (8.0 - width / 2.0) / 16.0,
                                    .y = (12.0 - height) / 16.0,
                                    .z = (15.0 - width) / 16.0,
                                },
                                .max = .{
                                    .x = (8.0 + width / 2.0) / 16.0,
                                    .y = 0.75,
                                    .z = 0.9375,
                                },
                            },
                            .north => .{
                                .min = .{
                                    .x = (8.0 - width / 2.0) / 16.0,
                                    .y = (12.0 - height) / 16.0,
                                    .z = 0.0625,
                                },
                                .max = .{
                                    .x = (8.0 + width / 2.0) / 16.0,
                                    .y = 0.75,
                                    .z = (1.0 + width) / 16.0,
                                },
                            },
                            .west => .{
                                .min = .{
                                    .x = 0.0625,
                                    .y = (12.0 - height) / 16.0,
                                    .z = (8.0 - width / 2.0) / 16.0,
                                },
                                .max = .{
                                    .x = (1.0 + width) / 16.0,
                                    .y = 0.75,
                                    .z = (8.0 + width / 2.0) / 16.0,
                                },
                            },
                            .east => .{
                                .min = .{
                                    .x = (15.0 - width) / 16.0,
                                    .y = (12.0 - height) / 16.0,
                                    .z = (8.0 - width / 2.0) / 16.0,
                                },
                                .max = .{
                                    .x = 0.9375,
                                    .y = 0.75,
                                    .z = (8.0 + width / 2.0) / 16.0,
                                },
                            },
                        };
                    },
                    null,
                    null,
                };
            },
            .sandstone_stairs => full, // TODO
            .emerald_ore => full,
            .ender_chest => .{
                .{
                    .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                    .max = .{ .x = 0.9375, .y = 0.875, .z = 0.9375 },
                },
                null,
                null,
            },
            .tripwire_hook => {
                const tripwire_hook = self.payload(.tripwire_hook);
                return .{
                    switch (tripwire_hook.facing) {
                        .east => .{
                            .min = .{ .x = 0.0, .y = 0.2, .z = 0.3125 },
                            .max = .{ .x = 0.375, .y = 0.8, .z = 0.6875 },
                        },
                        .west => .{
                            .min = .{ .x = 0.625, .y = 0.2, .z = 0.3125 },
                            .max = .{ .x = 1.0, .y = 0.8, .z = 0.6875 },
                        },
                        .south => .{
                            .min = .{ .x = 0.3125, .y = 0.2, .z = 0.0 },
                            .max = .{ .x = 0.6875, .y = 0.8, .z = 0.375 },
                        },
                        .north => .{
                            .min = .{ .x = 0.3125, .y = 0.2, .z = 0.625 },
                            .max = .{ .x = 0.6875, .y = 0.8, .z = 1.0 },
                        },
                    },
                    null,
                    null,
                };
            },
            .tripwire => {
                const tripwire = self.payload(.tripwire);
                return .{
                    if (!tripwire.suspended)
                        .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 0.09375, .z = 1.0 },
                        }
                    else if (!tripwire.attached)
                        .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 0.5, .z = 1.0 },
                        }
                    else
                        .{
                            .min = .{ .x = 0.0, .y = 0.0625, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 0.15625, .z = 1.0 },
                        },
                    null,
                    null,
                };
            },
            .emerald_block => full,
            .spruce_stairs => full, // TODO
            .birch_stairs => full, // TODO
            .jungle_stairs => full, // TODO
            .command_block => full,
            .beacon => full,
            .cobblestone_wall => full, // TODO
            .flower_pot => .{
                .{
                    .min = .{ .x = 0.3125, .y = 0.0, .z = 0.3125 },
                    .max = .{ .x = 0.6875, .y = 0.375, .z = 0.6875 },
                },
                null,
                null,
            },
            .carrots => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.25, .z = 1.0 },
                },
                null,
                null,
            },
            .potatoes => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.25, .z = 1.0 },
                },
                null,
                null,
            },
            .wooden_button => {
                const wooden_button = self.payload(.wooden_button);
                return .{
                    blk: {
                        if (true) break :blk .{
                            .min = .{ .x = 0.0, .y = 0.375, .z = 0.3125 },
                            .max = .{ .x = 1.0 / 16.0, .y = 0.625, .z = 0.6875 },
                        };
                        const button_depth = (if (wooden_button.powered) @as(f32, 1.0) else @as(f32, 2.0)) / 16.0;
                        break :blk switch (wooden_button.facing) {
                            .east => .{
                                .min = .{ .x = 0.0, .y = 0.375, .z = 0.3125 },
                                .max = .{ .x = button_depth, .y = 0.625, .z = 0.6875 },
                            },
                            .west => .{
                                .min = .{ .x = 1.0 - button_depth, .y = 0.375, .z = 0.3125 },
                                .max = .{ .x = 1.0, .y = 0.625, .z = 0.6875 },
                            },
                            .south => .{
                                .min = .{ .x = 0.3125, .y = 0.375, .z = 0.0 },
                                .max = .{ .x = 0.6875, .y = 0.625, .z = button_depth },
                            },
                            .north => .{
                                .min = .{ .x = 0.3125, .y = 0.375, .z = 1.0 - button_depth },
                                .max = .{ .x = 0.6875, .y = 0.625, .z = 1.0 },
                            },
                            .up => .{
                                .min = .{ .x = 0.3125, .y = 0.0, .z = 0.375 },
                                .max = .{ .x = 0.6875, .y = button_depth, .z = 0.625 },
                            },
                            .down => .{
                                .min = .{ .x = 0.3125, .y = 1.0 - button_depth, .z = 0.375 },
                                .max = .{ .x = 0.6875, .y = 1.0, .z = 0.625 },
                            },
                        };
                    },
                    null,
                    null,
                };
            },
            .skull => {
                const skull = self.payload(.skull);
                return .{
                    switch (skull.facing) {
                        .north => .{
                            .min = .{ .x = 0.25, .y = 0.25, .z = 0.5 },
                            .max = .{ .x = 0.75, .y = 0.75, .z = 1.0 },
                        },
                        .south => .{
                            .min = .{ .x = 0.25, .y = 0.25, .z = 0.0 },
                            .max = .{ .x = 0.75, .y = 0.75, .z = 0.5 },
                        },
                        .west => .{
                            .min = .{ .x = 0.5, .y = 0.25, .z = 0.25 },
                            .max = .{ .x = 1.0, .y = 0.75, .z = 0.75 },
                        },
                        .east => .{
                            .min = .{ .x = 0.0, .y = 0.25, .z = 0.25 },
                            .max = .{ .x = 0.5, .y = 0.75, .z = 0.75 },
                        },
                        else => .{
                            .min = .{ .x = 0.25, .y = 0.0, .z = 0.25 },
                            .max = .{ .x = 0.5, .y = 0.5, .z = 0.75 },
                        },
                    },
                    null,
                    null,
                };
            },
            .anvil => {
                const anvil = self.payload(.anvil);
                return .{
                    switch (anvil.facing) {
                        .west, .east => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.125 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 0.875 },
                        },
                        .north, .south => .{
                            .min = .{ .x = 0.125, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 0.875, .y = 1.0, .z = 1.0 },
                        },
                    },
                    null,
                    null,
                };
            },
            .trapped_chest => .{
                .{
                    .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 0.9375, .y = 0.875, .z = 0.9375 },
                },
                null,
                null,
            },
            .light_weighted_pressure_plate => {
                const light_weighted_pressure_plate = self.payload(.light_weighted_pressure_plate);
                return .{
                    .{
                        .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                        .max = .{ .x = 0.9375, .y = if (light_weighted_pressure_plate.power > 0) 0.03125 else 0.0625, .z = 0.9375 },
                    },
                    null,
                    null,
                };
            },
            .heavy_weighted_pressure_plate => {
                const heavy_weighted_pressure_plate = self.payload(.heavy_weighted_pressure_plate);
                return .{
                    .{
                        .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                        .max = .{ .x = 0.9375, .y = if (heavy_weighted_pressure_plate.power > 0) 0.03125 else 0.0625, .z = 0.9375 },
                    },
                    null,
                    null,
                };
            },
            .unpowered_comparator => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.125, .z = 1.0 },
                },
                null,
                null,
            },
            .powered_comparator => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.125, .z = 1.0 },
                },
                null,
                null,
            },
            .daylight_detector => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.375, .z = 1.0 },
                },
                null,
                null,
            },
            .redstone_block => full,
            .quartz_ore => full,
            .hopper => full,
            .quartz_block => full,
            .quartz_stairs => full, // TODO
            .activator_rail => {
                const activator_rail = self.payload(.activator_rail);
                return .{
                    .{
                        .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                        .max = .{ .x = 1.0, .y = if (activator_rail.shape == .ascending_east or activator_rail.shape == .ascending_north or activator_rail.shape == .ascending_south or activator_rail.shape == .ascending_west) 0.625 else 0.125, .z = 1.0 },
                    },
                    null,
                    null,
                };
            },
            .dropper => full,
            .stained_hardened_clay => full,
            .stained_glass_pane => full,
            .leaves2 => full,
            .log2 => full,
            .acacia_stairs => full, // TODO
            .dark_oak_stairs => full, // TODO
            .slime => full,
            .barrier => full,
            .iron_trapdoor => full, // TODO
            .prismarine => full,
            .sea_lantern => full,
            .hay_block => full,
            .carpet => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.0625, .z = 1.0 },
                },
                null,
                null,
            },
            .hardened_clay => full,
            .coal_block => full,
            .packed_ice => full,
            .double_plant => full,
            .standing_banner => .{
                .{
                    .min = .{ .x = 0.25, .y = 0.0, .z = 0.25 },
                    .max = .{ .x = 0.75, .y = 1.0, .z = 0.75 },
                },
                null,
                null,
            },
            .wall_banner => {
                const wall_banner = self.payload(.wall_banner);
                return .{
                    switch (wall_banner.facing) {
                        .north => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.875 },
                            .max = .{ .x = 1.0, .y = 0.78125, .z = 1.0 },
                        },
                        .south => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 0.78125, .z = 0.125 },
                        },
                        .west => .{
                            .min = .{ .x = 0.875, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 0.78125, .z = 1.0 },
                        },
                        .east => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 0.125, .y = 0.78125, .z = 1.0 },
                        },
                    },
                    null,
                    null,
                };
            },
            .daylight_detector_inverted => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.1 },
                    .max = .{ .x = 1.0, .y = 0.375, .z = 1.0 },
                },
                null,
                null,
            },
            .red_sandstone => full,
            .red_sandstone_stairs => full, // TODO
            .double_stone_slab2 => full,
            .stone_slab2 => {
                const stone_slab2 = self.payload(.stone_slab2);
                return .{
                    .{
                        .min = .{ .x = 0, .y = if (stone_slab2.half == .top) 0.5 else 0.0, .z = 0 },
                        .max = .{ .x = 1, .y = if (stone_slab2.half == .top) 1.0 else 0.5, .z = 1 },
                    },
                    null,
                    null,
                };
            },
            .spruce_fence_gate => {
                const spruce_fence_gate = self.payload(.spruce_fence_gate);
                return .{
                    switch (spruce_fence_gate.facing) {
                        .north, .south => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.375 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 0.625 },
                        },
                        .west, .east => .{
                            .min = .{ .x = 0.375, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 0.625, .y = 1.0, .z = 1.0 },
                        },
                    },
                    null,
                    null,
                };
            },
            .birch_fence_gate => {
                const birch_fence_gate = self.payload(.birch_fence_gate);
                return .{
                    switch (birch_fence_gate.facing) {
                        .north, .south => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.375 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 0.625 },
                        },
                        .west, .east => .{
                            .min = .{ .x = 0.375, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 0.625, .y = 1.0, .z = 1.0 },
                        },
                    },
                    null,
                    null,
                };
            },
            .jungle_fence_gate => {
                const jungle_fence_gate = self.payload(.jungle_fence_gate);
                return .{
                    switch (jungle_fence_gate.facing) {
                        .north, .south => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.375 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 0.625 },
                        },
                        .west, .east => .{
                            .min = .{ .x = 0.375, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 0.625, .y = 1.0, .z = 1.0 },
                        },
                    },
                    null,
                    null,
                };
            },
            .dark_oak_fence_gate => {
                const dark_oak_fence_gate = self.payload(.dark_oak_fence_gate);
                return .{
                    switch (dark_oak_fence_gate.facing) {
                        .north, .south => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.375 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 0.625 },
                        },
                        .west, .east => .{
                            .min = .{ .x = 0.375, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 0.625, .y = 1.0, .z = 1.0 },
                        },
                    },
                    null,
                    null,
                };
            },
            .acacia_fence_gate => {
                const acacia_fence_gate = self.payload(.acacia_fence_gate);
                return .{
                    switch (acacia_fence_gate.facing) {
                        .north, .south => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.375 },
                            .max = .{ .x = 1.0, .y = 1.0, .z = 0.625 },
                        },
                        .west, .east => .{
                            .min = .{ .x = 0.375, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 0.625, .y = 1.0, .z = 1.0 },
                        },
                    },
                    null,
                    null,
                };
            },
            // .spruce_fence,
            // .birch_fence,
            // .jungle_fence,
            // .dark_oak_fence,
            // .acacia_fence,
            .spruce_door => full, // TODO
            .birch_door => full, // TODO
            .jungle_door => full, // TODO
            .acacia_door => full, // TODO
            .dark_oak_door => full, // TODO
        };
    }
};

const physical_properties = @import("physical_properties.zig");

pub const PhysicalProperties = physical_properties.PhysicalProperties;

pub const StairFacing = physical_properties.StairFacing;
pub const Facing = physical_properties.Facing;
pub const HorizontalFacing = physical_properties.HorizontalFacing;
pub const PackedHorizontalFacing = physical_properties.PackedHorizontalFacing;
pub const TorchFacing = physical_properties.TorchFacing;
pub const ButtonFacing = physical_properties.ButtonFacing;
pub const LeverFacing = physical_properties.LeverFacing;
pub const HopperFacing = physical_properties.HopperFacing;
pub const WoodVariant = physical_properties.WoodVariant;
pub const WoodVariant1 = physical_properties.WoodVariant1;
pub const WoodVariant2 = physical_properties.WoodVariant2;
pub const RepeaterDelay = physical_properties.RepeaterDelay;
pub const LogAxis = physical_properties.LogAxis;
pub const Half = physical_properties.Half;
pub const StoneVariant = physical_properties.StoneVariant;
pub const DirtVariant = physical_properties.DirtVariant;
pub const SandVariant = physical_properties.SandVariant;
pub const SandstoneVariant = physical_properties.SandstoneVariant;
pub const RedSandstoneVariant = physical_properties.RedSandstoneVariant;
pub const StraightRailShape = physical_properties.StraightRailShape;
pub const Color = physical_properties.Color;
pub const NetherWartAge = physical_properties.NetherWartAge;
pub const CurveableRailShape = physical_properties.CurveableRailShape;
pub const QuartzBlockVariant = physical_properties.QuartzBlockVariant;
pub const DoorHalf = physical_properties.DoorHalf;
pub const BedPart = physical_properties.BedPart;
pub const TallGrassVariant = physical_properties.TallGrassVariant;
pub const RedFlowerVariant = physical_properties.RedFlowerVariant;
pub const StoneSlabVariant = physical_properties.StoneSlabVariant;
pub const MonsterEggVariant = physical_properties.MonsterEggVariant;
pub const PortalAxis = physical_properties.PortalAxis;
pub const StoneBrickVariant = physical_properties.StoneBrickVariant;
pub const MushroomBlockVariant = physical_properties.MushroomBlockVariant;
pub const CobblestoneWallVariant = physical_properties.CobblestoneWallVariant;
pub const PrismarineVariant = physical_properties.PrismarineVariant;
pub const HayBlockAxis = physical_properties.HayBlockAxis;
pub const DoublePlantVariant = physical_properties.DoublePlantVariant;
pub const DoublePlantHalf = physical_properties.DoublePlantHalf;
