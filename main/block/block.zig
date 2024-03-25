const std = @import("std");
const World = @import("../world/World.zig");
const Vector3 = @import("../math/vector.zig").Vector3;
const Box = @import("../math/box.zig").Box;

// Requirements of system:
// Looking up the raytrace hitboxes for a blockstate, which depends on virtual properties, must be fast
// Looking up the collision hitboxes for a blockstate, which depends on virtual properties, must be fast
// Looking up the model for a blockstate, which depends on virtual properties, must be fast
// looking up toughness, friction, tool, etc. for a block, must be fast
// Fully resolved blockstates must take up 16 bits or less

// To accomplish this, we split off the blocks that have too many virtual blockstates into multiple blocks

// To look up the raytrace/collision hitboxes, we use a hashmap
// To look up the toughness/friction/tool/solidity, we use only the block bits and index into an enum array

// The types of each block
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
};

// The raw bytes sent over
pub const RawBlockState = packed struct(u16) {
    metadata: u4,
    block: u12,

    pub fn toFiltered(self: @This()) FilteredBlockState {
        const block: Block = std.meta.intToEnum(Block, self.block) catch return FilteredBlockState.AIR;
        if (!@import("./valid_metadata_table.zig").@"export".get(block).isSet(self.metadata)) return FilteredBlockState.AIR;
        return .{
            .block = block,
            .properties = .{ .raw_bits = @import("./metadata_conversion_table.zig").@"export".get(block).get(self.metadata) },
        };
    }
};

