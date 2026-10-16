const main = @import("main");

const LocalPlayer = main.Entity.LocalPlayer;

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

    pub const Material = @import("material.zig").Material;

    pub const VirtualState = @import("virtual_state.zig").VirtualState;
    pub const PhysicalState = @import("physical_state.zig").PhysicalState;

    pub fn getFriction(self: @This()) f32 {
        return switch (self) {
            .slime => 0.8,
            .ice, .packed_ice => 0.98,
            else => 0.6,
        };
    }

    const full_cube_table = @import("full_cube.zig").full_cube;
    pub fn isFullCube(self: @This()) bool {
        return full_cube_table.contains(self);
    }

    /// TODO: STUB
    pub fn isSolid(self: @This()) bool {
        return self.isFullCube();
    }

    const hardness_table = @import("hardness.zig").hardness;
    pub fn getHardness(self: @This()) f32 {
        return hardness_table.get(self);
    }

    const block_to_material = @import("material.zig").block_to_material;
    pub fn getMaterial(self: @This()) Material {
        return block_to_material.get(self);
    }

    pub fn getMiningProgress(self: @This(), player: *const LocalPlayer) f32 {
        _ = player;

        const hardness: f32 = self.getHardness();
        if (hardness < 0) return 0;

        const can_break_efficiently = self.getMaterial().toolNotRequired();
        const player_mining_speed_multiplier: f32 = 1;

        return if (!can_break_efficiently)
            player_mining_speed_multiplier / hardness / 100.0
        else
            player_mining_speed_multiplier / hardness / 30.0;
    }
};
