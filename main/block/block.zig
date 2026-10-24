// Before 1.13, each block in a chunk is stored in 16 bits:
// <id: 12 bits>|<metadata: 4 bits>
// The id denotes the specific type of the block (such as dirt, water, torches,
// packed ice, etc.) Generally, metadata denotes the transient state of the block
// - e.g. for levers, powered vs unpowered and what face it is attached to.
// However, for other blocks like stone, it acts like a second block id, since
// andesite, diorite, granite, and their polished variants are all just metadata
// variants of the same block type (stone). Other blocks like this include wool,
// leaves, and wooden fences.
// As if this system wasn't bad enough, you may notice that some blocks should
// actually require more than 4 bits to store their block state! For example,
// redstone dust stores power level (0-15), then for each cardinal direction,
// whether there is a flat, rising, or no connection. That's 16*3*3*3*3, or
// 1296 states, which obviously can't fit within 4 bits.
// What actually happens is that the game just recomputes them on demand based
// on the neighboring blocks.
// (See vanilla's Block.resolveVirtualProperties. Note that it is only called for
// rendering and in the client debug overlay, but identical logic is used throughout
// for other tasks like getting collisions.)
// For an especially unhinged (pun intended) example: Doors have facing (n/e/s/w),
// open (bool), hinge (left/right), powered (bool), and half (upper/lower). `Half`
// is always a stored property, but only the lower half stores facing and open, and
// only the upper half stores hinge and powered. So each half has to look at the
// other to retrieve the state it doesn't have.

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

    pub const Material = material.Material;
    pub const VirtualState = @import("virtual_state.zig").VirtualState;
    pub const PhysicalState = @import("physical_state.zig").PhysicalState;

    pub fn getFriction(self: @This()) f32 {
        return switch (self) {
            .slime => 0.8,
            .ice, .packed_ice => 0.98,
            else => 0.6,
        };
    }

    pub fn isStair(self: @This()) bool {
        return attributes.is_stair.contains(self);
    }

    pub fn isSingleSlab(self: @This()) bool {
        return attributes.is_single_slab.contains(self);
    }

    pub fn isDoubleSlab(self: @This()) bool {
        return attributes.is_double_slab.contains(self);
    }

    pub fn isSlab(self: @This()) bool {
        return self.isSingleSlab() or self.isDoubleSlab();
    }

    pub fn isFence(self: @This()) bool {
        return attributes.is_fence.contains(self);
    }

    pub fn isFenceGate(self: @This()) bool {
        return attributes.is_fence_gate.contains(self);
    }

    pub fn isPlant(self: @This()) bool {
        return attributes.is_plant.contains(self);
    }

    pub fn isCube(self: @This()) bool {
        return attributes.is_cube.contains(self);
    }

    pub fn blocksAmbientLight(self: @This()) bool {
        return self.getMaterial().blocksMovement() and self.isCube();
    }

    pub fn isSignalSource(self: @This()) bool {
        return attributes.signal_source.contains(self);
    }

    pub fn isSolid(self: @This()) bool {
        return self.getMaterial().blocksMovementAndNotTranslucent() and self.isCube() and !self.isSignalSource();
    }

    pub fn getHardness(self: @This()) f32 {
        return attributes.hardness.get(self);
    }

    pub fn getMaterial(self: @This()) Material {
        return material.block_to_material.get(self);
    }

    // TODO: implement
    pub fn isSolidRender(self: @This()) bool {
        _ = self;
        return false;
    }

    pub fn isOpaque(self: @This()) bool {
        return self.isSolidRender();
    }

    pub fn canBePlaced(self: @This(), world: *const World, pos: Vector3(i32), dir: Direction) bool {
        const replaceable = world.getBlock(pos).getMaterial().isReplaceable();

        return switch (self) {
            // no item form
            inline .air,
            .fire,
            .flowing_lava,
            .flowing_water,
            .lava,
            .piston_extension,
            .piston_head,
            .portal,
            .powered_comparator,
            .powered_repeater,
            .unlit_redstone_torch,
            .water,
            => |block| {
                @setEvalBranchQuota(10_000);
                comptime std.debug.assert(std.enums.fromInt(main.Item, @backingInt(block)) == null);
                unreachable;
            },

            // items that produce these never call canBePlaced
            .bed,
            .wall_banner,
            => unreachable,

            .stone_pressure_plate,
            .wooden_pressure_plate,
            .light_weighted_pressure_plate,
            .heavy_weighted_pressure_plate,
            => {
                const below = world.getBlockState(pos.down());
                return below.hasSolidTop() or below.block.isFence();
            },

            .golden_rail,
            .rail,
            .detector_rail,
            .activator_rail,
            => world.getBlockState(pos.down()).hasSolidTop(),

            .standing_sign,
            .wall_sign,
            .standing_banner,
            => {
                if (!replaceable) return false;
                for (Direction.horizontals) |side| if (world.getBlock(pos.dir(side)) == .cactus) return false;
                return true;
            },

            .unpowered_repeater,
            .unpowered_comparator,
            .flower_pot,
            => replaceable and world.getBlockState(pos.down()).hasSolidTop(),

            .redstone_wire => replaceable and (world.getBlockState(pos.down()).hasSolidTop() or world.getBlock(pos.down()) == .glowstone),

            .fence_gate,
            .spruce_fence_gate,
            .birch_fence_gate,
            .jungle_fence_gate,
            .acacia_fence_gate,
            .dark_oak_fence_gate,
            .cake,
            => replaceable and world.getBlock(pos.down()).getMaterial().isSolid(),

            .cactus => {
                if (!replaceable) return false;
                for (Direction.horizontals) |side| if (world.getBlock(pos.dir(side)).getMaterial().isSolid()) return false;
                const below = world.getBlock(pos.down());
                return below == .cactus or below == .sand;
            },

            .carpet,
            => replaceable and world.getBlock(pos.down()) != .air,

            .pumpkin, .lit_pumpkin => replaceable and world.getBlockState(pos.down()).hasSolidTop(),

            .red_flower, .yellow_flower, .sapling, .tallgrass => replaceable and switch (world.getBlock(pos.down())) {
                .grass, .dirt, .farmland => true,
                else => false,
            },
            .deadbush => replaceable and switch (world.getBlock(pos.down())) {
                .sand, .hardened_clay, .stained_hardened_clay, .dirt => true,
                else => false,
            },
            .waterlily => replaceable and world.getBlock(pos.down()) == .water,

            .double_plant => replaceable and world.getBlock(pos.up()) == .air and switch (world.getBlock(pos.down())) {
                .grass, .dirt, .farmland => true,
                else => false,
            },

            .wheat, .carrots, .potatoes, .pumpkin_stem, .melon_stem => replaceable and world.getBlock(pos.down()) == .farmland,

            .nether_wart => replaceable and world.getBlock(pos.down()) == .soul_sand,

            // TODO: Light level, podzol, mycelium, etc. etc.
            .brown_mushroom, .red_mushroom => replaceable and world.getBlock(pos.down()).getMaterial().isOpaque(),

            .wooden_door, .iron_door, .spruce_door, .birch_door, .jungle_door, .acacia_door, .dark_oak_door => replaceable and
                pos.y < 255 and
                world.getBlockState(pos.down()).hasSolidTop() and
                world.getBlock(pos.up()).getMaterial().isReplaceable(),

            .chest, .trapped_chest => {
                var neighbouring_chests: usize = 0;
                for (Direction.horizontals) |side| {
                    if (world.getBlock(pos.dir(side)) != self) continue;
                    // a neighbour that itself has a same-block neighbour is a double chest
                    // cannot place a chest next to a double chest (of the same type)
                    for (Direction.horizontals) |diag| {
                        if (world.getBlock(pos.dir(side).dir(diag)) == self) return false;
                    }
                    neighbouring_chests += 1;
                }
                // at most one neighboring chest
                return neighbouring_chests <= 1;
            },

            .ladder => {
                for (Direction.horizontals) |side| {
                    if (world.getBlock(pos.dir(side)).isSolid()) return true;
                }
                return false;
            },

            .torch, .redstone_torch => {
                // oh FOR FUCKS SAKEEEE
                // this is incorrect at the WORLD BORDER and when searching an UNLOADED CHUNK
                // TODO: KILL MYSELF
                for (Direction.horizontals) |side| {
                    const side_block = world.getBlock(pos.dir(side));
                    if (side_block.getMaterial().blocksMovementAndNotTranslucent() and side_block.isCube()) return true;
                }
                const below = world.getBlockState(pos.down());
                return below.hasSolidTop() or below.block.isFence() or switch (below.block) {
                    .glass, .cobblestone_wall, .stained_glass => true,
                    else => false,
                };
            },

            .stone_button, .wooden_button, .lever => if (dir.plane() == .horizontal)
                world.getBlock(pos.dir(dir.opposite())).isSolid()
            else
                world.getBlockState(pos.dir(dir.opposite())).hasSolidTop(),

            .trapdoor, .iron_trapdoor => {
                if (dir.plane() != .horizontal) return false;

                const side_block = world.getBlock(pos.dir(dir.opposite()));

                if (side_block.getMaterial().blocksMovementAndNotTranslucent() and side_block.isCube()) return true;

                return side_block == .glowstone or side_block.isSlab() or side_block.isStair();
            },

            .tripwire_hook => dir.plane() == .horizontal and world.getBlock(pos.dir(dir.opposite())).isSolid(),

            .vine => {
                if (dir == .down) return false;
                const target = world.getBlock(if (dir == .up) pos.up() else pos.dir(dir.opposite()));
                return target.isCube() and target.getMaterial().blocksMovement();
            },

            // sugarcane grows on a sand/grass/dirt block with water besides it
            // or on another sugarcane
            .reeds => {
                const below = world.getBlock(pos.down());
                if (below == .reeds) return true;
                if (below != .grass and below != .dirt and below != .sand) return false;
                for (Direction.horizontals) |side| {
                    if (world.getBlock(pos.dir(side).down()).getMaterial() == .water) return true;
                }
                return false;
            },

            .snow_layer => {
                const below = world.getBlockState(pos.down());
                switch (below.block) {
                    .ice, .packed_ice => return false,
                    .snow_layer => return below.payload(.snow_layer).layers == .@"7" or below.payload(.snow_layer).layers == .@"8",
                    else => |block| return block.getMaterial() == .leaves or (block.isSolidRender() and block.getMaterial().blocksMovement()),
                }
            },

            // stairs just delegate to their parent block
            // here for explicitness
            .oak_stairs,
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
            => replaceable,

            inline else => |unlisted| {
                @setEvalBranchQuota(10_000);
                // make sure our override arms are exhaustive
                comptime std.debug.assert(!attributes.overrides_can_be_placed.contains(unlisted));
                return replaceable;
            },
        };
    }

    pub fn getMiningProgress(self: @This(), player: *const LocalPlayer) f32 {
        _ = player;

        const hardness: f32 = self.getHardness();
        if (hardness < 0) return 0;

        const needs_tool = self.getMaterial().requiresTool();
        const player_mining_speed_multiplier: f32 = 1;

        return if (needs_tool)
            player_mining_speed_multiplier / hardness / 100.0
        else
            player_mining_speed_multiplier / hardness / 30.0;
    }
};

const std = @import("std");

const main = @import("main");

const attributes = @import("block_attributes.zig");
const material = @import("material.zig");

const Direction = main.Direction;
const LocalPlayer = main.Entity.LocalPlayer;
const Vector3 = main.Vector3;
const World = main.World;