// RawBlockState, but stipped of invalid states and converted into a sane format
pub const FilteredBlockState = packed struct(u12) {
    block: Block,
    properties: BlockProperties,

    pub const AIR: @This() = .{ .block = .air, .properties = .{ .raw_bits = 0 } };

    pub const BlockProperties = packed union {
        pub const air = packed struct(u4) { _: u4 = 0 };
        pub const stone = packed struct(u4) { variant: enum(u3) { stone, granite, smooth_granite, diorite, smooth_diorite, andesite, smooth_andesite }, _: u1 = 0 };
        pub const grass = packed struct(u4) { _: u4 = 0 };
        pub const dirt = packed struct(u4) { variant: enum(u2) { dirt, coarse_dirt, podzol }, _: u2 = 0 };
        pub const cobblestone = packed struct(u4) { _: u4 = 0 };
        pub const planks = packed struct(u4) { variant: enum(u3) { oak, spruce, birch, jungle, acacia, dark_oak }, _: u1 = 0 };
        pub const sapling = packed struct(u4) { variant: enum(u3) { oak, spruce, birch, jungle, acacia, dark_oak }, stage: u1 };
        pub const bedrock = packed struct(u4) { _: u4 = 0 };
        pub const flowing_water = packed struct(u4) { level: u4 };
        pub const water = packed struct(u4) { level: u4 };
        pub const flowing_lava = packed struct(u4) { level: u4 };
        pub const lava = packed struct(u4) { level: u4 };
        pub const sand = packed struct(u4) { variant: enum(u1) { sand, red_sand }, _: u3 = 0 };
        pub const gravel = packed struct(u4) { _: u4 = 0 };
        pub const gold_ore = packed struct(u4) { _: u4 = 0 };
        pub const iron_ore = packed struct(u4) { _: u4 = 0 };
        pub const coal_ore = packed struct(u4) { _: u4 = 0 };
        pub const log = packed struct(u4) { axis: enum(u2) { x, y, z, none }, variant: enum(u2) { oak, spruce, birch, jungle } };
        pub const leaves = packed struct(u4) { variant: enum(u2) { oak, spruce, birch, jungle }, check_decay: bool, decayable: bool };
        pub const sponge = packed struct(u4) { wet: bool, _: u3 = 0 };
        pub const glass = packed struct(u4) { _: u4 = 0 };
        pub const lapis_ore = packed struct(u4) { _: u4 = 0 };
        pub const lapis_block = packed struct(u4) { _: u4 = 0 };
        pub const dispenser = packed struct(u4) { triggered: bool, facing: enum(u3) { down, up, north, south, west, east } };
        pub const sandstone = packed struct(u4) { variant: enum(u2) { sandstone, chiseled_sandstone, smooth_sandstone }, _: u2 = 0 };
        pub const noteblock = packed struct(u4) { _: u4 = 0 };
        pub const bed = packed struct(u4) { occupied: bool, facing: enum(u2) { north, south, west, east }, part: enum(u1) { head, foot } };
        pub const golden_rail = packed struct(u4) { powered: bool, shape: enum(u3) { north_south, east_west, ascending_east, ascending_west, ascending_north, ascending_south } };
        pub const detector_rail = packed struct(u4) { powered: bool, shape: enum(u3) { north_south, east_west, ascending_east, ascending_west, ascending_north, ascending_south } };
        pub const sticky_piston = packed struct(u4) { facing: enum(u3) { down, up, north, south, west, east }, extended: bool };
        pub const web = packed struct(u4) { _: u4 = 0 };
        pub const tallgrass = packed struct(u4) { variant: enum(u2) { dead_bush, tall_grass, fern }, _: u2 = 0 };
        pub const deadbush = packed struct(u4) { _: u4 = 0 };
        pub const piston = packed struct(u4) { facing: enum(u3) { down, up, north, south, west, east }, extended: bool };
        pub const piston_head = packed struct(u4) { variant: enum(u1) { normal, sticky }, facing: enum(u3) { down, up, north, south, west, east } };
        pub const wool = packed struct(u4) { color: enum(u4) { white, orange, magenta, light_blue, yellow, lime, pink, gray, silver, cyan, purple, blue, brown, green, red, black } };
        pub const piston_extension = packed struct(u4) { variant: enum(u1) { normal, sticky }, facing: enum(u3) { down, up, north, south, west, east } };
        pub const yellow_flower = packed struct(u4) { _: u4 = 0 };
        pub const red_flower = packed struct(u4) { variant: enum(u4) { poppy, blue_orchid, allium, houstonia, red_tulip, orange_tulip, white_tulip, pink_tulip, oxeye_daisy } };
        pub const brown_mushroom = packed struct(u4) { _: u4 = 0 };
        pub const red_mushroom = packed struct(u4) { _: u4 = 0 };
        pub const gold_block = packed struct(u4) { _: u4 = 0 };
        pub const iron_block = packed struct(u4) { _: u4 = 0 };
        pub const double_stone_slab = packed struct(u4) { seamless: bool, variant: enum(u3) { stone, sandstone, wood_old, cobblestone, brick, stone_brick, nether_brick, quartz } };
        pub const stone_slab = packed struct(u4) { variant: enum(u3) { stone, sandstone, wood_old, cobblestone, brick, stone_brick, nether_brick, quartz }, half: enum(u1) { top, bottom } };
        pub const brick_block = packed struct(u4) { _: u4 = 0 };
        pub const tnt = packed struct(u4) { explode: bool, _: u3 = 0 };
        pub const bookshelf = packed struct(u4) { _: u4 = 0 };
        pub const mossy_cobblestone = packed struct(u4) { _: u4 = 0 };
        pub const obsidian = packed struct(u4) { _: u4 = 0 };
        pub const torch = packed struct(u4) { facing: enum(u3) { up, north, south, west, east }, _: u1 = 0 };
        pub const fire = packed struct(u4) { age: u4 };
        pub const mob_spawner = packed struct(u4) { _: u4 = 0 };
        pub const oak_stairs = packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 };
        pub const chest = packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 };
        pub const redstone_wire = packed struct(u4) { power: u4 };
        pub const diamond_ore = packed struct(u4) { _: u4 = 0 };
        pub const diamond_block = packed struct(u4) { _: u4 = 0 };
        pub const crafting_table = packed struct(u4) { _: u4 = 0 };
        pub const wheat = packed struct(u4) { age: u3, _: u1 = 0 };
        pub const farmland = packed struct(u4) { moisture: u3, _: u1 = 0 };
        pub const furnace = packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 };
        pub const lit_furnace = packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 };
        pub const standing_sign = packed struct(u4) { rotation: u4 };
        pub const wooden_door = packed struct(u4) { half: enum(u1) { upper, lower }, other: packed union { when_upper: packed struct(u3) { hinge: enum(u1) { left, right }, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: enum(u2) { north, south, west, east }, open: bool } } };
        pub const ladder = packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 };
        pub const rail = packed struct(u4) { shape: enum(u4) { north_south, east_west, ascending_east, ascending_west, ascending_north, ascending_south, south_east, south_west, north_west, north_east } };
        pub const stone_stairs = packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 };
        pub const wall_sign = packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 };
        pub const lever = packed struct(u4) { powered: bool, facing: enum(u3) { down_x, east, west, south, north, up_z, up_x, down_z } };
        pub const stone_pressure_plate = packed struct(u4) { powered: bool, _: u3 = 0 };
        pub const iron_door = packed struct(u4) { half: enum(u1) { upper, lower }, other: packed union { when_upper: packed struct(u3) { hinge: enum(u1) { left, right }, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: enum(u2) { north, south, west, east }, open: bool } } };
        pub const wooden_pressure_plate = packed struct(u4) { powered: bool, _: u3 = 0 };
        pub const redstone_ore = packed struct(u4) { _: u4 = 0 };
        pub const lit_redstone_ore = packed struct(u4) { _: u4 = 0 };
        pub const unlit_redstone_torch = packed struct(u4) { facing: enum(u3) { up, north, south, west, east }, _: u1 = 0 };
        pub const redstone_torch = packed struct(u4) { facing: enum(u3) { up, north, south, west, east }, _: u1 = 0 };
        pub const stone_button = packed struct(u4) { powered: bool, facing: enum(u3) { down, up, north, south, west, east } };
        pub const snow_layer = packed struct(u4) { layers: u3, _: u1 = 0 };
        pub const ice = packed struct(u4) { _: u4 = 0 };
        pub const snow = packed struct(u4) { _: u4 = 0 };
        pub const cactus = packed struct(u4) { age: u4 };
        pub const clay = packed struct(u4) { _: u4 = 0 };
        pub const reeds = packed struct(u4) { age: u4 };
        pub const jukebox = packed struct(u4) { has_record: bool, _: u3 = 0 };
        pub const fence = packed struct(u4) { _: u4 = 0 };
        pub const pumpkin = packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 };
        pub const netherrack = packed struct(u4) { _: u4 = 0 };
        pub const soul_sand = packed struct(u4) { _: u4 = 0 };
        pub const glowstone = packed struct(u4) { _: u4 = 0 };
        pub const portal = packed struct(u4) { axis: enum(u1) { x, z }, _: u3 = 0 };
        pub const lit_pumpkin = packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 };
        pub const cake = packed struct(u4) { bites: u3, _: u1 = 0 };
        pub const unpowered_repeater = packed struct(u4) { delay: u2, facing: enum(u2) { north, south, west, east } };
        pub const powered_repeater = packed struct(u4) { delay: u2, facing: enum(u2) { north, south, west, east } };
        pub const stained_glass = packed struct(u4) { color: enum(u4) { white, orange, magenta, light_blue, yellow, lime, pink, gray, silver, cyan, purple, blue, brown, green, red, black } };
        pub const trapdoor = packed struct(u4) { open: bool, half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east } };
        pub const monster_egg = packed struct(u4) { variant: enum(u3) { stone, cobblestone, stone_brick, mossy_brick, cracked_brick, chiseled_brick }, _: u1 = 0 };
        pub const stonebrick = packed struct(u4) { variant: enum(u2) { stonebrick, mossy_stonebrick, cracked_stonebrick, chiseled_stonebrick }, _: u2 = 0 };
        pub const brown_mushroom_block = packed struct(u4) { variant: enum(u4) { north_west, north, north_east, west, center, east, south_west, south, south_east, stem, all_inside, all_outside, all_stem } };
        pub const red_mushroom_block = packed struct(u4) { variant: enum(u4) { north_west, north, north_east, west, center, east, south_west, south, south_east, stem, all_inside, all_outside, all_stem } };
        pub const iron_bars = packed struct(u4) { _: u4 = 0 };
        pub const glass_pane = packed struct(u4) { _: u4 = 0 };
        pub const melon_block = packed struct(u4) { _: u4 = 0 };
        pub const pumpkin_stem = packed struct(u4) { age: u3, _: u1 = 0 };
        pub const melon_stem = packed struct(u4) { age: u3, _: u1 = 0 };
        pub const vine = packed struct(u4) { west: bool, south: bool, north: bool, east: bool };
        pub const fence_gate = packed struct(u4) { open: bool, powered: bool, facing: enum(u2) { north, south, west, east } };
        pub const brick_stairs = packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 };
        pub const stone_brick_stairs = packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 };
        pub const mycelium = packed struct(u4) { _: u4 = 0 };
        pub const waterlily = packed struct(u4) { _: u4 = 0 };
        pub const nether_brick = packed struct(u4) { _: u4 = 0 };
        pub const nether_brick_fence = packed struct(u4) { _: u4 = 0 };
        pub const nether_brick_stairs = packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 };
        pub const nether_wart = packed struct(u4) { age: u2, _: u2 = 0 };
        pub const enchanting_table = packed struct(u4) { _: u4 = 0 };
        pub const brewing_stand = packed struct(u4) { has_bottle_2: bool, has_bottle_0: bool, has_bottle_1: bool, _: u1 = 0 };
        pub const cauldron = packed struct(u4) { level: u2, _: u2 = 0 };
        pub const end_portal = packed struct(u4) { _: u4 = 0 };
        pub const end_portal_frame = packed struct(u4) { eye: bool, facing: enum(u2) { north, south, west, east }, _: u1 = 0 };
        pub const end_stone = packed struct(u4) { _: u4 = 0 };
        pub const dragon_egg = packed struct(u4) { _: u4 = 0 };
        pub const redstone_lamp = packed struct(u4) { _: u4 = 0 };
        pub const lit_redstone_lamp = packed struct(u4) { _: u4 = 0 };
        pub const double_wooden_slab = packed struct(u4) { variant: enum(u3) { oak, spruce, birch, jungle, acacia, dark_oak }, _: u1 = 0 };
        pub const wooden_slab = packed struct(u4) { variant: enum(u3) { oak, spruce, birch, jungle, acacia, dark_oak }, half: enum(u1) { top, bottom } };
        pub const cocoa = packed struct(u4) { age: u2, facing: enum(u2) { north, south, west, east } };
        pub const sandstone_stairs = packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 };
        pub const emerald_ore = packed struct(u4) { _: u4 = 0 };
        pub const ender_chest = packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 };
        pub const tripwire_hook = packed struct(u4) { powered: bool, facing: enum(u2) { north, south, west, east }, attached: bool };
        pub const tripwire = packed struct(u4) { powered: bool, disarmed: bool, attached: bool, suspended: bool };
        pub const emerald_block = packed struct(u4) { _: u4 = 0 };
        pub const spruce_stairs = packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 };
        pub const birch_stairs = packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 };
        pub const jungle_stairs = packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 };
        pub const command_block = packed struct(u4) { triggered: bool, _: u3 = 0 };
        pub const beacon = packed struct(u4) { _: u4 = 0 };
        pub const cobblestone_wall = packed struct(u4) { variant: enum(u1) { cobblestone, mossy_cobblestone }, _: u3 = 0 };
        pub const flower_pot = packed struct(u4) { _: u4 = 0 };
        pub const carrots = packed struct(u4) { age: u3, _: u1 = 0 };
        pub const potatoes = packed struct(u4) { age: u3, _: u1 = 0 };
        pub const wooden_button = packed struct(u4) { powered: bool, facing: enum(u3) { down, up, north, south, west, east } };
        pub const skull = packed struct(u4) { facing: enum(u3) { down, up, north, south, west, east }, nodrop: bool };
        pub const anvil = packed struct(u4) { damage: u2, facing: enum(u2) { north, south, west, east } };
        pub const trapped_chest = packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 };
        pub const light_weighted_pressure_plate = packed struct(u4) { power: u4 };
        pub const heavy_weighted_pressure_plate = packed struct(u4) { power: u4 };
        pub const unpowered_comparator = packed struct(u4) { powered: bool, mode: enum(u1) { compare, subtract }, facing: enum(u2) { north, south, west, east } };
        pub const powered_comparator = packed struct(u4) { powered: bool, mode: enum(u1) { compare, subtract }, facing: enum(u2) { north, south, west, east } };
        pub const daylight_detector = packed struct(u4) { power: u4 };
        pub const redstone_block = packed struct(u4) { _: u4 = 0 };
        pub const quartz_ore = packed struct(u4) { _: u4 = 0 };
        pub const hopper = packed struct(u4) { facing: enum(u3) { down, north, south, west, east }, enabled: bool };
        pub const quartz_block = packed struct(u4) { variant: enum(u3) { default, chiseled, lines_x, lines_y, lines_z }, _: u1 = 0 };
        pub const quartz_stairs = packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 };
        pub const activator_rail = packed struct(u4) { powered: bool, shape: enum(u3) { north_south, east_west, ascending_east, ascending_west, ascending_north, ascending_south } };
        pub const dropper = packed struct(u4) { triggered: bool, facing: enum(u3) { down, up, north, south, west, east } };
        pub const stained_hardened_clay = packed struct(u4) { color: enum(u4) { white, orange, magenta, light_blue, yellow, lime, pink, gray, silver, cyan, purple, blue, brown, green, red, black } };
        pub const stained_glass_pane = packed struct(u4) { color: enum(u4) { white, orange, magenta, light_blue, yellow, lime, pink, gray, silver, cyan, purple, blue, brown, green, red, black } };
        pub const leaves2 = packed struct(u4) { variant: enum(u1) { acacia, dark_oak }, check_decay: bool, decayable: bool, _: u1 = 0 };
        pub const log2 = packed struct(u4) { axis: enum(u2) { x, y, z, none }, variant: enum(u1) { acacia, dark_oak }, _: u1 = 0 };
        pub const acacia_stairs = packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 };
        pub const dark_oak_stairs = packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 };
        pub const slime = packed struct(u4) { _: u4 = 0 };
        pub const barrier = packed struct(u4) { _: u4 = 0 };
        pub const iron_trapdoor = packed struct(u4) { open: bool, half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east } };
        pub const prismarine = packed struct(u4) { variant: enum(u2) { prismarine, prismarine_bricks, dark_prismarine }, _: u2 = 0 };
        pub const sea_lantern = packed struct(u4) { _: u4 = 0 };
        pub const hay_block = packed struct(u4) { axis: enum(u2) { x, y, z }, _: u2 = 0 };
        pub const carpet = packed struct(u4) { color: enum(u4) { white, orange, magenta, light_blue, yellow, lime, pink, gray, silver, cyan, purple, blue, brown, green, red, black } };
        pub const hardened_clay = packed struct(u4) { _: u4 = 0 };
        pub const coal_block = packed struct(u4) { _: u4 = 0 };
        pub const packed_ice = packed struct(u4) { _: u4 = 0 };
        pub const double_plant = packed struct(u4) { variant: enum(u3) { sunflower, syringa, double_grass, double_fern, double_rose, paeonia }, half: enum(u1) { upper, lower } };
        pub const standing_banner = packed struct(u4) { rotation: u4 };
        pub const wall_banner = packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 };
        pub const daylight_detector_inverted = packed struct(u4) { power: u4 };
        pub const red_sandstone = packed struct(u4) { variant: enum(u2) { red_sandstone, chiseled_red_sandstone, smooth_red_sandstone }, _: u2 = 0 };
        pub const red_sandstone_stairs = packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 };
        pub const double_stone_slab2 = packed struct(u4) { seamless: bool, _: u3 = 0 };
        pub const stone_slab2 = packed struct(u4) { half: enum(u1) { top, bottom }, _: u3 = 0 };
        pub const spruce_fence_gate = packed struct(u4) { open: bool, powered: bool, facing: enum(u2) { north, south, west, east } };
        pub const birch_fence_gate = packed struct(u4) { open: bool, powered: bool, facing: enum(u2) { north, south, west, east } };
        pub const jungle_fence_gate = packed struct(u4) { open: bool, powered: bool, facing: enum(u2) { north, south, west, east } };
        pub const dark_oak_fence_gate = packed struct(u4) { open: bool, powered: bool, facing: enum(u2) { north, south, west, east } };
        pub const acacia_fence_gate = packed struct(u4) { open: bool, powered: bool, facing: enum(u2) { north, south, west, east } };
        pub const spruce_fence = packed struct(u4) { _: u4 = 0 };
        pub const birch_fence = packed struct(u4) { _: u4 = 0 };
        pub const jungle_fence = packed struct(u4) { _: u4 = 0 };
        pub const dark_oak_fence = packed struct(u4) { _: u4 = 0 };
        pub const acacia_fence = packed struct(u4) { _: u4 = 0 };
        pub const spruce_door = packed struct(u4) { half: enum(u1) { upper, lower }, other: packed union { when_upper: packed struct(u3) { hinge: enum(u1) { left, right }, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: enum(u2) { north, south, west, east }, open: bool } } };
        pub const birch_door = packed struct(u4) { half: enum(u1) { upper, lower }, other: packed union { when_upper: packed struct(u3) { hinge: enum(u1) { left, right }, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: enum(u2) { north, south, west, east }, open: bool } } };
        pub const jungle_door = packed struct(u4) { half: enum(u1) { upper, lower }, other: packed union { when_upper: packed struct(u3) { hinge: enum(u1) { left, right }, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: enum(u2) { north, south, west, east }, open: bool } } };
        pub const acacia_door = packed struct(u4) { half: enum(u1) { upper, lower }, other: packed union { when_upper: packed struct(u3) { hinge: enum(u1) { left, right }, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: enum(u2) { north, south, west, east }, open: bool } } };
        pub const dark_oak_door = packed struct(u4) { half: enum(u1) { upper, lower }, other: packed union { when_upper: packed struct(u3) { hinge: enum(u1) { left, right }, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: enum(u2) { north, south, west, east }, open: bool } } };

        raw_bits: u4,
        air: air,
        stone: stone,
        grass: grass,
        dirt: dirt,
        cobblestone: cobblestone,
        planks: planks,
        sapling: sapling,
        bedrock: bedrock,
        flowing_water: flowing_water,
        water: water,
        flowing_lava: flowing_lava,
        lava: lava,
        sand: sand,
        gravel: gravel,
        gold_ore: gold_ore,
        iron_ore: iron_ore,
        coal_ore: coal_ore,
        log: log,
        leaves: leaves,
        sponge: sponge,
        glass: glass,
        lapis_ore: lapis_ore,
        lapis_block: lapis_block,
        dispenser: dispenser,
        sandstone: sandstone,
        noteblock: noteblock,
        bed: bed,
        golden_rail: golden_rail,
        detector_rail: detector_rail,
        sticky_piston: sticky_piston,
        web: web,
        tallgrass: tallgrass,
        deadbush: deadbush,
        piston: piston,
        piston_head: piston_head,
        wool: wool,
        piston_extension: piston_extension,
        yellow_flower: yellow_flower,
        red_flower: red_flower,
        brown_mushroom: brown_mushroom,
        red_mushroom: red_mushroom,
        gold_block: gold_block,
        iron_block: iron_block,
        double_stone_slab: double_stone_slab,
        stone_slab: stone_slab,
        brick_block: brick_block,
        tnt: tnt,
        bookshelf: bookshelf,
        mossy_cobblestone: mossy_cobblestone,
        obsidian: obsidian,
        torch: torch,
        fire: fire,
        mob_spawner: mob_spawner,
        oak_stairs: oak_stairs,
        chest: chest,
        redstone_wire: redstone_wire,
        diamond_ore: diamond_ore,
        diamond_block: diamond_block,
        crafting_table: crafting_table,
        wheat: wheat,
        farmland: farmland,
        furnace: furnace,
        lit_furnace: lit_furnace,
        standing_sign: standing_sign,
        wooden_door: wooden_door,
        ladder: ladder,
        rail: rail,
        stone_stairs: stone_stairs,
        wall_sign: wall_sign,
        lever: lever,
        stone_pressure_plate: stone_pressure_plate,
        iron_door: iron_door,
        wooden_pressure_plate: wooden_pressure_plate,
        redstone_ore: redstone_ore,
        lit_redstone_ore: lit_redstone_ore,
        unlit_redstone_torch: unlit_redstone_torch,
        redstone_torch: redstone_torch,
        stone_button: stone_button,
        snow_layer: snow_layer,
        ice: ice,
        snow: snow,
        cactus: cactus,
        clay: clay,
        reeds: reeds,
        jukebox: jukebox,
        fence: fence,
        pumpkin: pumpkin,
        netherrack: netherrack,
        soul_sand: soul_sand,
        glowstone: glowstone,
        portal: portal,
        lit_pumpkin: lit_pumpkin,
        cake: cake,
        unpowered_repeater: unpowered_repeater,
        powered_repeater: powered_repeater,
        stained_glass: stained_glass,
        trapdoor: trapdoor,
        monster_egg: monster_egg,
        stonebrick: stonebrick,
        brown_mushroom_block: brown_mushroom_block,
        red_mushroom_block: red_mushroom_block,
        iron_bars: iron_bars,
        glass_pane: glass_pane,
        melon_block: melon_block,
        pumpkin_stem: pumpkin_stem,
        melon_stem: melon_stem,
        vine: vine,
        fence_gate: fence_gate,
        brick_stairs: brick_stairs,
        stone_brick_stairs: stone_brick_stairs,
        mycelium: mycelium,
        waterlily: waterlily,
        nether_brick: nether_brick,
        nether_brick_fence: nether_brick_fence,
        nether_brick_stairs: nether_brick_stairs,
        nether_wart: nether_wart,
        enchanting_table: enchanting_table,
        brewing_stand: brewing_stand,
        cauldron: cauldron,
        end_portal: end_portal,
        end_portal_frame: end_portal_frame,
        end_stone: end_stone,
        dragon_egg: dragon_egg,
        redstone_lamp: redstone_lamp,
        lit_redstone_lamp: lit_redstone_lamp,
        double_wooden_slab: double_wooden_slab,
        wooden_slab: wooden_slab,
        cocoa: cocoa,
        sandstone_stairs: sandstone_stairs,
        emerald_ore: emerald_ore,
        ender_chest: ender_chest,
        tripwire_hook: tripwire_hook,
        tripwire: tripwire,
        emerald_block: emerald_block,
        spruce_stairs: spruce_stairs,
        birch_stairs: birch_stairs,
        jungle_stairs: jungle_stairs,
        command_block: command_block,
        beacon: beacon,
        cobblestone_wall: cobblestone_wall,
        flower_pot: flower_pot,
        carrots: carrots,
        potatoes: potatoes,
        wooden_button: wooden_button,
        skull: skull,
        anvil: anvil,
        trapped_chest: trapped_chest,
        light_weighted_pressure_plate: light_weighted_pressure_plate,
        heavy_weighted_pressure_plate: heavy_weighted_pressure_plate,
        unpowered_comparator: unpowered_comparator,
        powered_comparator: powered_comparator,
        daylight_detector: daylight_detector,
        redstone_block: redstone_block,
        quartz_ore: quartz_ore,
        hopper: hopper,
        quartz_block: quartz_block,
        quartz_stairs: quartz_stairs,
        activator_rail: activator_rail,
        dropper: dropper,
        stained_hardened_clay: stained_hardened_clay,
        stained_glass_pane: stained_glass_pane,
        leaves2: leaves2,
        log2: log2,
        acacia_stairs: acacia_stairs,
        dark_oak_stairs: dark_oak_stairs,
        slime: slime,
        barrier: barrier,
        iron_trapdoor: iron_trapdoor,
        prismarine: prismarine,
        sea_lantern: sea_lantern,
        hay_block: hay_block,
        carpet: carpet,
        hardened_clay: hardened_clay,
        coal_block: coal_block,
        packed_ice: packed_ice,
        double_plant: double_plant,
        standing_banner: standing_banner,
        wall_banner: wall_banner,
        daylight_detector_inverted: daylight_detector_inverted,
        red_sandstone: red_sandstone,
        red_sandstone_stairs: red_sandstone_stairs,
        double_stone_slab2: double_stone_slab2,
        stone_slab2: stone_slab2,
        spruce_fence_gate: spruce_fence_gate,
        birch_fence_gate: birch_fence_gate,
        jungle_fence_gate: jungle_fence_gate,
        dark_oak_fence_gate: dark_oak_fence_gate,
        acacia_fence_gate: acacia_fence_gate,
        spruce_fence: spruce_fence,
        birch_fence: birch_fence,
        jungle_fence: jungle_fence,
        dark_oak_fence: dark_oak_fence,
        acacia_fence: acacia_fence,
        spruce_door: spruce_door,
        birch_door: birch_door,
        jungle_door: jungle_door,
        acacia_door: acacia_door,
        dark_oak_door: dark_oak_door,
    };

    /// Casts to a concrete block state - DOES NOT resolve virtual states
    pub fn toConcrete(self: @This()) ConcreteBlockState {
        return .{
            .block = @enumFromInt(@intFromEnum(self.block)),
            .properties = .{ .raw_bits = .{ .virtual = 0, .stored = @bitCast(self.properties) } },
        };
    }
};

// Block, but with some blocks split to be used with ConcreteBlockState
pub const ConcreteBlock = enum(u8) {
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

    fire_upper,

    redstone_wire_none_flat,
    redstone_wire_none_upper,
    redstone_wire_flat_none,
    redstone_wire_flat_flat,
    redstone_wire_flat_upper,
    redstone_wire_upper_none,
    redstone_wire_upper_flat,
    redstone_wire_upper_upper,

    cobblestone_wall_upper,

    flower_pot_2,

    pub const full_cube_table = EnumBoolArray(@This()).init(.{
        .air = true,
        .stone = true,
        .grass = true,
        .dirt = true,
        .cobblestone = true,
        .planks = true,
        .sapling = false,
        .bedrock = true,
        .flowing_water = false,
        .water = false,
        .flowing_lava = false,
        .lava = false,
        .sand = true,
        .gravel = true,
        .gold_ore = true,
        .iron_ore = true,
        .coal_ore = true,
        .log = true,
        .leaves = true,
        .sponge = true,
        .glass = false,
        .lapis_ore = true,
        .lapis_block = true,
        .dispenser = true,
        .sandstone = true,
        .noteblock = true,
        .bed = false,
        .golden_rail = false,
        .detector_rail = false,
        .sticky_piston = false,
        .web = false,
        .tallgrass = false,
        .deadbush = false,
        .piston = false,
        .piston_head = false,
        .wool = true,
        .piston_extension = false,
        .yellow_flower = false,
        .red_flower = false,
        .brown_mushroom = false,
        .red_mushroom = false,
        .gold_block = true,
        .iron_block = true,
        .double_stone_slab = true,
        .stone_slab = false,
        .brick_block = true,
        .tnt = true,
        .bookshelf = true,
        .mossy_cobblestone = true,
        .obsidian = true,
        .torch = false,
        .fire = false,
        .mob_spawner = true,
        .oak_stairs = false,
        .chest = false,
        .redstone_wire = false,
        .diamond_ore = true,
        .diamond_block = true,
        .crafting_table = true,
        .wheat = false,
        .farmland = false,
        .furnace = true,
        .lit_furnace = true,
        .standing_sign = false,
        .wooden_door = false,
        .ladder = false,
        .rail = false,
        .stone_stairs = false,
        .wall_sign = false,
        .lever = false,
        .stone_pressure_plate = false,
        .iron_door = false,
        .wooden_pressure_plate = false,
        .redstone_ore = true,
        .lit_redstone_ore = true,
        .unlit_redstone_torch = false,
        .redstone_torch = false,
        .stone_button = false,
        .snow_layer = false,
        .ice = true,
        .snow = true,
        .cactus = false,
        .clay = true,
        .reeds = false,
        .jukebox = true,
        .fence = false,
        .pumpkin = true,
        .netherrack = true,
        .soul_sand = true,
        .glowstone = true,
        .portal = false,
        .lit_pumpkin = true,
        .cake = false,
        .unpowered_repeater = false,
        .powered_repeater = false,
        .stained_glass = false,
        .trapdoor = false,
        .monster_egg = true,
        .stonebrick = true,
        .brown_mushroom_block = true,
        .red_mushroom_block = true,
        .iron_bars = false,
        .glass_pane = false,
        .melon_block = true,
        .pumpkin_stem = false,
        .melon_stem = false,
        .vine = false,
        .fence_gate = false,
        .brick_stairs = false,
        .stone_brick_stairs = false,
        .mycelium = true,
        .waterlily = false,
        .nether_brick = true,
        .nether_brick_fence = false,
        .nether_brick_stairs = false,
        .nether_wart = false,
        .enchanting_table = false,
        .brewing_stand = false,
        .cauldron = false,
        .end_portal = false,
        .end_portal_frame = true,
        .end_stone = true,
        .dragon_egg = false,
        .redstone_lamp = true,
        .lit_redstone_lamp = true,
        .double_wooden_slab = true,
        .wooden_slab = false,
        .cocoa = false,
        .sandstone_stairs = false,
        .emerald_ore = true,
        .ender_chest = false,
        .tripwire_hook = false,
        .tripwire = false,
        .emerald_block = true,
        .spruce_stairs = false,
        .birch_stairs = false,
        .jungle_stairs = false,
        .command_block = true,
        .beacon = false,
        .cobblestone_wall = false,
        .flower_pot = false,
        .carrots = false,
        .potatoes = false,
        .wooden_button = false,
        .skull = false,
        .anvil = false,
        .trapped_chest = false,
        .light_weighted_pressure_plate = false,
        .heavy_weighted_pressure_plate = false,
        .unpowered_comparator = false,
        .powered_comparator = false,
        .daylight_detector = false,
        .redstone_block = true,
        .quartz_ore = true,
        .hopper = false,
        .quartz_block = true,
        .quartz_stairs = false,
        .activator_rail = false,
        .dropper = true,
        .stained_hardened_clay = true,
        .stained_glass_pane = false,
        .leaves2 = true,
        .log2 = true,
        .acacia_stairs = false,
        .dark_oak_stairs = false,
        .slime = true,
        .barrier = true,
        .iron_trapdoor = false,
        .prismarine = true,
        .sea_lantern = true,
        .hay_block = true,
        .carpet = false,
        .hardened_clay = true,
        .coal_block = true,
        .packed_ice = true,
        .double_plant = false,
        .standing_banner = false,
        .wall_banner = false,
        .daylight_detector_inverted = false,
        .red_sandstone = true,
        .red_sandstone_stairs = false,
        .double_stone_slab2 = true,
        .stone_slab2 = false,
        .spruce_fence_gate = false,
        .birch_fence_gate = false,
        .jungle_fence_gate = false,
        .dark_oak_fence_gate = false,
        .acacia_fence_gate = false,
        .spruce_fence = false,
        .birch_fence = false,
        .jungle_fence = false,
        .dark_oak_fence = false,
        .acacia_fence = false,
        .spruce_door = false,
        .birch_door = false,
        .jungle_door = false,
        .acacia_door = false,
        .dark_oak_door = false,

        .fire_upper = false,

        .redstone_wire_none_flat = false,
        .redstone_wire_none_upper = false,
        .redstone_wire_flat_none = false,
        .redstone_wire_flat_flat = false,
        .redstone_wire_flat_upper = false,
        .redstone_wire_upper_none = false,
        .redstone_wire_upper_flat = false,
        .redstone_wire_upper_upper = false,

        .cobblestone_wall_upper = false,

        .flower_pot_2 = false,
    });

    pub fn isFullCube(self: @This()) bool {
        return full_cube_table.get(self);
    }

    pub fn getFriction(self: @This()) f32 {
        return switch (self) {
            .slime => 0.8,
            .ice, .packed_ice => 0.98,
            else => 0.6,
        };
    }
};

pub const Material = enum {
    air,
    grass,
    dirt,
    wood,
    stone,
    iron,
    anvil,
    water,
    lava,
    leaves,
    plant,
    replaceable_plant,
    sponge,
    wool,
    fire,
    sand,
    decoration,
    carpet,
    glass,
    redstone_lamp,
    tnt,
    coral,
    ice,
    packed_ice,
    snow_layer,
    snow,
    cactus,
    clay,
    pumpkin,
    egg,
    portal,
    cake,
    cobweb,
    piston,
    barrier,
};

// FilteredBlockState, but with virtual properties resolved
pub const ConcreteBlockState = packed struct(u16) {
    pub var AIR: ConcreteBlockState = .{
        .block = .air,
        .properties = .{ .air = .{ .stored = .{} } },
    };

    const BlockProperties = packed union {
        const StoredBlockProperties = FilteredBlockState.BlockProperties;

        raw_bits: packed struct(u8) {
            virtual: u4,
            stored: u4,
        },
        air: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.air,
        },
        stone: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.stone,
        },
        grass: packed struct(u8) {
            virtual: packed struct(u4) { snowy: bool, _: u3 = 0 },
            stored: StoredBlockProperties.grass,
        },
        dirt: packed struct(u8) {
            virtual: packed struct(u4) { snowy: bool, _: u3 = 0 },
            stored: StoredBlockProperties.dirt,
        },
        cobblestone: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.cobblestone,
        },
        planks: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.planks,
        },
        sapling: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.sapling,
        },
        bedrock: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.bedrock,
        },
        flowing_water: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.flowing_water,
        },
        water: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.water,
        },
        flowing_lava: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.flowing_lava,
        },
        lava: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.lava,
        },
        sand: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.sand,
        },
        gravel: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.gravel,
        },
        gold_ore: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.gold_ore,
        },
        iron_ore: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.iron_ore,
        },
        coal_ore: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.coal_ore,
        },
        log: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.log,
        },
        leaves: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.leaves,
        },
        sponge: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.sponge,
        },
        glass: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.glass,
        },
        lapis_ore: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.lapis_ore,
        },
        lapis_block: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.lapis_block,
        },
        dispenser: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.dispenser,
        },
        sandstone: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.sandstone,
        },
        noteblock: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.noteblock,
        },
        bed: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.bed,
        },
        golden_rail: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.golden_rail,
        },
        detector_rail: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.detector_rail,
        },
        sticky_piston: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.sticky_piston,
        },
        web: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.web,
        },
        tallgrass: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.tallgrass,
        },
        deadbush: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.deadbush,
        },
        piston: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.piston,
        },
        piston_head: packed struct(u8) {
            virtual: packed struct(u4) { short: bool, _: u3 = 0 },
            stored: StoredBlockProperties.piston_head,
        },
        wool: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.wool,
        },
        piston_extension: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.piston_extension,
        },
        yellow_flower: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.yellow_flower,
        },
        red_flower: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.red_flower,
        },
        brown_mushroom: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.brown_mushroom,
        },
        red_mushroom: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.red_mushroom,
        },
        gold_block: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.gold_block,
        },
        iron_block: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.iron_block,
        },
        double_stone_slab: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.double_stone_slab,
        },
        stone_slab: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.stone_slab,
        },
        brick_block: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.brick_block,
        },
        tnt: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.tnt,
        },
        bookshelf: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.bookshelf,
        },
        mossy_cobblestone: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.mossy_cobblestone,
        },
        obsidian: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.obsidian,
        },
        torch: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.torch,
        },

        /// This block is split due to virtual blockstates not fitting into 4 bits.
        /// See fire_upper
        fire: packed struct(u8) { // TODO: Split
            virtual: packed struct(u4) { west: bool, south: bool, north: bool, east: bool },
            stored: StoredBlockProperties.fire,
        },

        mob_spawner: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.mob_spawner,
        },
        oak_stairs: packed struct(u8) {
            const Shape = enum(u3) { straight, inner_left, inner_right, outer_left, outer_right };

            virtual: packed struct(u4) { shape: Shape, _: u1 = 0 },
            stored: StoredBlockProperties.oak_stairs,

            pub fn secondHitbox(self: @This()) Box(f64) {
                const min_y: f64 = if (self.stored.half == .top) 0.0 else 0.5;
                const max_y: f64 = if (self.stored.half == .top) 0.5 else 1.0;
                return switch (self.stored.facing) {
                    .east => switch (self.virtual.shape) {
                        .straight, .inner_left, .inner_right => .{
                            .min = .{ .x = 0.5, .y = min_y, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = max_y, .z = 1.0 },
                        },
                        .outer_left => .{
                            .min = .{ .x = 0.5, .y = min_y, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = max_y, .z = 0.5 },
                        },
                        .outer_right => .{
                            .min = .{ .x = 0.5, .y = min_y, .z = 0.5 },
                            .max = .{ .x = 1.0, .y = max_y, .z = 1.0 },
                        },
                    },
                    .west => switch (self.virtual.shape) {
                        .straight, .inner_left, .inner_right => .{
                            .min = .{ .x = 0.0, .y = min_y, .z = 0.0 },
                            .max = .{ .x = 0.5, .y = max_y, .z = 1.0 },
                        },
                        .outer_left => .{
                            .min = .{ .x = 0.0, .y = min_y, .z = 0.5 },
                            .max = .{ .x = 0.5, .y = max_y, .z = 1.0 },
                        },
                        .outer_right => .{
                            .min = .{ .x = 0.0, .y = min_y, .z = 0.0 },
                            .max = .{ .x = 0.5, .y = max_y, .z = 0.5 },
                        },
                    },
                    .south => switch (self.virtual.shape) {
                        .straight, .inner_left, .inner_right => .{
                            .min = .{ .x = 0.0, .y = min_y, .z = 0.5 },
                            .max = .{ .x = 1.0, .y = max_y, .z = 1.0 },
                        },
                        .outer_left => .{
                            .min = .{ .x = 0.5, .y = min_y, .z = 0.5 },
                            .max = .{ .x = 1.0, .y = max_y, .z = 1.0 },
                        },
                        .outer_right => .{
                            .min = .{ .x = 0.0, .y = min_y, .z = 0.5 },
                            .max = .{ .x = 0.5, .y = max_y, .z = 1.0 },
                        },
                    },
                    .north => switch (self.virtual.shape) {
                        .straight, .inner_left, .inner_right => .{
                            .min = .{ .x = 0.0, .y = min_y, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = max_y, .z = 0.5 },
                        },
                        .outer_left => .{
                            .min = .{ .x = 0.0, .y = min_y, .z = 0.0 },
                            .max = .{ .x = 0.5, .y = max_y, .z = 0.5 },
                        },
                        .outer_right => .{
                            .min = .{ .x = 0.5, .y = min_y, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = max_y, .z = 0.5 },
                        },
                    },
                };
            }

            pub fn innerHitbox(self: @This()) ?Box(f64) {
                const min_y: f64 = if (self.stored.half == .top) 0.0 else 0.5;
                const max_y: f64 = if (self.stored.half == .top) 0.5 else 1.0;
                return switch (self.stored.facing) {
                    .east => switch (self.virtual.shape) {
                        .inner_left => .{
                            .min = .{ .x = 0.0, .y = min_y, .z = 0.0 },
                            .max = .{ .x = 0.5, .y = max_y, .z = 0.5 },
                        },
                        .inner_right => .{
                            .min = .{ .x = 0.0, .y = min_y, .z = 0.5 },
                            .max = .{ .x = 0.5, .y = max_y, .z = 1.0 },
                        },
                        else => null,
                    },
                    .west => switch (self.virtual.shape) {
                        .inner_left => .{
                            .min = .{ .x = 0.5, .y = min_y, .z = 0.5 },
                            .max = .{ .x = 1.0, .y = max_y, .z = 1.0 },
                        },
                        .inner_right => .{
                            .min = .{ .x = 0.5, .y = min_y, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = max_y, .z = 0.5 },
                        },
                        else => null,
                    },
                    .south => switch (self.virtual.shape) {
                        .inner_left => .{
                            .min = .{ .x = 0.5, .y = min_y, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = max_y, .z = 0.5 },
                        },
                        .inner_right => .{
                            .min = .{ .x = 0.0, .y = min_y, .z = 0.0 },
                            .max = .{ .x = 0.5, .y = max_y, .z = 0.5 },
                        },
                        else => null,
                    },
                    .north => switch (self.virtual.shape) {
                        .inner_left => .{
                            .min = .{ .x = 0.0, .y = min_y, .z = 0.5 },
                            .max = .{ .x = 0.5, .y = max_y, .z = 1.0 },
                        },
                        .inner_right => .{
                            .min = .{ .x = 0.5, .y = min_y, .z = 0.5 },
                            .max = .{ .x = 1.0, .y = max_y, .z = 1.0 },
                        },
                        else => null,
                    },
                };
            }

            pub fn isInner(self: @This(), world: World, block_pos: Vector3(i32)) bool {
                switch (self.stored.facing) {
                    .east => {
                        if (getStairState(world, block_pos.east())) |east| {
                            if (self.stored.half == east.stored.half) {
                                return (east.stored.facing != .north or self.alignedStair(world, block_pos.south())) and
                                    (east.stored.facing != .south or self.alignedStair(world, block_pos.north()));
                            }
                        }
                    },
                    .west => {
                        if (getStairState(world, block_pos.west())) |west| {
                            if (self.stored.half == west.stored.half) {
                                return (west.stored.facing != .north or self.alignedStair(world, block_pos.south())) and
                                    (west.stored.facing != .south or self.alignedStair(world, block_pos.north()));
                            }
                        }
                    },
                    .south => {
                        if (getStairState(world, block_pos.south())) |south| {
                            if (self.stored.half == south.stored.half) {
                                return (south.stored.facing != .west or self.alignedStair(world, block_pos.east())) and
                                    (south.stored.facing != .east or self.alignedStair(world, block_pos.west()));
                            }
                        }
                    },
                    .north => {
                        if (getStairState(world, block_pos.north())) |north| {
                            if (self.stored.half == north.stored.half) {
                                return (north.stored.facing != .west or self.alignedStair(world, block_pos.east())) and
                                    (north.stored.facing != .east or self.alignedStair(world, block_pos.west()));
                            }
                        }
                    },
                }
                return true;
            }

            pub fn getInnerStairShape(self: @This(), world: World, block_pos: Vector3(i32)) Shape {
                const top_half = self.stored.half == .top;
                switch (self.stored.facing) {
                    .east => {
                        if (getStairState(world, block_pos.west())) |west| {
                            if (west.stored.half == self.stored.half) {
                                if (west.stored.facing == .north and !self.alignedStair(world, block_pos.north())) {
                                    return if (top_half) .inner_right else .inner_left;
                                } else if (west.stored.facing == .south and !self.alignedStair(world, block_pos.south())) {
                                    return if (top_half) .inner_left else .inner_right;
                                }
                            }
                        }
                    },
                    .west => {
                        if (getStairState(world, block_pos.east())) |east| {
                            if (east.stored.half == self.stored.half) {
                                if (east.stored.facing == .north and !self.alignedStair(world, block_pos.north())) {
                                    return if (top_half) .inner_left else .inner_right;
                                } else if (east.stored.facing == .south and !self.alignedStair(world, block_pos.south())) {
                                    return if (top_half) .inner_right else .inner_left;
                                }
                            }
                        }
                    },
                    .south => {
                        if (getStairState(world, block_pos.north())) |north| {
                            if (north.stored.half == self.stored.half) {
                                if (north.stored.facing == .west and !self.alignedStair(world, block_pos.west())) {
                                    return if (top_half) .inner_left else .inner_right;
                                } else if (north.stored.facing == .east and !self.alignedStair(world, block_pos.east())) {
                                    return if (top_half) .inner_right else .inner_left;
                                }
                            }
                        }
                    },
                    .north => {
                        if (getStairState(world, block_pos.south())) |south| {
                            if (south.stored.half == self.stored.half) {
                                if (south.stored.facing == .west and !self.alignedStair(world, block_pos.west())) {
                                    return if (top_half) .inner_right else .inner_left;
                                } else if (south.stored.facing == .east and !self.alignedStair(world, block_pos.east())) {
                                    return if (top_half) .inner_left else .inner_right;
                                }
                            }
                        }
                    },
                }
                return .straight;
            }

            pub fn getOuterStairShape(self: @This(), world: World, block_pos: Vector3(i32)) Shape {
                const top_half = self.stored.half == .top;

                switch (self.stored.facing) {
                    .east => {
                        if (getStairState(world, block_pos.east())) |east| {
                            if (east.stored.half == self.stored.half) {
                                if (east.stored.facing == .north and !self.alignedStair(world, block_pos.south())) {
                                    return if (top_half) .outer_right else .outer_left;
                                } else if (east.stored.facing == .south and !self.alignedStair(world, block_pos.north())) {
                                    return if (top_half) .outer_left else .outer_right;
                                }
                            }
                        }
                    },
                    .west => {
                        if (getStairState(world, block_pos.west())) |west| {
                            if (west.stored.half == self.stored.half) {
                                if (west.stored.facing == .north and !self.alignedStair(world, block_pos.south())) {
                                    return if (top_half) .outer_left else .outer_right;
                                } else if (west.stored.facing == .south and !self.alignedStair(world, block_pos.north())) {
                                    return if (top_half) .outer_right else .outer_left;
                                }
                            }
                        }
                    },
                    .south => {
                        if (getStairState(world, block_pos.south())) |south| {
                            if (south.stored.half == self.stored.half) {
                                if (south.stored.facing == .west and !self.alignedStair(world, block_pos.east())) {
                                    return if (top_half) .outer_left else .outer_right;
                                } else if (south.stored.facing == .east and !self.alignedStair(world, block_pos.west())) {
                                    return if (top_half) .outer_right else .outer_left;
                                }
                            }
                        }
                    },
                    .north => {
                        if (getStairState(world, block_pos.north())) |north| {
                            if (north.stored.half == self.stored.half) {
                                if (north.stored.facing == .west and !self.alignedStair(world, block_pos.east())) {
                                    return if (top_half) .outer_right else .outer_left;
                                } else if (north.stored.facing == .east and !self.alignedStair(world, block_pos.north())) {
                                    return if (top_half) .outer_left else .outer_right;
                                }
                            }
                        }
                    },
                }
                return .straight;
            }

            pub fn getStairState(world: World, block_pos: Vector3(i32)) ?@This() {
                const state = world.getBlockState(block_pos);
                if (isStair(state.block)) return state.properties.oak_stairs;
                return null;
            }

            pub fn alignedStair(self: @This(), world: World, block_pos: Vector3(i32)) bool {
                const other = getStairState(world, block_pos) orelse return false;
                return self.stored.facing == other.stored.facing and self.stored.half == other.stored.half;
            }

            pub fn isStair(block: ConcreteBlock) bool {
                return block == .oak_stairs or
                    block == .stone_stairs or
                    block == .brick_stairs or
                    block == .stone_brick_stairs or
                    block == .nether_brick_stairs or
                    block == .sandstone_stairs or
                    block == .spruce_stairs or
                    block == .birch_stairs or
                    block == .jungle_stairs or
                    block == .quartz_stairs or
                    block == .acacia_stairs or
                    block == .dark_oak_stairs or
                    block == .red_sandstone_stairs;
            }
        },
        chest: packed struct(u8) {
            virtual: packed struct(u4) { connection: enum(u3) { north, south, west, east, none }, _: u1 = 0 },
            stored: StoredBlockProperties.chest,
        },

        /// This block is split due to virtual blockstates not fitting into 4 bits.
        /// See the following:
        ///                           redstone_wire_none_flat,  redstone_wire_none_upper,
        /// redstone_wire_flat_none,  redstone_wire_flat_flat,  redstone_wire_flat_upper,
        /// redstone_wire_upper_none, redstone_wire_upper_flat, redstone_wire_upper_upper
        redstone_wire: packed struct(u8) {
            virtual: packed struct(u4) { north: enum { none, flat, upper }, east: enum { none, flat, upper } },
            stored: StoredBlockProperties.redstone_wire,
        },

        diamond_ore: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.diamond_ore,
        },
        diamond_block: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.diamond_block,
        },
        crafting_table: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.crafting_table,
        },
        wheat: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.wheat,
        },
        farmland: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.farmland,
        },
        furnace: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.furnace,
        },
        lit_furnace: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.lit_furnace,
        },
        standing_sign: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.standing_sign,
        },
        wooden_door: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.wooden_door,
        },
        ladder: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.ladder,
        },
        rail: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.rail,
        },
        stone_stairs: packed struct(u8) {
            virtual: packed struct(u4) { shape: enum(u3) { straight, inner_left, inner_right, outer_left, outer_right }, _: u1 = 0 },
            stored: StoredBlockProperties.stone_stairs,
        },
        wall_sign: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.wall_sign,
        },
        lever: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.lever,
        },
        stone_pressure_plate: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.stone_pressure_plate,
        },
        iron_door: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.iron_door,
        },
        wooden_pressure_plate: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.wooden_pressure_plate,
        },
        redstone_ore: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.redstone_ore,
        },
        lit_redstone_ore: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.lit_redstone_ore,
        },
        unlit_redstone_torch: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.unlit_redstone_torch,
        },
        redstone_torch: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.redstone_torch,
        },
        stone_button: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.stone_button,
        },
        snow_layer: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.snow_layer,
        },
        ice: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.ice,
        },
        snow: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.snow,
        },
        cactus: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.cactus,
        },
        clay: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.clay,
        },
        reeds: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.reeds,
        },
        jukebox: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.jukebox,
        },
        fence: packed struct(u8) {
            virtual: packed struct(u4) { west: bool, south: bool, north: bool, east: bool },
            stored: StoredBlockProperties.fence,

            pub fn shouldConnectTo(_: @This(), block: ConcreteBlock) bool {
                return EnumBoolArray(ConcreteBlock).init(@import("./wood_fence_connections.zig").@"export").get(block);
            }
        },
        pumpkin: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.pumpkin,
        },
        netherrack: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.netherrack,
        },
        soul_sand: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.soul_sand,
        },
        glowstone: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.glowstone,
        },
        portal: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.portal,
        },
        lit_pumpkin: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.lit_pumpkin,
        },
        cake: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.cake,
        },
        unpowered_repeater: packed struct(u8) {
            virtual: packed struct(u4) { locked: bool, _: u3 = 0 },
            stored: StoredBlockProperties.unpowered_repeater,
        },
        powered_repeater: packed struct(u8) {
            virtual: packed struct(u4) { locked: bool, _: u3 = 0 },
            stored: StoredBlockProperties.powered_repeater,
        },
        stained_glass: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.stained_glass,
        },
        trapdoor: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.trapdoor,
        },
        monster_egg: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.monster_egg,
        },
        stonebrick: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.stonebrick,
        },
        brown_mushroom_block: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.brown_mushroom_block,
        },
        red_mushroom_block: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.red_mushroom_block,
        },
        iron_bars: packed struct(u8) {
            virtual: packed struct(u4) { west: bool, south: bool, north: bool, east: bool },
            stored: StoredBlockProperties.iron_bars,
        },
        glass_pane: packed struct(u8) {
            virtual: packed struct(u4) { west: bool, south: bool, north: bool, east: bool },
            stored: StoredBlockProperties.glass_pane,
        },
        melon_block: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.melon_block,
        },
        pumpkin_stem: packed struct(u8) {
            virtual: packed struct(u4) { facing: enum(u3) { up, north, south, west, east }, _: u1 = 0 },
            stored: StoredBlockProperties.pumpkin_stem,
        },
        melon_stem: packed struct(u8) {
            virtual: packed struct(u4) { facing: enum(u3) { up, north, south, west, east }, _: u1 = 0 },
            stored: StoredBlockProperties.melon_stem,
        },
        vine: packed struct(u8) {
            virtual: packed struct(u4) { up: bool, _: u3 = 0 },
            stored: StoredBlockProperties.vine,
        },
        fence_gate: packed struct(u8) {
            virtual: packed struct(u4) { in_wall: bool, _: u3 = 0 },
            stored: StoredBlockProperties.fence_gate,
        },
        brick_stairs: packed struct(u8) {
            virtual: packed struct(u4) { shape: enum(u3) { straight, inner_left, inner_right, outer_left, outer_right }, _: u1 = 0 },
            stored: StoredBlockProperties.brick_stairs,
        },
        stone_brick_stairs: packed struct(u8) {
            virtual: packed struct(u4) { shape: enum(u3) { straight, inner_left, inner_right, outer_left, outer_right }, _: u1 = 0 },
            stored: StoredBlockProperties.stone_brick_stairs,
        },
        mycelium: packed struct(u8) {
            virtual: packed struct(u4) { snowy: bool, _: u3 = 0 },
            stored: StoredBlockProperties.mycelium,
        },
        waterlily: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.waterlily,
        },
        nether_brick: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.nether_brick,
        },
        nether_brick_fence: packed struct(u8) {
            virtual: packed struct(u4) { west: bool, south: bool, north: bool, east: bool },
            stored: StoredBlockProperties.nether_brick_fence,

            pub fn shouldConnectTo(_: @This(), block: ConcreteBlock) bool {
                return EnumBoolArray(ConcreteBlock).init(@import("./nether_brick_fence_connections.zig").@"export").get(block);
            }
        },
        nether_brick_stairs: packed struct(u8) {
            virtual: packed struct(u4) { shape: enum(u3) { straight, inner_left, inner_right, outer_left, outer_right }, _: u1 = 0 },
            stored: StoredBlockProperties.nether_brick_stairs,
        },
        nether_wart: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.nether_wart,
        },
        enchanting_table: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.enchanting_table,
        },
        brewing_stand: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.brewing_stand,
        },
        cauldron: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.cauldron,
        },
        end_portal: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.end_portal,
        },
        end_portal_frame: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.end_portal_frame,
        },
        end_stone: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.end_stone,
        },
        dragon_egg: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.dragon_egg,
        },
        redstone_lamp: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.redstone_lamp,
        },
        lit_redstone_lamp: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.lit_redstone_lamp,
        },
        double_wooden_slab: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.double_wooden_slab,
        },
        wooden_slab: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.wooden_slab,
        },
        cocoa: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.cocoa,
        },
        sandstone_stairs: packed struct(u8) {
            virtual: packed struct(u4) { shape: enum(u3) { straight, inner_left, inner_right, outer_left, outer_right }, _: u1 = 0 },
            stored: StoredBlockProperties.sandstone_stairs,
        },
        emerald_ore: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.emerald_ore,
        },
        ender_chest: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.ender_chest,
        },
        tripwire_hook: packed struct(u8) {
            virtual: packed struct(u4) { suspended: bool, _: u3 = 0 },
            stored: StoredBlockProperties.tripwire_hook,
        },
        tripwire: packed struct(u8) {
            virtual: packed struct(u4) { west: bool, south: bool, north: bool, east: bool },
            stored: StoredBlockProperties.tripwire,
        },
        emerald_block: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.emerald_block,
        },
        spruce_stairs: packed struct(u8) {
            virtual: packed struct(u4) { shape: enum(u3) { straight, inner_left, inner_right, outer_left, outer_right }, _: u1 = 0 },
            stored: StoredBlockProperties.spruce_stairs,
        },
        birch_stairs: packed struct(u8) {
            virtual: packed struct(u4) { shape: enum(u3) { straight, inner_left, inner_right, outer_left, outer_right }, _: u1 = 0 },
            stored: StoredBlockProperties.birch_stairs,
        },
        jungle_stairs: packed struct(u8) {
            virtual: packed struct(u4) { shape: enum(u3) { straight, inner_left, inner_right, outer_left, outer_right }, _: u1 = 0 },
            stored: StoredBlockProperties.jungle_stairs,
        },
        command_block: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.command_block,
        },
        beacon: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.beacon,
        },

        /// This block is split due to virtual blockstates not fitting into 4 bits.
        /// See cobblestone_wall_upper
        cobblestone_wall: packed struct(u8) {
            virtual: packed struct(u4) { west: bool, south: bool, north: bool, east: bool },
            stored: StoredBlockProperties.cobblestone_wall,
        },

        /// This block is split due to virtual blockstates not fitting into 4 bits.
        /// See flower_pot_2
        flower_pot: packed struct(u8) {
            virtual: packed struct(u4) { contents: enum { empty, poppy, blue_orchid, allium, houstonia, red_tulip, orange_tulip, white_tulip, pink_tulip, oxeye_daisy, dandelion, oak_sapling, spruce_sapling, birch_sapling, jungle_sapling, acacia_sapling } },
            stored: StoredBlockProperties.flower_pot,
        },

        carrots: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.carrots,
        },
        potatoes: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.potatoes,
        },
        wooden_button: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.wooden_button,
        },
        skull: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.skull,
        },
        anvil: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.anvil,
        },
        trapped_chest: packed struct(u8) {
            virtual: packed struct(u4) { connection: enum(u3) { north, south, west, east, none }, _: u1 = 0 },
            stored: StoredBlockProperties.trapped_chest,
        },
        light_weighted_pressure_plate: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.light_weighted_pressure_plate,
        },
        heavy_weighted_pressure_plate: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.heavy_weighted_pressure_plate,
        },
        unpowered_comparator: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.unpowered_comparator,
        },
        powered_comparator: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.powered_comparator,
        },
        daylight_detector: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.daylight_detector,
        },
        redstone_block: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.redstone_block,
        },
        quartz_ore: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.quartz_ore,
        },
        hopper: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.hopper,
        },
        quartz_block: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.quartz_block,
        },
        quartz_stairs: packed struct(u8) {
            virtual: packed struct(u4) { shape: enum(u3) { straight, inner_left, inner_right, outer_left, outer_right }, _: u1 = 0 },
            stored: StoredBlockProperties.quartz_stairs,
        },
        activator_rail: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.activator_rail,
        },
        dropper: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.dropper,
        },
        stained_hardened_clay: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.stained_hardened_clay,
        },
        stained_glass_pane: packed struct(u8) {
            virtual: packed struct(u4) { west: bool, south: bool, north: bool, east: bool },
            stored: StoredBlockProperties.stained_glass_pane,
        },
        leaves2: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.leaves2,
        },
        log2: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.log2,
        },
        acacia_stairs: packed struct(u8) {
            virtual: packed struct(u4) { shape: enum(u3) { straight, inner_left, inner_right, outer_left, outer_right }, _: u1 = 0 },
            stored: StoredBlockProperties.acacia_stairs,
        },
        dark_oak_stairs: packed struct(u8) {
            virtual: packed struct(u4) { shape: enum(u3) { straight, inner_left, inner_right, outer_left, outer_right }, _: u1 = 0 },
            stored: StoredBlockProperties.dark_oak_stairs,
        },
        slime: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.slime,
        },
        barrier: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.barrier,
        },
        iron_trapdoor: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.iron_trapdoor,
        },
        prismarine: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.prismarine,
        },
        sea_lantern: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.sea_lantern,
        },
        hay_block: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.hay_block,
        },
        carpet: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.carpet,
        },
        hardened_clay: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.hardened_clay,
        },
        coal_block: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.coal_block,
        },
        packed_ice: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.packed_ice,
        },
        double_plant: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.double_plant,
        },
        standing_banner: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.standing_banner,
        },
        wall_banner: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.wall_banner,
        },
        daylight_detector_inverted: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.daylight_detector_inverted,
        },
        red_sandstone: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.red_sandstone,
        },
        red_sandstone_stairs: packed struct(u8) {
            virtual: packed struct(u4) { shape: enum(u3) { straight, inner_left, inner_right, outer_left, outer_right }, _: u1 = 0 },
            stored: StoredBlockProperties.red_sandstone_stairs,
        },
        double_stone_slab2: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.double_stone_slab2,
        },
        stone_slab2: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.stone_slab2,
        },
        spruce_fence_gate: packed struct(u8) {
            virtual: packed struct(u4) { in_wall: bool, _: u3 = 0 },
            stored: StoredBlockProperties.spruce_fence_gate,
        },
        birch_fence_gate: packed struct(u8) {
            virtual: packed struct(u4) { in_wall: bool, _: u3 = 0 },
            stored: StoredBlockProperties.birch_fence_gate,
        },
        jungle_fence_gate: packed struct(u8) {
            virtual: packed struct(u4) { in_wall: bool, _: u3 = 0 },
            stored: StoredBlockProperties.jungle_fence_gate,
        },
        dark_oak_fence_gate: packed struct(u8) {
            virtual: packed struct(u4) { in_wall: bool, _: u3 = 0 },
            stored: StoredBlockProperties.dark_oak_fence_gate,
        },
        acacia_fence_gate: packed struct(u8) {
            virtual: packed struct(u4) { in_wall: bool, _: u3 = 0 },
            stored: StoredBlockProperties.acacia_fence_gate,
        },
        spruce_fence: packed struct(u8) {
            virtual: packed struct(u4) { west: bool, south: bool, north: bool, east: bool },
            stored: StoredBlockProperties.spruce_fence,
        },
        birch_fence: packed struct(u8) {
            virtual: packed struct(u4) { west: bool, south: bool, north: bool, east: bool },
            stored: StoredBlockProperties.birch_fence,
        },
        jungle_fence: packed struct(u8) {
            virtual: packed struct(u4) { west: bool, south: bool, north: bool, east: bool },
            stored: StoredBlockProperties.jungle_fence,
        },
        dark_oak_fence: packed struct(u8) {
            virtual: packed struct(u4) { west: bool, south: bool, north: bool, east: bool },
            stored: StoredBlockProperties.dark_oak_fence,
        },
        acacia_fence: packed struct(u8) {
            virtual: packed struct(u4) { west: bool, south: bool, north: bool, east: bool },
            stored: StoredBlockProperties.acacia_fence,
        },
        spruce_door: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.spruce_door,
        },
        birch_door: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.birch_door,
        },
        jungle_door: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.jungle_door,
        },
        acacia_door: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.acacia_door,
        },
        dark_oak_door: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.dark_oak_door,
        },

        fire_upper: packed struct(u8) {
            virtual: packed struct(u4) { _: u4 = 0 } = .{},
            stored: StoredBlockProperties.fire,
        },

        redstone_wire_none_flat: packed struct(u8) {
            virtual: packed struct(u4) { north: enum { none, flat, upper }, east: enum { none, flat, upper } },
            stored: StoredBlockProperties.redstone_wire,
        },
        redstone_wire_none_upper: packed struct(u8) {
            virtual: packed struct(u4) { north: enum { none, flat, upper }, east: enum { none, flat, upper } },
            stored: StoredBlockProperties.redstone_wire,
        },
        redstone_wire_flat_none: packed struct(u8) {
            virtual: packed struct(u4) { north: enum { none, flat, upper }, east: enum { none, flat, upper } },
            stored: StoredBlockProperties.redstone_wire,
        },
        redstone_wire_flat_flat: packed struct(u8) {
            virtual: packed struct(u4) { north: enum { none, flat, upper }, east: enum { none, flat, upper } },
            stored: StoredBlockProperties.redstone_wire,
        },
        redstone_wire_flat_upper: packed struct(u8) {
            virtual: packed struct(u4) { north: enum { none, flat, upper }, east: enum { none, flat, upper } },
            stored: StoredBlockProperties.redstone_wire,
        },
        redstone_wire_upper_none: packed struct(u8) {
            virtual: packed struct(u4) { north: enum { none, flat, upper }, east: enum { none, flat, upper } },
            stored: StoredBlockProperties.redstone_wire,
        },
        redstone_wire_upper_flat: packed struct(u8) {
            virtual: packed struct(u4) { north: enum { none, flat, upper }, east: enum { none, flat, upper } },
            stored: StoredBlockProperties.redstone_wire,
        },
        redstone_wire_upper_upper: packed struct(u8) {
            virtual: packed struct(u4) { north: enum { none, flat, upper }, east: enum { none, flat, upper } },
            stored: StoredBlockProperties.redstone_wire,
        },

        cobblestone_wall_upper: packed struct(u8) {
            virtual: packed struct(u4) { west: bool, south: bool, north: bool, east: bool },
            stored: StoredBlockProperties.cobblestone_wall,
        },

        flower_pot_2: packed struct(u8) {
            virtual: packed struct(u4) { contents: enum { dark_oak_sapling, mushroom_red, mushroom_brown, dead_bush, fern, cactus }, _: u1 = 0 },
            stored: StoredBlockProperties.flower_pot,
        },
    };

    block: ConcreteBlock,
    properties: BlockProperties,

    pub fn update(self: *@This(), world: World, block_pos: Vector3(i32)) void {
        switch (self.block) {
            .grass,
            .dirt,
            => {
                const up = world.getBlock(block_pos.up());
                self.properties.grass.virtual.snowy = up == .snow or up == .snow_layer;
            },
            // .dirt,
            .piston_head => {},
            .fire => {},
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
            => {
                const stairs = &self.properties.oak_stairs;
                if (stairs.isInner(world, block_pos)) {
                    stairs.virtual.shape = stairs.getInnerStairShape(world, block_pos);
                } else {
                    stairs.virtual.shape = stairs.getOuterStairShape(world, block_pos);
                }
            },
            .chest => {},
            .redstone_wire => {},
            // .stone_stairs,
            .fence,
            .spruce_fence,
            .birch_fence,
            .jungle_fence,
            .dark_oak_fence,
            .acacia_fence,
            => {
                self.properties.fence.virtual = .{
                    .west = self.properties.fence.shouldConnectTo(world.getBlock(block_pos.west())),
                    .south = self.properties.fence.shouldConnectTo(world.getBlock(block_pos.south())),
                    .north = self.properties.fence.shouldConnectTo(world.getBlock(block_pos.north())),
                    .east = self.properties.fence.shouldConnectTo(world.getBlock(block_pos.east())),
                };
            },
            .unpowered_repeater => {},
            .powered_repeater => {},
            .iron_bars => {},
            .glass_pane => {},
            .pumpkin_stem => {},
            .melon_stem => {},
            .vine => {},
            .fence_gate => {},
            // .brick_stairs,
            // .stone_brick_stairs,
            .mycelium => {},
            .nether_brick_fence => {
                self.payloadPtr(.nether_brick_fence).virtual = .{
                    .west = self.payload(.nether_brick_fence).shouldConnectTo(world.getBlock(block_pos.west())),
                    .south = self.payload(.nether_brick_fence).shouldConnectTo(world.getBlock(block_pos.south())),
                    .north = self.payload(.nether_brick_fence).shouldConnectTo(world.getBlock(block_pos.north())),
                    .east = self.payload(.nether_brick_fence).shouldConnectTo(world.getBlock(block_pos.east())),
                };
            },
            // .nether_brick_stairs,
            // .sandstone_stairs,
            .tripwire_hook => {},
            .tripwire => {},
            // .spruce_stairs,
            // .birch_stairs,
            // .jungle_stairs,
            .cobblestone_wall => {},
            .flower_pot => {},
            .trapped_chest => {},
            // .quartz_stairs,
            .stained_glass_pane => {},
            // .acacia_stairs,
            // .dark_oak_stairs,
            // .red_sandstone_stairs,
            .spruce_fence_gate => {},
            .birch_fence_gate => {},
            .jungle_fence_gate => {},
            .dark_oak_fence_gate => {},
            .acacia_fence_gate => {},

            // .spruce_fence => {},
            // .birch_fence => {},
            // .jungle_fence => {},
            // .dark_oak_fence => {},
            // .acacia_fence => {},

            else => {},
        }
    }

    pub fn payload(self: @This(), comptime block: ConcreteBlock) @TypeOf(@field(self.properties, @tagName(block))) {
        std.debug.assert(self.block == block);
        return @field(self.properties, @tagName(block));
    }
    pub fn payloadPtr(self: *@This(), comptime block: ConcreteBlock) *@TypeOf(@field(self.properties, @tagName(block))) {
        std.debug.assert(self.block == block);
        return &@field(self.properties, @tagName(block));
    }

    pub fn getRaytraceHitbox(self: @This()) [3]?Box(f64) {
        const CUBE: Box(f64) = .{
            .min = .{ .x = 0, .y = 0, .z = 0 },
            .max = .{ .x = 1, .y = 1, .z = 1 },
        };
        const NONE: [3]?Box(f64) = .{ null, null, null };
        const FULL: [3]?Box(f64) = .{ CUBE, null, null };
        return switch (self.block) {
            .air => NONE,
            .stone => FULL,
            .grass => FULL,
            .dirt => FULL,
            .cobblestone => FULL,
            .planks => FULL,
            .sapling => .{
                .{
                    .min = .{ .x = 0.1, .y = 0.1, .z = 0.1 },
                    .max = .{ .x = 0.9, .y = 0.8, .z = 0.9 },
                },
                null,
                null,
            },
            .bedrock => FULL,
            .flowing_water => FULL, // TODO
            .water => FULL, // TODO
            .flowing_lava => FULL, // TODO
            .lava => FULL, // TODO
            .sand => FULL,
            .gravel => FULL,
            .gold_ore => FULL,
            .iron_ore => FULL,
            .coal_ore => FULL,
            .log => FULL,
            .leaves => FULL,
            .sponge => FULL,
            .glass => FULL,
            .lapis_ore => FULL,
            .lapis_block => FULL,
            .dispenser => FULL,
            .sandstone => FULL,
            .noteblock => FULL,
            .bed => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.5625, .z = 1.0 },
                },
                null,
                null,
            },
            .golden_rail => {
                const golden_rail = self.payload(.golden_rail);
                return .{
                    .{
                        .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                        .max = .{ .x = 1.0, .y = if (golden_rail.stored.shape == .ascending_east or golden_rail.stored.shape == .ascending_north or golden_rail.stored.shape == .ascending_south or golden_rail.stored.shape == .ascending_west) 0.625 else 0.125, .z = 1.0 },
                    },
                    null,
                    null,
                };
            },
            .detector_rail => {
                const detector_rail = self.payload(.detector_rail);
                return .{
                    .{
                        .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                        .max = .{ .x = 1.0, .y = if (detector_rail.stored.shape == .ascending_east or detector_rail.stored.shape == .ascending_north or detector_rail.stored.shape == .ascending_south or detector_rail.stored.shape == .ascending_west) 0.625 else 0.125, .z = 1.0 },
                    },
                    null,
                    null,
                };
            },
            .sticky_piston => {
                const sticky_piston = self.payload(.sticky_piston);
                return .{
                    if (sticky_piston.stored.extended) switch (sticky_piston.stored.facing) {
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
                    } else CUBE,
                    null,
                    null,
                };
            },
            .web => FULL,
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
                const piston = self.payload(.piston);
                return .{
                    if (piston.stored.extended) switch (piston.stored.facing) {
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
                    } else CUBE,
                    null,
                    null,
                };
            },
            .piston_head => {
                const piston_head = self.payload(.piston_head);
                return .{
                    switch (piston_head.stored.facing) {
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
            .wool => FULL,
            .piston_extension => NONE,
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
            .gold_block => FULL,
            .iron_block => FULL,
            .double_stone_slab => FULL,
            .stone_slab => {
                const stone_slab = self.payload(.stone_slab);
                return .{
                    .{
                        .min = .{ .x = 0, .y = if (stone_slab.stored.half == .top) 0.5 else 0.0, .z = 0 },
                        .max = .{ .x = 1, .y = if (stone_slab.stored.half == .top) 1.0 else 0.5, .z = 1 },
                    },
                    null,
                    null,
                };
            },
            .brick_block => FULL,
            .tnt => FULL,
            .bookshelf => FULL,
            .mossy_cobblestone => FULL,
            .obsidian => FULL,
            .torch => {
                const torch = self.payload(.torch);
                return .{
                    blk: {
                        const wall_width: f32 = 0.15;
                        const floor_width: f32 = 0.1;
                        break :blk switch (torch.stored.facing) {
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

            .fire => NONE,

            .mob_spawner => FULL,
            .oak_stairs => {
                const stair = self.properties.oak_stairs;
                return .{
                    if (stair.stored.half == .top) .{
                        .min = .{ .x = 0.0, .y = 0.5, .z = 0.0 },
                        .max = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
                    } else .{
                        .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                        .max = .{ .x = 1.0, .y = 0.5, .z = 1.0 },
                    },
                    stair.secondHitbox(),
                    stair.innerHitbox(),
                };
            }, // TODO
            .chest => {
                const chest = self.payload(.chest);
                return .{
                    switch (chest.virtual.connection) {
                        .north => .{
                            .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 0.9375, .y = 0.875, .z = 0.9375 },
                        },
                        .south => .{
                            .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                            .max = .{ .x = 0.9375, .y = 0.875, .z = 1.0 },
                        },
                        .west => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0625 },
                            .max = .{ .x = 0.9375, .y = 0.875, .z = 0.9375 },
                        },
                        .east => .{
                            .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                            .max = .{ .x = 1.0, .y = 0.875, .z = 0.9375 },
                        },
                        .none => .{
                            .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                            .max = .{ .x = 0.9375, .y = 0.875, .z = 0.9375 },
                        },
                    },
                    null,
                    null,
                };
            },

            .redstone_wire => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.0625, .z = 1.0 },
                },
                null,
                null,
            },

            .diamond_ore => FULL,
            .diamond_block => FULL,
            .crafting_table => FULL,
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
            .furnace => FULL,
            .lit_furnace => FULL,
            .standing_sign => .{
                .{
                    .min = .{ .x = 0.25, .y = 0.0, .z = 0.25 },
                    .max = .{ .x = 0.75, .y = 1.0, .z = 0.75 },
                },
                null,
                null,
            },
            .wooden_door => FULL, // TODO
            .ladder => {
                const ladder = self.payload(.ladder);
                return .{
                    switch (ladder.stored.facing) {
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
                            .max = .{ .x = 1.0, .y = 0.125, .z = 1.0 },
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
                        .max = .{ .x = 1.0, .y = if (rail.stored.shape == .ascending_east or rail.stored.shape == .ascending_north or rail.stored.shape == .ascending_south or rail.stored.shape == .ascending_west) 0.625 else 0.125, .z = 1.0 },
                    },
                    null,
                    null,
                };
            },
            .stone_stairs => FULL, // TODO
            .wall_sign => {
                const wall_sign = self.payload(.wall_sign);
                return .{
                    switch (wall_sign.stored.facing) {
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
                    switch (lever.stored.facing) {
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
                        .max = .{ .x = 0.9375, .y = if (stone_pressure_plate.stored.powered) 0.03125 else 0.0625, .z = 0.9375 },
                    },
                    null,
                    null,
                };
            },
            .iron_door => FULL, // TODO
            .wooden_pressure_plate => {
                const wooden_pressure_plate = self.payload(.wooden_pressure_plate);
                return .{
                    .{
                        .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                        .max = .{ .x = 0.9375, .y = if (wooden_pressure_plate.stored.powered) 0.03125 else 0.0625, .z = 0.9375 },
                    },
                    null,
                    null,
                };
            },
            .redstone_ore => FULL,
            .lit_redstone_ore => FULL,
            .unlit_redstone_torch => {
                const unlit_redstone_torch = self.payload(.unlit_redstone_torch);
                return .{
                    blk: {
                        const wall_width: f32 = 0.15;
                        const floor_width: f32 = 0.1;
                        break :blk switch (unlit_redstone_torch.stored.facing) {
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
                        break :blk switch (redstone_torch.stored.facing) {
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
                        const button_depth = @as(f32, @floatFromInt(@intFromBool(stone_button.stored.powered))) / 16.0;
                        break :blk switch (stone_button.stored.facing) {
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
                        .max = .{ .x = 1.0, .y = @as(f32, @floatFromInt(snow_layer.stored.layers + 1)) / 8.0, .z = 1.0 },
                    },
                    null,
                    null,
                };
            },
            .ice => FULL,
            .snow => FULL,
            .cactus => FULL,
            .clay => FULL,
            .reeds => .{
                .{
                    .min = .{ .x = 0.125, .y = 0.0, .z = 0.125 },
                    .max = .{ .x = 0.875, .y = 1.0, .z = 0.875 },
                },
                null,
                null,
            },
            .jukebox => FULL,
            .fence, .nether_brick_fence, .spruce_fence, .birch_fence, .jungle_fence, .dark_oak_fence, .acacia_fence => {
                const fence = self.properties.fence.virtual;
                return .{
                    .{
                        .min = .{ .x = if (fence.west) 0.0 else 0.375, .y = 0.0, .z = if (fence.north) 0.0 else 0.375 },
                        .max = .{ .x = if (fence.east) 1.0 else 0.625, .y = 1.0, .z = if (fence.south) 1.0 else 0.625 },
                    },
                    null,
                    null,
                };
            },
            .pumpkin => FULL,
            .netherrack => FULL,
            .soul_sand => FULL,
            .glowstone => FULL,
            .portal => {
                const portal = self.payload(.portal);
                return .{
                    switch (portal.stored.axis) {
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
            .lit_pumpkin => FULL,
            .cake => {
                const cake = self.payload(.cake);
                return .{
                    .{
                        .min = .{ .x = @as(f32, @floatFromInt(cake.stored.bites * 2 + 1)) / 16.0, .y = 0.0, .z = 0.0625 },
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
            .stained_glass => FULL,
            .trapdoor => FULL, // TODO
            .monster_egg => FULL,
            .stonebrick => FULL,
            .brown_mushroom_block => FULL,
            .red_mushroom_block => FULL,
            .iron_bars => {
                const iron_bars = self.payload(.iron_bars);
                return .{
                    blk: {
                        const any = iron_bars.virtual.north or iron_bars.virtual.south or iron_bars.virtual.west or iron_bars.virtual.east;
                        break :blk if (!any) CUBE else .{
                            .min = .{ .x = if (iron_bars.virtual.west) @as(f32, 0.0) else @as(f32, 0.4375), .y = 0.0, .z = if (iron_bars.virtual.north) @as(f32, 0.0) else @as(f32, 0.4375) },
                            .max = .{ .x = if (iron_bars.virtual.east) @as(f32, 1.0) else @as(f32, 0.5625), .y = 1.0, .z = if (iron_bars.virtual.south) @as(f32, 1.0) else @as(f32, 0.5625) },
                        };
                    },
                    null,
                    null,
                };
            },
            .glass_pane => {
                const glass_pane = self.payload(.glass_pane);
                return .{
                    blk: {
                        const any = glass_pane.virtual.north or glass_pane.virtual.south or glass_pane.virtual.west or glass_pane.virtual.east;
                        break :blk if (!any) CUBE else .{
                            .min = .{ .x = if (glass_pane.virtual.west) @as(f32, 0.0) else @as(f32, 0.4375), .y = 0.0, .z = if (glass_pane.virtual.north) @as(f32, 0.0) else @as(f32, 0.4375) },
                            .max = .{ .x = if (glass_pane.virtual.east) @as(f32, 1.0) else @as(f32, 0.5625), .y = 1.0, .z = if (glass_pane.virtual.south) @as(f32, 1.0) else @as(f32, 0.5625) },
                        };
                    },
                    null,
                    null,
                };
            },
            .melon_block => FULL,
            .pumpkin_stem => {
                const pumpkin_stem = self.payload(.pumpkin_stem);
                return .{
                    .{
                        .min = .{ .x = 0.375, .y = 0.0, .z = 0.375 },
                        .max = .{ .x = 0.625, .y = @as(f32, @floatFromInt(pumpkin_stem.stored.age * 2 + 2)) / 16.0, .z = 0.625 },
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
                        .max = .{ .x = 0.625, .y = @as(f32, @floatFromInt(melon_stem.stored.age * 2 + 2)) / 16.0, .z = 0.625 },
                    },
                    null,
                    null,
                };
            },
            .vine => FULL, // TODO
            .fence_gate => {
                const fence_gate = self.payload(.fence_gate);
                return .{
                    switch (fence_gate.stored.facing) {
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
            .brick_stairs => FULL, // TODO
            .stone_brick_stairs => FULL, // TODO
            .mycelium => FULL,
            .waterlily => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.375 },
                    .max = .{ .x = 1.0, .y = 0.015625, .z = 0.625 },
                },
                null,
                null,
            },
            .nether_brick => FULL,
            // .nether_brick_fence,
            .nether_brick_stairs => FULL, // TODO
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
            .cauldron => FULL,
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
            .end_stone => FULL,
            .dragon_egg => .{
                .{
                    .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                    .max = .{ .x = 0.9375, .y = 1.0, .z = 0.9375 },
                },
                null,
                null,
            },
            .redstone_lamp => FULL,
            .lit_redstone_lamp => FULL,
            .double_wooden_slab => FULL,
            .wooden_slab => {
                const wooden_slab = self.payload(.wooden_slab);
                return .{
                    .{
                        .min = .{ .x = 0, .y = if (wooden_slab.stored.half == .top) 0.5 else 0.0, .z = 0 },
                        .max = .{ .x = 1, .y = if (wooden_slab.stored.half == .top) 1.0 else 0.5, .z = 1 },
                    },
                    null,
                    null,
                };
            },
            .cocoa => {
                const cocoa = self.payload(.cocoa);
                return .{
                    blk: {
                        const width = @as(f32, @floatFromInt(4 + @as(u8, @intCast(cocoa.stored.age)) * 2));
                        const height = @as(f32, @floatFromInt(5 + @as(u8, @intCast(cocoa.stored.age)) * 2));
                        break :blk switch (cocoa.stored.facing) {
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
            .sandstone_stairs => FULL, // TODO
            .emerald_ore => FULL,
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
                    switch (tripwire_hook.stored.facing) {
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
                    if (!tripwire.stored.suspended)
                        .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 1.0, .y = 0.09375, .z = 1.0 },
                        }
                    else if (!tripwire.stored.attached)
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
            .emerald_block => FULL,
            .spruce_stairs => FULL, // TODO
            .birch_stairs => FULL, // TODO
            .jungle_stairs => FULL, // TODO
            .command_block => FULL,
            .beacon => FULL,
            .cobblestone_wall => FULL, // TODO
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
                        const button_depth = @as(f32, @floatFromInt(@intFromBool(wooden_button.stored.powered))) / 16.0;
                        break :blk switch (wooden_button.stored.facing) {
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
                    switch (skull.stored.facing) {
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
                    switch (anvil.stored.facing) {
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
            .trapped_chest => {
                const trapped_chest = self.payload(.trapped_chest);
                return .{
                    switch (trapped_chest.virtual.connection) {
                        .north => .{
                            .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0 },
                            .max = .{ .x = 0.9375, .y = 0.875, .z = 0.9375 },
                        },
                        .south => .{
                            .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                            .max = .{ .x = 0.9375, .y = 0.875, .z = 1.0 },
                        },
                        .west => .{
                            .min = .{ .x = 0.0, .y = 0.0, .z = 0.0625 },
                            .max = .{ .x = 0.9375, .y = 0.875, .z = 0.9375 },
                        },
                        .east => .{
                            .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                            .max = .{ .x = 1.0, .y = 0.875, .z = 0.9375 },
                        },
                        .none => .{
                            .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                            .max = .{ .x = 0.9375, .y = 0.875, .z = 0.9375 },
                        },
                    },
                    null,
                    null,
                };
            },
            .light_weighted_pressure_plate => {
                const light_weighted_pressure_plate = self.payload(.light_weighted_pressure_plate);
                return .{
                    .{
                        .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                        .max = .{ .x = 0.9375, .y = if (light_weighted_pressure_plate.stored.power > 0) 0.03125 else 0.0625, .z = 0.9375 },
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
                        .max = .{ .x = 0.9375, .y = if (heavy_weighted_pressure_plate.stored.power > 0) 0.03125 else 0.0625, .z = 0.9375 },
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
            .redstone_block => FULL,
            .quartz_ore => FULL,
            .hopper => FULL,
            .quartz_block => FULL,
            .quartz_stairs => FULL, // TODO
            .activator_rail => {
                const activator_rail = self.payload(.activator_rail);
                return .{
                    .{
                        .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                        .max = .{ .x = 1.0, .y = if (activator_rail.stored.shape == .ascending_east or activator_rail.stored.shape == .ascending_north or activator_rail.stored.shape == .ascending_south or activator_rail.stored.shape == .ascending_west) 0.625 else 0.125, .z = 1.0 },
                    },
                    null,
                    null,
                };
            },
            .dropper => FULL,
            .stained_hardened_clay => FULL,
            .stained_glass_pane => {
                const stained_glass_pane = self.payload(.stained_glass_pane);
                return .{
                    blk: {
                        const any = stained_glass_pane.virtual.north or stained_glass_pane.virtual.south or stained_glass_pane.virtual.west or stained_glass_pane.virtual.east;
                        break :blk if (!any) CUBE else .{
                            .min = .{ .x = if (stained_glass_pane.virtual.west) @as(f32, 0.0) else @as(f32, 0.4375), .y = 0.0, .z = if (stained_glass_pane.virtual.north) @as(f32, 0.0) else @as(f32, 0.4375) },
                            .max = .{ .x = if (stained_glass_pane.virtual.east) @as(f32, 1.0) else @as(f32, 0.5625), .y = 1.0, .z = if (stained_glass_pane.virtual.south) @as(f32, 1.0) else @as(f32, 0.5625) },
                        };
                    },
                    null,
                    null,
                };
            },
            .leaves2 => FULL,
            .log2 => FULL,
            .acacia_stairs => FULL, // TODO
            .dark_oak_stairs => FULL, // TODO
            .slime => FULL,
            .barrier => FULL,
            .iron_trapdoor => FULL, // TODO
            .prismarine => FULL,
            .sea_lantern => FULL,
            .hay_block => FULL,
            .carpet => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.0625, .z = 1.0 },
                },
                null,
                null,
            },
            .hardened_clay => FULL,
            .coal_block => FULL,
            .packed_ice => FULL,
            .double_plant => FULL,
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
                    switch (wall_banner.stored.facing) {
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
            .red_sandstone => FULL,
            .red_sandstone_stairs => FULL, // TODO
            .double_stone_slab2 => FULL,
            .stone_slab2 => {
                const stone_slab2 = self.payload(.stone_slab2);
                return .{
                    .{
                        .min = .{ .x = 0, .y = if (stone_slab2.stored.half == .top) 0.5 else 0.0, .z = 0 },
                        .max = .{ .x = 1, .y = if (stone_slab2.stored.half == .top) 1.0 else 0.5, .z = 1 },
                    },
                    null,
                    null,
                };
            },
            .spruce_fence_gate => {
                const spruce_fence_gate = self.payload(.spruce_fence_gate);
                return .{
                    switch (spruce_fence_gate.stored.facing) {
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
                    switch (birch_fence_gate.stored.facing) {
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
                    switch (jungle_fence_gate.stored.facing) {
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
                    switch (dark_oak_fence_gate.stored.facing) {
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
                    switch (acacia_fence_gate.stored.facing) {
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
            .spruce_door => FULL, // TODO
            .birch_door => FULL, // TODO
            .jungle_door => FULL, // TODO
            .acacia_door => FULL, // TODO
            .dark_oak_door => FULL, // TODO

            .fire_upper => FULL, // TODO

            .redstone_wire_none_flat => FULL, // TODO
            .redstone_wire_none_upper => FULL, // TODO
            .redstone_wire_flat_none => FULL, // TODO
            .redstone_wire_flat_flat => FULL, // TODO
            .redstone_wire_flat_upper => FULL, // TODO
            .redstone_wire_upper_none => FULL, // TODO
            .redstone_wire_upper_flat => FULL, // TODO
            .redstone_wire_upper_upper => FULL, // TODO

            .cobblestone_wall_upper => FULL, // TODO
            .flower_pot_2 => FULL, // TODO
        };
    }
};

pub fn EnumBoolArray(comptime Enum: type) type {
    return struct {
        set: std.EnumSet(Enum),

        pub fn get(self: @This(), key: Enum) bool {
            return self.set.contains(key);
        }

        pub fn init(entries: std.enums.EnumFieldStruct(Enum, bool, null)) @This() {
            @setEvalBranchQuota(100000);
            var set = std.EnumSet(Enum).initEmpty();
            inline for (@typeInfo(@TypeOf(entries)).Struct.fields) |struct_field| {
                if (@field(entries, struct_field.name)) {
                    inline for (@typeInfo(Enum).Enum.fields) |enum_field| {
                        if (comptime std.mem.eql(u8, enum_field.name, struct_field.name)) {
                            set.insert(@enumFromInt(enum_field.value));
                        }
                    }
                }
            }
            return .{ .set = set };
        }
    };
}
