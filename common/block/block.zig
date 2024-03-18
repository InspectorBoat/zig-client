const std = @import("std");
const World = @import("../world/World.zig");
const Vector3 = @import("../type/vector.zig").Vector3;
const Hitbox = @import("../math/Hitbox.zig");

// Requirements of system:
// Looking up the raytrace hitboxes for a blockstate, which depends on virtual properties, must be fast
// Looking up the collision hitboxes for a blockstate, which depends on virtual properties, must be fast
// Looking up the model for a blockstate, which depends on virtual properties, must be fast
// looking up toughness, friction, tool, etc. for a block, must be fast
// Fully resolved blockstates must take up 16 bits or less

// To accomplish this, we split off the blocks that have too many virtual blockstates into multiple blocks

// To look up the raytrace/collision hitboxes, we use a hashmap
// To look up the toughness/friction/tool/solidity, we directly use the block bits

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
        if (!valid_metadata_table.get(block).isSet(self.metadata)) return FilteredBlockState.AIR;
        return .{
            .block = block,
            .properties = .{ .raw_bits = metadata_conversion_table.get(block).get(self.metadata) },
        };
    }
};

// RawBlockState, but stipped of invalid states and converted into a sane format
pub const FilteredBlockState = packed struct {
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

    pub fn toConcreteBlockState(self: @This(), world: World, block_pos: Vector3(i32)) ConcreteBlockState {
        _ = world;
        _ = block_pos;
        // @setEvalBranchQuota(1000000);
        // comptime var virtual = 0;
        // inline for (@typeInfo(ConcreteBlockState).Union.fields) |block| {
        //     const field_info = @typeInfo(block.type);
        //     const virtual_properties = field_info.Struct.fields[0].type;
        //     if (field_info == .Struct) {
        //         if (comptime !std.mem.eql(u8, @typeInfo(virtual_properties).Struct.fields[0].name, "_")) {
        //             @compileLog(block.name);
        //             virtual += 1;
        //             if (comptime std.mem.containsAtLeast(u8, block.name, 1, "stairs")) {
        //                 virtual -= 1;
        //             }
        //             if (comptime std.mem.containsAtLeast(u8, block.name, 1, "fence")) {
        //                 virtual -= 1;
        //             }
        //             if (comptime std.mem.containsAtLeast(u8, block.name, 1, "redstone_wire")) {
        //                 virtual -= 1;
        //             }
        //         }
        //     }
        // }
        // virtual += 2;
        // @compileLog(virtual);
        return switch (self.block) {
            .grass => ConcreteBlockState.AIR,
            .dirt => ConcreteBlockState.AIR,
            .piston_head => ConcreteBlockState.AIR,
            .fire => ConcreteBlockState.AIR,
            .oak_stairs => ConcreteBlockState.AIR,
            .chest => ConcreteBlockState.AIR,
            .redstone_wire => ConcreteBlockState.AIR,
            .stone_stairs => ConcreteBlockState.AIR,
            .fence => ConcreteBlockState.AIR,
            .unpowered_repeater => ConcreteBlockState.AIR,
            .powered_repeater => ConcreteBlockState.AIR,
            .iron_bars => ConcreteBlockState.AIR,
            .glass_pane => ConcreteBlockState.AIR,
            .pumpkin_stem => ConcreteBlockState.AIR,
            .melon_stem => ConcreteBlockState.AIR,
            .vine => ConcreteBlockState.AIR,
            .fence_gate => ConcreteBlockState.AIR,
            .brick_stairs => ConcreteBlockState.AIR,
            .stone_brick_stairs => ConcreteBlockState.AIR,
            .mycelium => ConcreteBlockState.AIR,
            .nether_brick_fence => ConcreteBlockState.AIR,
            .nether_brick_stairs => ConcreteBlockState.AIR,
            .sandstone_stairs => ConcreteBlockState.AIR,
            .tripwire_hook => ConcreteBlockState.AIR,
            .tripwire => ConcreteBlockState.AIR,
            .spruce_stairs => ConcreteBlockState.AIR,
            .birch_stairs => ConcreteBlockState.AIR,
            .jungle_stairs => ConcreteBlockState.AIR,
            .cobblestone_wall => ConcreteBlockState.AIR,
            .flower_pot => ConcreteBlockState.AIR,
            .trapped_chest => ConcreteBlockState.AIR,
            .quartz_stairs => ConcreteBlockState.AIR,
            .stained_glass_pane => ConcreteBlockState.AIR,
            .acacia_stairs => ConcreteBlockState.AIR,
            .dark_oak_stairs => ConcreteBlockState.AIR,
            .red_sandstone_stairs => ConcreteBlockState.AIR,
            .spruce_fence_gate => ConcreteBlockState.AIR,
            .birch_fence_gate => ConcreteBlockState.AIR,
            .jungle_fence_gate => ConcreteBlockState.AIR,
            .dark_oak_fence_gate => ConcreteBlockState.AIR,
            .acacia_fence_gate => ConcreteBlockState.AIR,
            .spruce_fence => ConcreteBlockState.AIR,
            .birch_fence => ConcreteBlockState.AIR,
            .jungle_fence => ConcreteBlockState.AIR,
            .dark_oak_fence => ConcreteBlockState.AIR,
            .acacia_fence => ConcreteBlockState.AIR,

            else => |block| {
                return .{
                    .block = @enumFromInt(@intFromEnum(block)),
                    .properties = .{ .raw_bits = .{ .virtual = 0, .stored = @bitCast(self.properties) } },
                };
            },
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

    pub fn getFriction(self: @This()) f32 {
        return switch (self) {
            .slime => 0.8,
            .ice, .packed_ice => 0.98,
            else => 0.6,
        };
    }
};

// FilteredBlockState, but with virtual properties resolved
pub const ConcreteBlockState = packed struct(u16) {
    const AIR: ConcreteBlockState = .{
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
            virtual: packed struct(u4) { shape: enum(u3) { straight, inner_left, inner_right, outer_left, outer_right }, _: u1 = 0 },
            stored: StoredBlockProperties.oak_stairs,
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

    pub fn payload(self: @This(), comptime block: ConcreteBlock) @TypeOf(@field(self.properties, @tagName(block))) {
        std.debug.assert(self.block == block);
        return @field(self.properties, @tagName(block));
    }
    pub fn payloadUnchecked(self: @This(), comptime block: ConcreteBlock) @TypeOf(@field(self.properties, @tagName(block))) {
        return @field(self.properties, @tagName(block));
    }

    pub fn getRaytraceHitbox(self: @This()) [3]Hitbox {
        const EMPTY: Hitbox = .{
            .min = .{ .x = 0, .y = 0, .z = 0 },
            .max = .{ .x = 0, .y = 0, .z = 0 },
        };
        const CUBE: Hitbox = .{
            .min = .{ .x = 0, .y = 0, .z = 0 },
            .max = .{ .x = 1, .y = 1, .z = 1 },
        };
        const NONE: [3]Hitbox = .{ EMPTY, EMPTY, EMPTY };
        const FULL: [3]Hitbox = .{ CUBE, EMPTY, EMPTY };
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
                EMPTY,
                EMPTY,
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
                EMPTY,
                EMPTY,
            },
            .golden_rail => {
                const golden_rail = self.payload(.golden_rail);
                return .{
                    .{
                        .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                        .max = .{ .x = 1.0, .y = if (golden_rail.stored.shape == .ascending_east or golden_rail.stored.shape == .ascending_north or golden_rail.stored.shape == .ascending_south or golden_rail.stored.shape == .ascending_west) 0.625 else 0.125, .z = 1.0 },
                    },
                    EMPTY,
                    EMPTY,
                };
            },
            .detector_rail => {
                const detector_rail = self.payload(.detector_rail);
                return .{
                    .{
                        .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                        .max = .{ .x = 1.0, .y = if (detector_rail.stored.shape == .ascending_east or detector_rail.stored.shape == .ascending_north or detector_rail.stored.shape == .ascending_south or detector_rail.stored.shape == .ascending_west) 0.625 else 0.125, .z = 1.0 },
                    },
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
                };
            },
            .web => FULL,
            .tallgrass => .{
                .{
                    .min = .{ .x = 0.1, .y = 0.1, .z = 0.1 },
                    .max = .{ .x = 0.9, .y = 0.8, .z = 0.9 },
                },
                EMPTY,
                EMPTY,
            },
            .deadbush => .{
                .{
                    .min = .{ .x = 0.1, .y = 0.1, .z = 0.1 },
                    .max = .{ .x = 0.9, .y = 0.8, .z = 0.9 },
                },
                EMPTY,
                EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
                };
            },
            .wool => FULL,
            .piston_extension => NONE,
            .yellow_flower => .{
                .{
                    .min = .{ .x = 0.3, .y = 0.0, .z = 0.3 },
                    .max = .{ .x = 0.7, .y = 0.6, .z = 0.7 },
                },
                EMPTY,
                EMPTY,
            },
            .red_flower => .{
                .{
                    .min = .{ .x = 0.3, .y = 0.0, .z = 0.3 },
                    .max = .{ .x = 0.7, .y = 0.6, .z = 0.7 },
                },
                EMPTY,
                EMPTY,
            },
            .brown_mushroom => .{
                .{
                    .min = .{ .x = 0.3, .y = 0.0, .z = 0.3 },
                    .max = .{ .x = 0.7, .y = 0.6, .z = 0.7 },
                },
                EMPTY,
                EMPTY,
            },
            .red_mushroom => .{
                .{
                    .min = .{ .x = 0.3, .y = 0.0, .z = 0.3 },
                    .max = .{ .x = 0.7, .y = 0.6, .z = 0.7 },
                },
                EMPTY,
                EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
                };
            },

            .fire => NONE,

            .mob_spawner => FULL,
            .oak_stairs => FULL, // TODO
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
                    EMPTY,
                    EMPTY,
                };
            },

            .redstone_wire => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.0625, .z = 1.0 },
                },
                EMPTY,
                EMPTY,
            },

            .diamond_ore => FULL,
            .diamond_block => FULL,
            .crafting_table => FULL,
            .wheat => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.25, .z = 1.0 },
                },
                EMPTY,
                EMPTY,
            },
            .farmland => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.9375, .z = 1.0 },
                },
                EMPTY,
                EMPTY,
            },
            .furnace => FULL,
            .lit_furnace => FULL,
            .standing_sign => .{
                .{
                    .min = .{ .x = 0.25, .y = 0.0, .z = 0.25 },
                    .max = .{ .x = 0.75, .y = 1.0, .z = 0.75 },
                },
                EMPTY,
                EMPTY,
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
                    EMPTY,
                    EMPTY,
                };
            },
            .rail => {
                const rail = self.payload(.rail);
                return .{
                    .{
                        .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                        .max = .{ .x = 1.0, .y = if (rail.stored.shape == .ascending_east or rail.stored.shape == .ascending_north or rail.stored.shape == .ascending_south or rail.stored.shape == .ascending_west) 0.625 else 0.125, .z = 1.0 },
                    },
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
                };
            },
            .stone_pressure_plate => {
                const stone_pressure_plate = self.payload(.stone_pressure_plate);
                return .{
                    .{
                        .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                        .max = .{ .x = 0.9375, .y = if (stone_pressure_plate.stored.powered) 0.03125 else 0.0625, .z = 0.9375 },
                    },
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
                };
            },
            .snow_layer => {
                const snow_layer = self.payload(.snow_layer);
                return .{
                    .{
                        .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                        .max = .{ .x = 1.0, .y = @as(f32, @floatFromInt(snow_layer.stored.layers + 1)) / 8.0, .z = 1.0 },
                    },
                    EMPTY,
                    EMPTY,
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
                EMPTY,
                EMPTY,
            },
            .jukebox => FULL,
            .fence => {
                const fence = self.payload(.fence);
                return .{
                    .{
                        .min = .{ .x = if (fence.virtual.west) 0.0 else 0.375, .y = 0.0, .z = if (fence.virtual.north) 0.0 else 0.375 },
                        .max = .{ .x = if (fence.virtual.east) 0.0 else 0.625, .y = 1.0, .z = if (fence.virtual.south) 0.0 else 0.625 },
                    },
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
                };
            },
            .unpowered_repeater => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.125, .z = 1.0 },
                },
                EMPTY,
                EMPTY,
            },
            .powered_repeater => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.125, .z = 1.0 },
                },
                EMPTY,
                EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
                };
            },
            .melon_stem => {
                const melon_stem = self.payload(.melon_stem);
                return .{
                    .{
                        .min = .{ .x = 0.375, .y = 0.0, .z = 0.375 },
                        .max = .{ .x = 0.625, .y = @as(f32, @floatFromInt(melon_stem.stored.age * 2 + 2)) / 16.0, .z = 0.625 },
                    },
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                EMPTY,
                EMPTY,
            },
            .nether_brick => FULL,
            .nether_brick_fence => {
                const nether_brick_fence = self.payload(.nether_brick_fence);
                return .{
                    .{
                        .min = .{ .x = if (nether_brick_fence.virtual.west) 0.0 else 0.375, .y = 0.0, .z = if (nether_brick_fence.virtual.north) 0.0 else 0.375 },
                        .max = .{ .x = if (nether_brick_fence.virtual.east) 0.0 else 0.625, .y = 1.0, .z = if (nether_brick_fence.virtual.south) 0.0 else 0.625 },
                    },
                    EMPTY,
                    EMPTY,
                };
            },
            .nether_brick_stairs => FULL, // TODO
            .nether_wart => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.375 },
                    .max = .{ .x = 1.0, .y = 0.25, .z = 0.625 },
                },
                EMPTY,
                EMPTY,
            },
            .enchanting_table => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.375 },
                    .max = .{ .x = 1.0, .y = 0.75, .z = 0.625 },
                },
                EMPTY,
                EMPTY,
            },
            .brewing_stand => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.375 },
                    .max = .{ .x = 1.0, .y = 0.125, .z = 0.625 },
                },
                EMPTY,
                EMPTY,
            },
            .cauldron => FULL,
            .end_portal => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.0625, .z = 1.0 },
                },
                EMPTY,
                EMPTY,
            },
            .end_portal_frame => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.8125, .z = 0.0 },
                },
                EMPTY,
                EMPTY,
            },
            .end_stone => FULL,
            .dragon_egg => .{
                .{
                    .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                    .max = .{ .x = 0.9375, .y = 1.0, .z = 0.9375 },
                },
                EMPTY,
                EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
                };
            },
            .sandstone_stairs => FULL, // TODO
            .emerald_ore => FULL,
            .ender_chest => .{
                .{
                    .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                    .max = .{ .x = 0.9375, .y = 0.875, .z = 0.9375 },
                },
                EMPTY,
                EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                EMPTY,
                EMPTY,
            },
            .carrots => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.25, .z = 1.0 },
                },
                EMPTY,
                EMPTY,
            },
            .potatoes => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.25, .z = 1.0 },
                },
                EMPTY,
                EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
                };
            },
            .light_weighted_pressure_plate => {
                const light_weighted_pressure_plate = self.payload(.light_weighted_pressure_plate);
                return .{
                    .{
                        .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                        .max = .{ .x = 0.9375, .y = if (light_weighted_pressure_plate.stored.power > 0) 0.03125 else 0.0625, .z = 0.9375 },
                    },
                    EMPTY,
                    EMPTY,
                };
            },
            .heavy_weighted_pressure_plate => {
                const heavy_weighted_pressure_plate = self.payload(.heavy_weighted_pressure_plate);
                return .{
                    .{
                        .min = .{ .x = 0.0625, .y = 0.0, .z = 0.0625 },
                        .max = .{ .x = 0.9375, .y = if (heavy_weighted_pressure_plate.stored.power > 0) 0.03125 else 0.0625, .z = 0.9375 },
                    },
                    EMPTY,
                    EMPTY,
                };
            },
            .unpowered_comparator => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.125, .z = 1.0 },
                },
                EMPTY,
                EMPTY,
            },
            .powered_comparator => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.125, .z = 1.0 },
                },
                EMPTY,
                EMPTY,
            },
            .daylight_detector => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
                    .max = .{ .x = 1.0, .y = 0.375, .z = 1.0 },
                },
                EMPTY,
                EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                EMPTY,
                EMPTY,
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
                EMPTY,
                EMPTY,
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
                    EMPTY,
                    EMPTY,
                };
            },
            .daylight_detector_inverted => .{
                .{
                    .min = .{ .x = 0.0, .y = 0.0, .z = 0.1 },
                    .max = .{ .x = 1.0, .y = 0.375, .z = 1.0 },
                },
                EMPTY,
                EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
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
                    EMPTY,
                    EMPTY,
                };
            },
            .spruce_fence => {
                const spruce_fence = self.payload(.spruce_fence);
                return .{
                    .{
                        .min = .{ .x = if (spruce_fence.virtual.west) 0.0 else 0.375, .y = 0.0, .z = if (spruce_fence.virtual.north) 0.0 else 0.375 },
                        .max = .{ .x = if (spruce_fence.virtual.east) 0.0 else 0.625, .y = 1.0, .z = if (spruce_fence.virtual.south) 0.0 else 0.625 },
                    },
                    EMPTY,
                    EMPTY,
                };
            },
            .birch_fence => {
                const birch_fence = self.payload(.birch_fence);
                return .{
                    .{
                        .min = .{ .x = if (birch_fence.virtual.west) 0.0 else 0.375, .y = 0.0, .z = if (birch_fence.virtual.north) 0.0 else 0.375 },
                        .max = .{ .x = if (birch_fence.virtual.east) 0.0 else 0.625, .y = 1.0, .z = if (birch_fence.virtual.south) 0.0 else 0.625 },
                    },
                    EMPTY,
                    EMPTY,
                };
            },
            .jungle_fence => {
                const jungle_fence = self.payload(.jungle_fence);
                return .{
                    .{
                        .min = .{ .x = if (jungle_fence.virtual.west) 0.0 else 0.375, .y = 0.0, .z = if (jungle_fence.virtual.north) 0.0 else 0.375 },
                        .max = .{ .x = if (jungle_fence.virtual.east) 0.0 else 0.625, .y = 1.0, .z = if (jungle_fence.virtual.south) 0.0 else 0.625 },
                    },
                    EMPTY,
                    EMPTY,
                };
            },
            .dark_oak_fence => {
                const dark_oak_fence = self.payload(.dark_oak_fence);
                return .{
                    .{
                        .min = .{ .x = if (dark_oak_fence.virtual.west) 0.0 else 0.375, .y = 0.0, .z = if (dark_oak_fence.virtual.north) 0.0 else 0.375 },
                        .max = .{ .x = if (dark_oak_fence.virtual.east) 0.0 else 0.625, .y = 1.0, .z = if (dark_oak_fence.virtual.south) 0.0 else 0.625 },
                    },
                    EMPTY,
                    EMPTY,
                };
            },
            .acacia_fence => {
                const acacia_fence = self.payload(.acacia_fence);
                return .{
                    .{
                        .min = .{ .x = if (acacia_fence.virtual.west) 0.0 else 0.375, .y = 0.0, .z = if (acacia_fence.virtual.north) 0.0 else 0.375 },
                        .max = .{ .x = if (acacia_fence.virtual.east) 0.0 else 0.625, .y = 1.0, .z = if (acacia_fence.virtual.south) 0.0 else 0.625 },
                    },
                    EMPTY,
                    EMPTY,
                };
            },
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

/// A table of valid metadata values for each block
/// Zero represents an invalid value that will become air and One represents a valid value that should be looked up in raw_to_filtered_conversion_table
/// For example, the only valid metadata value for .Air is 0
const valid_metadata_table = blk: {
    var table = std.EnumArray(Block, std.bit_set.IntegerBitSet(16)).initUndefined();
    table.set(.air, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.stone, .{ .mask = @bitReverse(@as(u16, 0b1111111000000000)) });
    table.set(.grass, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.dirt, .{ .mask = @bitReverse(@as(u16, 0b1110000000000000)) });
    table.set(.cobblestone, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.planks, .{ .mask = @bitReverse(@as(u16, 0b1111110000000000)) });
    table.set(.sapling, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.bedrock, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.flowing_water, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.water, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.flowing_lava, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.lava, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.sand, .{ .mask = @bitReverse(@as(u16, 0b1100000000000000)) });
    table.set(.gravel, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.gold_ore, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.iron_ore, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.coal_ore, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.log, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.leaves, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.sponge, .{ .mask = @bitReverse(@as(u16, 0b1100000000000000)) });
    table.set(.glass, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.lapis_ore, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.lapis_block, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.dispenser, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.sandstone, .{ .mask = @bitReverse(@as(u16, 0b1110000000000000)) });
    table.set(.noteblock, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.bed, .{ .mask = @bitReverse(@as(u16, 0b1111000011111111)) });
    table.set(.golden_rail, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.detector_rail, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.sticky_piston, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.web, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.tallgrass, .{ .mask = @bitReverse(@as(u16, 0b1110000000000000)) });
    table.set(.deadbush, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.piston, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.piston_head, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.wool, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.piston_extension, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.yellow_flower, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.red_flower, .{ .mask = @bitReverse(@as(u16, 0b1111111110000000)) });
    table.set(.brown_mushroom, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.red_mushroom, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.gold_block, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.iron_block, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.double_stone_slab, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.stone_slab, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.brick_block, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.tnt, .{ .mask = @bitReverse(@as(u16, 0b1100000000000000)) });
    table.set(.bookshelf, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.mossy_cobblestone, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.obsidian, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.torch, .{ .mask = @bitReverse(@as(u16, 0b0111110000000000)) });
    table.set(.fire, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.mob_spawner, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.oak_stairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.chest, .{ .mask = @bitReverse(@as(u16, 0b0011110000000000)) });
    table.set(.redstone_wire, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.diamond_ore, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.diamond_block, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.crafting_table, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.wheat, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.farmland, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.furnace, .{ .mask = @bitReverse(@as(u16, 0b0011110000000000)) });
    table.set(.lit_furnace, .{ .mask = @bitReverse(@as(u16, 0b0011110000000000)) });
    table.set(.standing_sign, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.wooden_door, .{ .mask = @bitReverse(@as(u16, 0b1111111111110000)) });
    table.set(.ladder, .{ .mask = @bitReverse(@as(u16, 0b0011110000000000)) });
    table.set(.rail, .{ .mask = @bitReverse(@as(u16, 0b1111111111000000)) });
    table.set(.stone_stairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.wall_sign, .{ .mask = @bitReverse(@as(u16, 0b0011110000000000)) });
    table.set(.lever, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.stone_pressure_plate, .{ .mask = @bitReverse(@as(u16, 0b1100000000000000)) });
    table.set(.iron_door, .{ .mask = @bitReverse(@as(u16, 0b1111111111110000)) });
    table.set(.wooden_pressure_plate, .{ .mask = @bitReverse(@as(u16, 0b1100000000000000)) });
    table.set(.redstone_ore, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.lit_redstone_ore, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.unlit_redstone_torch, .{ .mask = @bitReverse(@as(u16, 0b0111110000000000)) });
    table.set(.redstone_torch, .{ .mask = @bitReverse(@as(u16, 0b0111110000000000)) });
    table.set(.stone_button, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.snow_layer, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.ice, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.snow, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.cactus, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.clay, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.reeds, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.jukebox, .{ .mask = @bitReverse(@as(u16, 0b1100000000000000)) });
    table.set(.fence, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.pumpkin, .{ .mask = @bitReverse(@as(u16, 0b1111000000000000)) });
    table.set(.netherrack, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.soul_sand, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.glowstone, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.portal, .{ .mask = @bitReverse(@as(u16, 0b0110000000000000)) });
    table.set(.lit_pumpkin, .{ .mask = @bitReverse(@as(u16, 0b1111000000000000)) });
    table.set(.cake, .{ .mask = @bitReverse(@as(u16, 0b1111111000000000)) });
    table.set(.unpowered_repeater, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.powered_repeater, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.stained_glass, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.trapdoor, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.monster_egg, .{ .mask = @bitReverse(@as(u16, 0b1111110000000000)) });
    table.set(.stonebrick, .{ .mask = @bitReverse(@as(u16, 0b1111000000000000)) });
    table.set(.brown_mushroom_block, .{ .mask = @bitReverse(@as(u16, 0b1111111111100011)) });
    table.set(.red_mushroom_block, .{ .mask = @bitReverse(@as(u16, 0b1111111111100011)) });
    table.set(.iron_bars, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.glass_pane, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.melon_block, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.pumpkin_stem, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.melon_stem, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.vine, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.fence_gate, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.brick_stairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.stone_brick_stairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.mycelium, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.waterlily, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.nether_brick, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.nether_brick_fence, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.nether_brick_stairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.nether_wart, .{ .mask = @bitReverse(@as(u16, 0b1111000000000000)) });
    table.set(.enchanting_table, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.brewing_stand, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.cauldron, .{ .mask = @bitReverse(@as(u16, 0b1111000000000000)) });
    table.set(.end_portal, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.end_portal_frame, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.end_stone, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.dragon_egg, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.redstone_lamp, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.lit_redstone_lamp, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.double_wooden_slab, .{ .mask = @bitReverse(@as(u16, 0b1111110000000000)) });
    table.set(.wooden_slab, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.cocoa, .{ .mask = @bitReverse(@as(u16, 0b1111111111110000)) });
    table.set(.sandstone_stairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.emerald_ore, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.ender_chest, .{ .mask = @bitReverse(@as(u16, 0b0011110000000000)) });
    table.set(.tripwire_hook, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.tripwire, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.emerald_block, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.spruce_stairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.birch_stairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.jungle_stairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.command_block, .{ .mask = @bitReverse(@as(u16, 0b1100000000000000)) });
    table.set(.beacon, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.cobblestone_wall, .{ .mask = @bitReverse(@as(u16, 0b1100000000000000)) });
    table.set(.flower_pot, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.carrots, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.potatoes, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.wooden_button, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.skull, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.anvil, .{ .mask = @bitReverse(@as(u16, 0b1111111111110000)) });
    table.set(.trapped_chest, .{ .mask = @bitReverse(@as(u16, 0b0011110000000000)) });
    table.set(.light_weighted_pressure_plate, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.heavy_weighted_pressure_plate, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.unpowered_comparator, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.powered_comparator, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.daylight_detector, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.redstone_block, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.quartz_ore, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.hopper, .{ .mask = @bitReverse(@as(u16, 0b1011110010111100)) });
    table.set(.quartz_block, .{ .mask = @bitReverse(@as(u16, 0b1111100000000000)) });
    table.set(.quartz_stairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.activator_rail, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.dropper, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.stained_hardened_clay, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.stained_glass_pane, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.leaves2, .{ .mask = @bitReverse(@as(u16, 0b1100110011001100)) });
    table.set(.log2, .{ .mask = @bitReverse(@as(u16, 0b1100110011001100)) });
    table.set(.acacia_stairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.dark_oak_stairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.slime, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.barrier, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.iron_trapdoor, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.prismarine, .{ .mask = @bitReverse(@as(u16, 0b1110000000000000)) });
    table.set(.sea_lantern, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.hay_block, .{ .mask = @bitReverse(@as(u16, 0b1000100010000000)) });
    table.set(.carpet, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.hardened_clay, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.coal_block, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.packed_ice, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.double_plant, .{ .mask = @bitReverse(@as(u16, 0b1111110011110000)) });
    table.set(.standing_banner, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.wall_banner, .{ .mask = @bitReverse(@as(u16, 0b0011110000000000)) });
    table.set(.daylight_detector_inverted, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.red_sandstone, .{ .mask = @bitReverse(@as(u16, 0b1110000000000000)) });
    table.set(.red_sandstone_stairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.double_stone_slab2, .{ .mask = @bitReverse(@as(u16, 0b1000000010000000)) });
    table.set(.stone_slab2, .{ .mask = @bitReverse(@as(u16, 0b1000000010000000)) });
    table.set(.spruce_fence_gate, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.birch_fence_gate, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.jungle_fence_gate, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.dark_oak_fence_gate, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.acacia_fence_gate, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.spruce_fence, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.birch_fence, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.jungle_fence, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.dark_oak_fence, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.acacia_fence, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.spruce_door, .{ .mask = @bitReverse(@as(u16, 0b1111111111110000)) });
    table.set(.birch_door, .{ .mask = @bitReverse(@as(u16, 0b1111111111110000)) });
    table.set(.jungle_door, .{ .mask = @bitReverse(@as(u16, 0b1111111111110000)) });
    table.set(.acacia_door, .{ .mask = @bitReverse(@as(u16, 0b1111111111110000)) });
    table.set(.dark_oak_door, .{ .mask = @bitReverse(@as(u16, 0b1111111111110000)) });
    break :blk table;
};

/// converts metadata -> packed struct through lookup table
const metadata_conversion_table = blk: {
    const bitCastArrayElements = struct {
        /// Casts an array of packed structs into an array of that packed struct's backing int
        fn bitCastArrayElements(comptime ElementType: type, comptime length: usize, array: [length]ElementType) [length]std.meta.Int(.unsigned, @bitSizeOf(ElementType)) {
            @setEvalBranchQuota(1000000);
            var casted: [length]std.meta.Int(.unsigned, @bitSizeOf(ElementType)) = undefined;
            for (array, &casted) |original, *casted_ptr| {
                casted_ptr.* = @bitCast(original);
            }
            return casted;
        }
    }.bitCastArrayElements;

    var table = std.EnumArray(Block, std.PackedIntArray(u4, 16)).initUndefined();
    const properties = FilteredBlockState.BlockProperties;
    table.set(.air, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.air, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.stone, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.stone, 16, .{ .{ .variant = .stone }, .{ .variant = .granite }, .{ .variant = .smooth_granite }, .{ .variant = .diorite }, .{ .variant = .smooth_diorite }, .{ .variant = .andesite }, .{ .variant = .smooth_andesite }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.grass, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.grass, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.dirt, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.dirt, 16, .{ .{ .variant = .dirt }, .{ .variant = .coarse_dirt }, .{ .variant = .podzol }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.cobblestone, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.cobblestone, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.planks, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.planks, 16, .{ .{ .variant = .oak }, .{ .variant = .spruce }, .{ .variant = .birch }, .{ .variant = .jungle }, .{ .variant = .acacia }, .{ .variant = .dark_oak }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.sapling, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.sapling, 16, .{ .{ .variant = .oak, .stage = 0 }, .{ .variant = .spruce, .stage = 0 }, .{ .variant = .birch, .stage = 0 }, .{ .variant = .jungle, .stage = 0 }, .{ .variant = .acacia, .stage = 0 }, .{ .variant = .dark_oak, .stage = 0 }, undefined, undefined, .{ .variant = .oak, .stage = 1 }, .{ .variant = .spruce, .stage = 1 }, .{ .variant = .birch, .stage = 1 }, .{ .variant = .jungle, .stage = 1 }, .{ .variant = .acacia, .stage = 1 }, .{ .variant = .dark_oak, .stage = 1 }, undefined, undefined })));
    table.set(.bedrock, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.bedrock, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.flowing_water, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.flowing_water, 16, .{ .{ .level = 0 }, .{ .level = 1 }, .{ .level = 2 }, .{ .level = 3 }, .{ .level = 4 }, .{ .level = 5 }, .{ .level = 6 }, .{ .level = 7 }, .{ .level = 8 }, .{ .level = 9 }, .{ .level = 10 }, .{ .level = 11 }, .{ .level = 12 }, .{ .level = 13 }, .{ .level = 14 }, .{ .level = 15 } })));
    table.set(.water, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.water, 16, .{ .{ .level = 0 }, .{ .level = 1 }, .{ .level = 2 }, .{ .level = 3 }, .{ .level = 4 }, .{ .level = 5 }, .{ .level = 6 }, .{ .level = 7 }, .{ .level = 8 }, .{ .level = 9 }, .{ .level = 10 }, .{ .level = 11 }, .{ .level = 12 }, .{ .level = 13 }, .{ .level = 14 }, .{ .level = 15 } })));
    table.set(.flowing_lava, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.flowing_lava, 16, .{ .{ .level = 0 }, .{ .level = 1 }, .{ .level = 2 }, .{ .level = 3 }, .{ .level = 4 }, .{ .level = 5 }, .{ .level = 6 }, .{ .level = 7 }, .{ .level = 8 }, .{ .level = 9 }, .{ .level = 10 }, .{ .level = 11 }, .{ .level = 12 }, .{ .level = 13 }, .{ .level = 14 }, .{ .level = 15 } })));
    table.set(.lava, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.lava, 16, .{ .{ .level = 0 }, .{ .level = 1 }, .{ .level = 2 }, .{ .level = 3 }, .{ .level = 4 }, .{ .level = 5 }, .{ .level = 6 }, .{ .level = 7 }, .{ .level = 8 }, .{ .level = 9 }, .{ .level = 10 }, .{ .level = 11 }, .{ .level = 12 }, .{ .level = 13 }, .{ .level = 14 }, .{ .level = 15 } })));
    table.set(.sand, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.sand, 16, .{ .{ .variant = .sand }, .{ .variant = .red_sand }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.gravel, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.gravel, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.gold_ore, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.gold_ore, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.iron_ore, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.iron_ore, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.coal_ore, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.coal_ore, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.log, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.log, 16, .{ .{ .axis = .y, .variant = .oak }, .{ .axis = .y, .variant = .spruce }, .{ .axis = .y, .variant = .birch }, .{ .axis = .y, .variant = .jungle }, .{ .axis = .x, .variant = .oak }, .{ .axis = .x, .variant = .spruce }, .{ .axis = .x, .variant = .birch }, .{ .axis = .x, .variant = .jungle }, .{ .axis = .z, .variant = .oak }, .{ .axis = .z, .variant = .spruce }, .{ .axis = .z, .variant = .birch }, .{ .axis = .z, .variant = .jungle }, .{ .axis = .none, .variant = .oak }, .{ .axis = .none, .variant = .spruce }, .{ .axis = .none, .variant = .birch }, .{ .axis = .none, .variant = .jungle } })));
    table.set(.leaves, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.leaves, 16, .{ .{ .variant = .oak, .check_decay = false, .decayable = true }, .{ .variant = .spruce, .check_decay = false, .decayable = true }, .{ .variant = .birch, .check_decay = false, .decayable = true }, .{ .variant = .jungle, .check_decay = false, .decayable = true }, .{ .variant = .oak, .check_decay = false, .decayable = false }, .{ .variant = .spruce, .check_decay = false, .decayable = false }, .{ .variant = .birch, .check_decay = false, .decayable = false }, .{ .variant = .jungle, .check_decay = false, .decayable = false }, .{ .variant = .oak, .check_decay = true, .decayable = true }, .{ .variant = .spruce, .check_decay = true, .decayable = true }, .{ .variant = .birch, .check_decay = true, .decayable = true }, .{ .variant = .jungle, .check_decay = true, .decayable = true }, .{ .variant = .oak, .check_decay = true, .decayable = false }, .{ .variant = .spruce, .check_decay = true, .decayable = false }, .{ .variant = .birch, .check_decay = true, .decayable = false }, .{ .variant = .jungle, .check_decay = true, .decayable = false } })));
    table.set(.sponge, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.sponge, 16, .{ .{ .wet = false }, .{ .wet = true }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.glass, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.glass, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.lapis_ore, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.lapis_ore, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.lapis_block, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.lapis_block, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.dispenser, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.dispenser, 16, .{ .{ .triggered = false, .facing = .down }, .{ .triggered = false, .facing = .up }, .{ .triggered = false, .facing = .north }, .{ .triggered = false, .facing = .south }, .{ .triggered = false, .facing = .west }, .{ .triggered = false, .facing = .east }, undefined, undefined, .{ .triggered = true, .facing = .down }, .{ .triggered = true, .facing = .up }, .{ .triggered = true, .facing = .north }, .{ .triggered = true, .facing = .south }, .{ .triggered = true, .facing = .west }, .{ .triggered = true, .facing = .east }, undefined, undefined })));
    table.set(.sandstone, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.sandstone, 16, .{ .{ .variant = .sandstone }, .{ .variant = .chiseled_sandstone }, .{ .variant = .smooth_sandstone }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.noteblock, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.noteblock, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.bed, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.bed, 16, .{ .{ .occupied = false, .facing = .south, .part = .foot }, .{ .occupied = false, .facing = .west, .part = .foot }, .{ .occupied = false, .facing = .north, .part = .foot }, .{ .occupied = false, .facing = .east, .part = .foot }, undefined, undefined, undefined, undefined, .{ .occupied = false, .facing = .south, .part = .head }, .{ .occupied = false, .facing = .west, .part = .head }, .{ .occupied = false, .facing = .north, .part = .head }, .{ .occupied = false, .facing = .east, .part = .head }, .{ .occupied = true, .facing = .south, .part = .head }, .{ .occupied = true, .facing = .west, .part = .head }, .{ .occupied = true, .facing = .north, .part = .head }, .{ .occupied = true, .facing = .east, .part = .head } })));
    table.set(.golden_rail, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.golden_rail, 16, .{ .{ .powered = false, .shape = .north_south }, .{ .powered = false, .shape = .east_west }, .{ .powered = false, .shape = .ascending_east }, .{ .powered = false, .shape = .ascending_west }, .{ .powered = false, .shape = .ascending_north }, .{ .powered = false, .shape = .ascending_south }, undefined, undefined, .{ .powered = true, .shape = .north_south }, .{ .powered = true, .shape = .east_west }, .{ .powered = true, .shape = .ascending_east }, .{ .powered = true, .shape = .ascending_west }, .{ .powered = true, .shape = .ascending_north }, .{ .powered = true, .shape = .ascending_south }, undefined, undefined })));
    table.set(.detector_rail, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.detector_rail, 16, .{ .{ .powered = false, .shape = .north_south }, .{ .powered = false, .shape = .east_west }, .{ .powered = false, .shape = .ascending_east }, .{ .powered = false, .shape = .ascending_west }, .{ .powered = false, .shape = .ascending_north }, .{ .powered = false, .shape = .ascending_south }, undefined, undefined, .{ .powered = true, .shape = .north_south }, .{ .powered = true, .shape = .east_west }, .{ .powered = true, .shape = .ascending_east }, .{ .powered = true, .shape = .ascending_west }, .{ .powered = true, .shape = .ascending_north }, .{ .powered = true, .shape = .ascending_south }, undefined, undefined })));
    table.set(.sticky_piston, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.sticky_piston, 16, .{ .{ .facing = .down, .extended = false }, .{ .facing = .up, .extended = false }, .{ .facing = .north, .extended = false }, .{ .facing = .south, .extended = false }, .{ .facing = .west, .extended = false }, .{ .facing = .east, .extended = false }, undefined, undefined, .{ .facing = .down, .extended = true }, .{ .facing = .up, .extended = true }, .{ .facing = .north, .extended = true }, .{ .facing = .south, .extended = true }, .{ .facing = .west, .extended = true }, .{ .facing = .east, .extended = true }, undefined, undefined })));
    table.set(.web, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.web, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.tallgrass, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.tallgrass, 16, .{ .{ .variant = .dead_bush }, .{ .variant = .tall_grass }, .{ .variant = .fern }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.deadbush, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.deadbush, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.piston, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.piston, 16, .{ .{ .facing = .down, .extended = false }, .{ .facing = .up, .extended = false }, .{ .facing = .north, .extended = false }, .{ .facing = .south, .extended = false }, .{ .facing = .west, .extended = false }, .{ .facing = .east, .extended = false }, undefined, undefined, .{ .facing = .down, .extended = true }, .{ .facing = .up, .extended = true }, .{ .facing = .north, .extended = true }, .{ .facing = .south, .extended = true }, .{ .facing = .west, .extended = true }, .{ .facing = .east, .extended = true }, undefined, undefined })));
    table.set(.piston_head, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.piston_head, 16, .{ .{ .variant = .normal, .facing = .down }, .{ .variant = .normal, .facing = .up }, .{ .variant = .normal, .facing = .north }, .{ .variant = .normal, .facing = .south }, .{ .variant = .normal, .facing = .west }, .{ .variant = .normal, .facing = .east }, undefined, undefined, .{ .variant = .sticky, .facing = .down }, .{ .variant = .sticky, .facing = .up }, .{ .variant = .sticky, .facing = .north }, .{ .variant = .sticky, .facing = .south }, .{ .variant = .sticky, .facing = .west }, .{ .variant = .sticky, .facing = .east }, undefined, undefined })));
    table.set(.wool, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.wool, 16, .{ .{ .color = .white }, .{ .color = .orange }, .{ .color = .magenta }, .{ .color = .light_blue }, .{ .color = .yellow }, .{ .color = .lime }, .{ .color = .pink }, .{ .color = .gray }, .{ .color = .silver }, .{ .color = .cyan }, .{ .color = .purple }, .{ .color = .blue }, .{ .color = .brown }, .{ .color = .green }, .{ .color = .red }, .{ .color = .black } })));
    table.set(.piston_extension, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.piston_extension, 16, .{ .{ .variant = .normal, .facing = .down }, .{ .variant = .normal, .facing = .up }, .{ .variant = .normal, .facing = .north }, .{ .variant = .normal, .facing = .south }, .{ .variant = .normal, .facing = .west }, .{ .variant = .normal, .facing = .east }, undefined, undefined, .{ .variant = .sticky, .facing = .down }, .{ .variant = .sticky, .facing = .up }, .{ .variant = .sticky, .facing = .north }, .{ .variant = .sticky, .facing = .south }, .{ .variant = .sticky, .facing = .west }, .{ .variant = .sticky, .facing = .east }, undefined, undefined })));
    table.set(.yellow_flower, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.yellow_flower, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.red_flower, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.red_flower, 16, .{ .{ .variant = .poppy }, .{ .variant = .blue_orchid }, .{ .variant = .allium }, .{ .variant = .houstonia }, .{ .variant = .red_tulip }, .{ .variant = .orange_tulip }, .{ .variant = .white_tulip }, .{ .variant = .pink_tulip }, .{ .variant = .oxeye_daisy }, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.brown_mushroom, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.brown_mushroom, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.red_mushroom, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.red_mushroom, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.gold_block, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.gold_block, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.iron_block, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.iron_block, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.double_stone_slab, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.double_stone_slab, 16, .{ .{ .seamless = false, .variant = .stone }, .{ .seamless = false, .variant = .sandstone }, .{ .seamless = false, .variant = .wood_old }, .{ .seamless = false, .variant = .cobblestone }, .{ .seamless = false, .variant = .brick }, .{ .seamless = false, .variant = .stone_brick }, .{ .seamless = false, .variant = .nether_brick }, .{ .seamless = false, .variant = .quartz }, .{ .seamless = true, .variant = .stone }, .{ .seamless = true, .variant = .sandstone }, .{ .seamless = true, .variant = .wood_old }, .{ .seamless = true, .variant = .cobblestone }, .{ .seamless = true, .variant = .brick }, .{ .seamless = true, .variant = .stone_brick }, .{ .seamless = true, .variant = .nether_brick }, .{ .seamless = true, .variant = .quartz } })));
    table.set(.stone_slab, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.stone_slab, 16, .{ .{ .variant = .stone, .half = .bottom }, .{ .variant = .sandstone, .half = .bottom }, .{ .variant = .wood_old, .half = .bottom }, .{ .variant = .cobblestone, .half = .bottom }, .{ .variant = .brick, .half = .bottom }, .{ .variant = .stone_brick, .half = .bottom }, .{ .variant = .nether_brick, .half = .bottom }, .{ .variant = .quartz, .half = .bottom }, .{ .variant = .stone, .half = .top }, .{ .variant = .sandstone, .half = .top }, .{ .variant = .wood_old, .half = .top }, .{ .variant = .cobblestone, .half = .top }, .{ .variant = .brick, .half = .top }, .{ .variant = .stone_brick, .half = .top }, .{ .variant = .nether_brick, .half = .top }, .{ .variant = .quartz, .half = .top } })));
    table.set(.brick_block, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.brick_block, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.tnt, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.tnt, 16, .{ .{ .explode = false }, .{ .explode = true }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.bookshelf, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.bookshelf, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.mossy_cobblestone, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.mossy_cobblestone, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.obsidian, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.obsidian, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.torch, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.torch, 16, .{ undefined, .{ .facing = .east }, .{ .facing = .west }, .{ .facing = .south }, .{ .facing = .north }, .{ .facing = .up }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.fire, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.fire, 16, .{ .{ .age = 0 }, .{ .age = 1 }, .{ .age = 2 }, .{ .age = 3 }, .{ .age = 4 }, .{ .age = 5 }, .{ .age = 6 }, .{ .age = 7 }, .{ .age = 8 }, .{ .age = 9 }, .{ .age = 10 }, .{ .age = 11 }, .{ .age = 12 }, .{ .age = 13 }, .{ .age = 14 }, .{ .age = 15 } })));
    table.set(.mob_spawner, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.mob_spawner, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.oak_stairs, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.oak_stairs, 16, .{ .{ .half = .bottom, .facing = .east }, .{ .half = .bottom, .facing = .west }, .{ .half = .bottom, .facing = .south }, .{ .half = .bottom, .facing = .north }, .{ .half = .top, .facing = .east }, .{ .half = .top, .facing = .west }, .{ .half = .top, .facing = .south }, .{ .half = .top, .facing = .north }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.chest, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.chest, 16, .{ undefined, undefined, .{ .facing = .north }, .{ .facing = .south }, .{ .facing = .west }, .{ .facing = .east }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.redstone_wire, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.redstone_wire, 16, .{ .{ .power = 0 }, .{ .power = 1 }, .{ .power = 2 }, .{ .power = 3 }, .{ .power = 4 }, .{ .power = 5 }, .{ .power = 6 }, .{ .power = 7 }, .{ .power = 8 }, .{ .power = 9 }, .{ .power = 10 }, .{ .power = 11 }, .{ .power = 12 }, .{ .power = 13 }, .{ .power = 14 }, .{ .power = 15 } })));
    table.set(.diamond_ore, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.diamond_ore, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.diamond_block, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.diamond_block, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.crafting_table, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.crafting_table, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.wheat, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.wheat, 16, .{ .{ .age = 0 }, .{ .age = 1 }, .{ .age = 2 }, .{ .age = 3 }, .{ .age = 4 }, .{ .age = 5 }, .{ .age = 6 }, .{ .age = 7 }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.farmland, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.farmland, 16, .{ .{ .moisture = 0 }, .{ .moisture = 1 }, .{ .moisture = 2 }, .{ .moisture = 3 }, .{ .moisture = 4 }, .{ .moisture = 5 }, .{ .moisture = 6 }, .{ .moisture = 7 }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.furnace, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.furnace, 16, .{ undefined, undefined, .{ .facing = .north }, .{ .facing = .south }, .{ .facing = .west }, .{ .facing = .east }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.lit_furnace, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.lit_furnace, 16, .{ undefined, undefined, .{ .facing = .north }, .{ .facing = .south }, .{ .facing = .west }, .{ .facing = .east }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.standing_sign, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.standing_sign, 16, .{ .{ .rotation = 0 }, .{ .rotation = 1 }, .{ .rotation = 2 }, .{ .rotation = 3 }, .{ .rotation = 4 }, .{ .rotation = 5 }, .{ .rotation = 6 }, .{ .rotation = 7 }, .{ .rotation = 8 }, .{ .rotation = 9 }, .{ .rotation = 10 }, .{ .rotation = 11 }, .{ .rotation = 12 }, .{ .rotation = 13 }, .{ .rotation = 14 }, .{ .rotation = 15 } })));
    table.set(.wooden_door, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.wooden_door, 16, .{ .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .east } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .south } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .west } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .north } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .east } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .south } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .west } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .north } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = false, .hinge = .left } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = false, .hinge = .right } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = true, .hinge = .left } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = true, .hinge = .right } } }, undefined, undefined, undefined, undefined })));
    table.set(.ladder, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.ladder, 16, .{ undefined, undefined, .{ .facing = .north }, .{ .facing = .south }, .{ .facing = .west }, .{ .facing = .east }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.rail, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.rail, 16, .{ .{ .shape = .north_south }, .{ .shape = .east_west }, .{ .shape = .ascending_east }, .{ .shape = .ascending_west }, .{ .shape = .ascending_north }, .{ .shape = .ascending_south }, .{ .shape = .south_east }, .{ .shape = .south_west }, .{ .shape = .north_west }, .{ .shape = .north_east }, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.stone_stairs, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.stone_stairs, 16, .{ .{ .half = .bottom, .facing = .east }, .{ .half = .bottom, .facing = .west }, .{ .half = .bottom, .facing = .south }, .{ .half = .bottom, .facing = .north }, .{ .half = .top, .facing = .east }, .{ .half = .top, .facing = .west }, .{ .half = .top, .facing = .south }, .{ .half = .top, .facing = .north }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.wall_sign, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.wall_sign, 16, .{ undefined, undefined, .{ .facing = .north }, .{ .facing = .south }, .{ .facing = .west }, .{ .facing = .east }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.lever, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.lever, 16, .{ .{ .powered = false, .facing = .down_x }, .{ .powered = false, .facing = .east }, .{ .powered = false, .facing = .west }, .{ .powered = false, .facing = .south }, .{ .powered = false, .facing = .north }, .{ .powered = false, .facing = .up_z }, .{ .powered = false, .facing = .up_x }, .{ .powered = false, .facing = .down_z }, .{ .powered = true, .facing = .down_x }, .{ .powered = true, .facing = .east }, .{ .powered = true, .facing = .west }, .{ .powered = true, .facing = .south }, .{ .powered = true, .facing = .north }, .{ .powered = true, .facing = .up_z }, .{ .powered = true, .facing = .up_x }, .{ .powered = true, .facing = .down_z } })));
    table.set(.stone_pressure_plate, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.stone_pressure_plate, 16, .{ .{ .powered = false }, .{ .powered = true }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.iron_door, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.iron_door, 16, .{ .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .east } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .south } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .west } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .north } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .east } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .south } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .west } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .north } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = false, .hinge = .left } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = false, .hinge = .right } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = true, .hinge = .left } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = true, .hinge = .right } } }, undefined, undefined, undefined, undefined })));
    table.set(.wooden_pressure_plate, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.wooden_pressure_plate, 16, .{ .{ .powered = false }, .{ .powered = true }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.redstone_ore, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.redstone_ore, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.lit_redstone_ore, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.lit_redstone_ore, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.unlit_redstone_torch, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.unlit_redstone_torch, 16, .{ undefined, .{ .facing = .east }, .{ .facing = .west }, .{ .facing = .south }, .{ .facing = .north }, .{ .facing = .up }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.redstone_torch, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.redstone_torch, 16, .{ undefined, .{ .facing = .east }, .{ .facing = .west }, .{ .facing = .south }, .{ .facing = .north }, .{ .facing = .up }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.stone_button, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.stone_button, 16, .{ .{ .powered = false, .facing = .down }, .{ .powered = false, .facing = .east }, .{ .powered = false, .facing = .west }, .{ .powered = false, .facing = .south }, .{ .powered = false, .facing = .north }, .{ .powered = false, .facing = .up }, undefined, undefined, .{ .powered = true, .facing = .down }, .{ .powered = true, .facing = .east }, .{ .powered = true, .facing = .west }, .{ .powered = true, .facing = .south }, .{ .powered = true, .facing = .north }, .{ .powered = true, .facing = .up }, undefined, undefined })));
    table.set(.snow_layer, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.snow_layer, 16, .{ .{ .layers = 0 }, .{ .layers = 1 }, .{ .layers = 2 }, .{ .layers = 3 }, .{ .layers = 4 }, .{ .layers = 5 }, .{ .layers = 6 }, .{ .layers = 7 }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.ice, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.ice, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.snow, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.snow, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.cactus, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.cactus, 16, .{ .{ .age = 0 }, .{ .age = 1 }, .{ .age = 2 }, .{ .age = 3 }, .{ .age = 4 }, .{ .age = 5 }, .{ .age = 6 }, .{ .age = 7 }, .{ .age = 8 }, .{ .age = 9 }, .{ .age = 10 }, .{ .age = 11 }, .{ .age = 12 }, .{ .age = 13 }, .{ .age = 14 }, .{ .age = 15 } })));
    table.set(.clay, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.clay, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.reeds, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.reeds, 16, .{ .{ .age = 0 }, .{ .age = 1 }, .{ .age = 2 }, .{ .age = 3 }, .{ .age = 4 }, .{ .age = 5 }, .{ .age = 6 }, .{ .age = 7 }, .{ .age = 8 }, .{ .age = 9 }, .{ .age = 10 }, .{ .age = 11 }, .{ .age = 12 }, .{ .age = 13 }, .{ .age = 14 }, .{ .age = 15 } })));
    table.set(.jukebox, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.jukebox, 16, .{ .{ .has_record = false }, .{ .has_record = true }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.fence, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.fence, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.pumpkin, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.pumpkin, 16, .{ .{ .facing = .south }, .{ .facing = .west }, .{ .facing = .north }, .{ .facing = .east }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.netherrack, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.netherrack, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.soul_sand, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.soul_sand, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.glowstone, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.glowstone, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.portal, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.portal, 16, .{ undefined, .{ .axis = .x }, .{ .axis = .z }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.lit_pumpkin, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.lit_pumpkin, 16, .{ .{ .facing = .south }, .{ .facing = .west }, .{ .facing = .north }, .{ .facing = .east }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.cake, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.cake, 16, .{ .{ .bites = 0 }, .{ .bites = 1 }, .{ .bites = 2 }, .{ .bites = 3 }, .{ .bites = 4 }, .{ .bites = 5 }, .{ .bites = 6 }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.unpowered_repeater, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.unpowered_repeater, 16, .{ .{ .delay = 0, .facing = .south }, .{ .delay = 0, .facing = .west }, .{ .delay = 0, .facing = .north }, .{ .delay = 0, .facing = .east }, .{ .delay = 1, .facing = .south }, .{ .delay = 1, .facing = .west }, .{ .delay = 1, .facing = .north }, .{ .delay = 1, .facing = .east }, .{ .delay = 2, .facing = .south }, .{ .delay = 2, .facing = .west }, .{ .delay = 2, .facing = .north }, .{ .delay = 2, .facing = .east }, .{ .delay = 3, .facing = .south }, .{ .delay = 3, .facing = .west }, .{ .delay = 3, .facing = .north }, .{ .delay = 3, .facing = .east } })));
    table.set(.powered_repeater, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.powered_repeater, 16, .{ .{ .delay = 0, .facing = .south }, .{ .delay = 0, .facing = .west }, .{ .delay = 0, .facing = .north }, .{ .delay = 0, .facing = .east }, .{ .delay = 1, .facing = .south }, .{ .delay = 1, .facing = .west }, .{ .delay = 1, .facing = .north }, .{ .delay = 1, .facing = .east }, .{ .delay = 2, .facing = .south }, .{ .delay = 2, .facing = .west }, .{ .delay = 2, .facing = .north }, .{ .delay = 2, .facing = .east }, .{ .delay = 3, .facing = .south }, .{ .delay = 3, .facing = .west }, .{ .delay = 3, .facing = .north }, .{ .delay = 3, .facing = .east } })));
    table.set(.stained_glass, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.stained_glass, 16, .{ .{ .color = .white }, .{ .color = .orange }, .{ .color = .magenta }, .{ .color = .light_blue }, .{ .color = .yellow }, .{ .color = .lime }, .{ .color = .pink }, .{ .color = .gray }, .{ .color = .silver }, .{ .color = .cyan }, .{ .color = .purple }, .{ .color = .blue }, .{ .color = .brown }, .{ .color = .green }, .{ .color = .red }, .{ .color = .black } })));
    table.set(.trapdoor, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.trapdoor, 16, .{ .{ .open = false, .half = .bottom, .facing = .north }, .{ .open = false, .half = .bottom, .facing = .south }, .{ .open = false, .half = .bottom, .facing = .west }, .{ .open = false, .half = .bottom, .facing = .east }, .{ .open = true, .half = .bottom, .facing = .north }, .{ .open = true, .half = .bottom, .facing = .south }, .{ .open = true, .half = .bottom, .facing = .west }, .{ .open = true, .half = .bottom, .facing = .east }, .{ .open = false, .half = .top, .facing = .north }, .{ .open = false, .half = .top, .facing = .south }, .{ .open = false, .half = .top, .facing = .west }, .{ .open = false, .half = .top, .facing = .east }, .{ .open = true, .half = .top, .facing = .north }, .{ .open = true, .half = .top, .facing = .south }, .{ .open = true, .half = .top, .facing = .west }, .{ .open = true, .half = .top, .facing = .east } })));
    table.set(.monster_egg, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.monster_egg, 16, .{ .{ .variant = .stone }, .{ .variant = .cobblestone }, .{ .variant = .stone_brick }, .{ .variant = .mossy_brick }, .{ .variant = .cracked_brick }, .{ .variant = .chiseled_brick }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.stonebrick, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.stonebrick, 16, .{ .{ .variant = .stonebrick }, .{ .variant = .mossy_stonebrick }, .{ .variant = .cracked_stonebrick }, .{ .variant = .chiseled_stonebrick }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.brown_mushroom_block, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.brown_mushroom_block, 16, .{ .{ .variant = .all_inside }, .{ .variant = .north_west }, .{ .variant = .north }, .{ .variant = .north_east }, .{ .variant = .west }, .{ .variant = .center }, .{ .variant = .east }, .{ .variant = .south_west }, .{ .variant = .south }, .{ .variant = .south_east }, .{ .variant = .stem }, undefined, undefined, undefined, .{ .variant = .all_outside }, .{ .variant = .all_stem } })));
    table.set(.red_mushroom_block, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.red_mushroom_block, 16, .{ .{ .variant = .all_inside }, .{ .variant = .north_west }, .{ .variant = .north }, .{ .variant = .north_east }, .{ .variant = .west }, .{ .variant = .center }, .{ .variant = .east }, .{ .variant = .south_west }, .{ .variant = .south }, .{ .variant = .south_east }, .{ .variant = .stem }, undefined, undefined, undefined, .{ .variant = .all_outside }, .{ .variant = .all_stem } })));
    table.set(.iron_bars, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.iron_bars, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.glass_pane, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.glass_pane, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.melon_block, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.melon_block, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.pumpkin_stem, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.pumpkin_stem, 16, .{ .{ .age = 0 }, .{ .age = 1 }, .{ .age = 2 }, .{ .age = 3 }, .{ .age = 4 }, .{ .age = 5 }, .{ .age = 6 }, .{ .age = 7 }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.melon_stem, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.melon_stem, 16, .{ .{ .age = 0 }, .{ .age = 1 }, .{ .age = 2 }, .{ .age = 3 }, .{ .age = 4 }, .{ .age = 5 }, .{ .age = 6 }, .{ .age = 7 }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.vine, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.vine, 16, .{ .{ .west = false, .south = false, .north = false, .east = false }, .{ .west = false, .south = true, .north = false, .east = false }, .{ .west = true, .south = false, .north = false, .east = false }, .{ .west = true, .south = true, .north = false, .east = false }, .{ .west = false, .south = false, .north = true, .east = false }, .{ .west = false, .south = true, .north = true, .east = false }, .{ .west = true, .south = false, .north = true, .east = false }, .{ .west = true, .south = true, .north = true, .east = false }, .{ .west = false, .south = false, .north = false, .east = true }, .{ .west = false, .south = true, .north = false, .east = true }, .{ .west = true, .south = false, .north = false, .east = true }, .{ .west = true, .south = true, .north = false, .east = true }, .{ .west = false, .south = false, .north = true, .east = true }, .{ .west = false, .south = true, .north = true, .east = true }, .{ .west = true, .south = false, .north = true, .east = true }, .{ .west = true, .south = true, .north = true, .east = true } })));
    table.set(.fence_gate, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.fence_gate, 16, .{ .{ .open = false, .powered = false, .facing = .south }, .{ .open = false, .powered = false, .facing = .west }, .{ .open = false, .powered = false, .facing = .north }, .{ .open = false, .powered = false, .facing = .east }, .{ .open = true, .powered = false, .facing = .south }, .{ .open = true, .powered = false, .facing = .west }, .{ .open = true, .powered = false, .facing = .north }, .{ .open = true, .powered = false, .facing = .east }, .{ .open = false, .powered = true, .facing = .south }, .{ .open = false, .powered = true, .facing = .west }, .{ .open = false, .powered = true, .facing = .north }, .{ .open = false, .powered = true, .facing = .east }, .{ .open = true, .powered = true, .facing = .south }, .{ .open = true, .powered = true, .facing = .west }, .{ .open = true, .powered = true, .facing = .north }, .{ .open = true, .powered = true, .facing = .east } })));
    table.set(.brick_stairs, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.brick_stairs, 16, .{ .{ .half = .bottom, .facing = .east }, .{ .half = .bottom, .facing = .west }, .{ .half = .bottom, .facing = .south }, .{ .half = .bottom, .facing = .north }, .{ .half = .top, .facing = .east }, .{ .half = .top, .facing = .west }, .{ .half = .top, .facing = .south }, .{ .half = .top, .facing = .north }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.stone_brick_stairs, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.stone_brick_stairs, 16, .{ .{ .half = .bottom, .facing = .east }, .{ .half = .bottom, .facing = .west }, .{ .half = .bottom, .facing = .south }, .{ .half = .bottom, .facing = .north }, .{ .half = .top, .facing = .east }, .{ .half = .top, .facing = .west }, .{ .half = .top, .facing = .south }, .{ .half = .top, .facing = .north }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.mycelium, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.mycelium, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.waterlily, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.waterlily, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.nether_brick, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.nether_brick, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.nether_brick_fence, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.nether_brick_fence, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.nether_brick_stairs, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.nether_brick_stairs, 16, .{ .{ .half = .bottom, .facing = .east }, .{ .half = .bottom, .facing = .west }, .{ .half = .bottom, .facing = .south }, .{ .half = .bottom, .facing = .north }, .{ .half = .top, .facing = .east }, .{ .half = .top, .facing = .west }, .{ .half = .top, .facing = .south }, .{ .half = .top, .facing = .north }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.nether_wart, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.nether_wart, 16, .{ .{ .age = 0 }, .{ .age = 1 }, .{ .age = 2 }, .{ .age = 3 }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.enchanting_table, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.enchanting_table, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.brewing_stand, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.brewing_stand, 16, .{ .{ .has_bottle_2 = false, .has_bottle_0 = false, .has_bottle_1 = false }, .{ .has_bottle_2 = false, .has_bottle_0 = true, .has_bottle_1 = false }, .{ .has_bottle_2 = false, .has_bottle_0 = false, .has_bottle_1 = true }, .{ .has_bottle_2 = false, .has_bottle_0 = true, .has_bottle_1 = true }, .{ .has_bottle_2 = true, .has_bottle_0 = false, .has_bottle_1 = false }, .{ .has_bottle_2 = true, .has_bottle_0 = true, .has_bottle_1 = false }, .{ .has_bottle_2 = true, .has_bottle_0 = false, .has_bottle_1 = true }, .{ .has_bottle_2 = true, .has_bottle_0 = true, .has_bottle_1 = true }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.cauldron, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.cauldron, 16, .{ .{ .level = 0 }, .{ .level = 1 }, .{ .level = 2 }, .{ .level = 3 }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.end_portal, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.end_portal, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.end_portal_frame, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.end_portal_frame, 16, .{ .{ .eye = false, .facing = .south }, .{ .eye = false, .facing = .west }, .{ .eye = false, .facing = .north }, .{ .eye = false, .facing = .east }, .{ .eye = true, .facing = .south }, .{ .eye = true, .facing = .west }, .{ .eye = true, .facing = .north }, .{ .eye = true, .facing = .east }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.end_stone, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.end_stone, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.dragon_egg, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.dragon_egg, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.redstone_lamp, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.redstone_lamp, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.lit_redstone_lamp, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.lit_redstone_lamp, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.double_wooden_slab, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.double_wooden_slab, 16, .{ .{ .variant = .oak }, .{ .variant = .spruce }, .{ .variant = .birch }, .{ .variant = .jungle }, .{ .variant = .acacia }, .{ .variant = .dark_oak }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.wooden_slab, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.wooden_slab, 16, .{ .{ .variant = .oak, .half = .bottom }, .{ .variant = .spruce, .half = .bottom }, .{ .variant = .birch, .half = .bottom }, .{ .variant = .jungle, .half = .bottom }, .{ .variant = .acacia, .half = .bottom }, .{ .variant = .dark_oak, .half = .bottom }, undefined, undefined, .{ .variant = .oak, .half = .top }, .{ .variant = .spruce, .half = .top }, .{ .variant = .birch, .half = .top }, .{ .variant = .jungle, .half = .top }, .{ .variant = .acacia, .half = .top }, .{ .variant = .dark_oak, .half = .top }, undefined, undefined })));
    table.set(.cocoa, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.cocoa, 16, .{ .{ .age = 0, .facing = .south }, .{ .age = 0, .facing = .west }, .{ .age = 0, .facing = .north }, .{ .age = 0, .facing = .east }, .{ .age = 1, .facing = .south }, .{ .age = 1, .facing = .west }, .{ .age = 1, .facing = .north }, .{ .age = 1, .facing = .east }, .{ .age = 2, .facing = .south }, .{ .age = 2, .facing = .west }, .{ .age = 2, .facing = .north }, .{ .age = 2, .facing = .east }, undefined, undefined, undefined, undefined })));
    table.set(.sandstone_stairs, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.sandstone_stairs, 16, .{ .{ .half = .bottom, .facing = .east }, .{ .half = .bottom, .facing = .west }, .{ .half = .bottom, .facing = .south }, .{ .half = .bottom, .facing = .north }, .{ .half = .top, .facing = .east }, .{ .half = .top, .facing = .west }, .{ .half = .top, .facing = .south }, .{ .half = .top, .facing = .north }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.emerald_ore, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.emerald_ore, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.ender_chest, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.ender_chest, 16, .{ undefined, undefined, .{ .facing = .north }, .{ .facing = .south }, .{ .facing = .west }, .{ .facing = .east }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.tripwire_hook, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.tripwire_hook, 16, .{ .{ .powered = false, .facing = .south, .attached = false }, .{ .powered = false, .facing = .west, .attached = false }, .{ .powered = false, .facing = .north, .attached = false }, .{ .powered = false, .facing = .east, .attached = false }, .{ .powered = false, .facing = .south, .attached = true }, .{ .powered = false, .facing = .west, .attached = true }, .{ .powered = false, .facing = .north, .attached = true }, .{ .powered = false, .facing = .east, .attached = true }, .{ .powered = true, .facing = .south, .attached = false }, .{ .powered = true, .facing = .west, .attached = false }, .{ .powered = true, .facing = .north, .attached = false }, .{ .powered = true, .facing = .east, .attached = false }, .{ .powered = true, .facing = .south, .attached = true }, .{ .powered = true, .facing = .west, .attached = true }, .{ .powered = true, .facing = .north, .attached = true }, .{ .powered = true, .facing = .east, .attached = true } })));
    table.set(.tripwire, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.tripwire, 16, .{ .{ .powered = false, .disarmed = false, .attached = false, .suspended = false }, .{ .powered = true, .disarmed = false, .attached = false, .suspended = false }, .{ .powered = false, .disarmed = false, .attached = false, .suspended = true }, .{ .powered = true, .disarmed = false, .attached = false, .suspended = true }, .{ .powered = false, .disarmed = false, .attached = true, .suspended = false }, .{ .powered = true, .disarmed = false, .attached = true, .suspended = false }, .{ .powered = false, .disarmed = false, .attached = true, .suspended = true }, .{ .powered = true, .disarmed = false, .attached = true, .suspended = true }, .{ .powered = false, .disarmed = true, .attached = false, .suspended = false }, .{ .powered = true, .disarmed = true, .attached = false, .suspended = false }, .{ .powered = false, .disarmed = true, .attached = false, .suspended = true }, .{ .powered = true, .disarmed = true, .attached = false, .suspended = true }, .{ .powered = false, .disarmed = true, .attached = true, .suspended = false }, .{ .powered = true, .disarmed = true, .attached = true, .suspended = false }, .{ .powered = false, .disarmed = true, .attached = true, .suspended = true }, .{ .powered = true, .disarmed = true, .attached = true, .suspended = true } })));
    table.set(.emerald_block, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.emerald_block, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.spruce_stairs, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.spruce_stairs, 16, .{ .{ .half = .bottom, .facing = .east }, .{ .half = .bottom, .facing = .west }, .{ .half = .bottom, .facing = .south }, .{ .half = .bottom, .facing = .north }, .{ .half = .top, .facing = .east }, .{ .half = .top, .facing = .west }, .{ .half = .top, .facing = .south }, .{ .half = .top, .facing = .north }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.birch_stairs, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.birch_stairs, 16, .{ .{ .half = .bottom, .facing = .east }, .{ .half = .bottom, .facing = .west }, .{ .half = .bottom, .facing = .south }, .{ .half = .bottom, .facing = .north }, .{ .half = .top, .facing = .east }, .{ .half = .top, .facing = .west }, .{ .half = .top, .facing = .south }, .{ .half = .top, .facing = .north }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.jungle_stairs, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.jungle_stairs, 16, .{ .{ .half = .bottom, .facing = .east }, .{ .half = .bottom, .facing = .west }, .{ .half = .bottom, .facing = .south }, .{ .half = .bottom, .facing = .north }, .{ .half = .top, .facing = .east }, .{ .half = .top, .facing = .west }, .{ .half = .top, .facing = .south }, .{ .half = .top, .facing = .north }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.command_block, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.command_block, 16, .{ .{ .triggered = false }, .{ .triggered = true }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.beacon, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.beacon, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.cobblestone_wall, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.cobblestone_wall, 16, .{ .{ .variant = .cobblestone }, .{ .variant = .mossy_cobblestone }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.flower_pot, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.flower_pot, 16, .{ .{}, .{}, .{}, .{}, .{}, .{}, .{}, .{}, .{}, .{}, .{}, .{}, .{}, .{}, .{}, .{} })));
    table.set(.carrots, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.carrots, 16, .{ .{ .age = 0 }, .{ .age = 1 }, .{ .age = 2 }, .{ .age = 3 }, .{ .age = 4 }, .{ .age = 5 }, .{ .age = 6 }, .{ .age = 7 }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.potatoes, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.potatoes, 16, .{ .{ .age = 0 }, .{ .age = 1 }, .{ .age = 2 }, .{ .age = 3 }, .{ .age = 4 }, .{ .age = 5 }, .{ .age = 6 }, .{ .age = 7 }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.wooden_button, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.wooden_button, 16, .{ .{ .powered = false, .facing = .down }, .{ .powered = false, .facing = .east }, .{ .powered = false, .facing = .west }, .{ .powered = false, .facing = .south }, .{ .powered = false, .facing = .north }, .{ .powered = false, .facing = .up }, undefined, undefined, .{ .powered = true, .facing = .down }, .{ .powered = true, .facing = .east }, .{ .powered = true, .facing = .west }, .{ .powered = true, .facing = .south }, .{ .powered = true, .facing = .north }, .{ .powered = true, .facing = .up }, undefined, undefined })));
    table.set(.skull, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.skull, 16, .{ .{ .facing = .down, .nodrop = false }, .{ .facing = .up, .nodrop = false }, .{ .facing = .north, .nodrop = false }, .{ .facing = .south, .nodrop = false }, .{ .facing = .west, .nodrop = false }, .{ .facing = .east, .nodrop = false }, undefined, undefined, .{ .facing = .down, .nodrop = true }, .{ .facing = .up, .nodrop = true }, .{ .facing = .north, .nodrop = true }, .{ .facing = .south, .nodrop = true }, .{ .facing = .west, .nodrop = true }, .{ .facing = .east, .nodrop = true }, undefined, undefined })));
    table.set(.anvil, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.anvil, 16, .{ .{ .damage = 0, .facing = .south }, .{ .damage = 0, .facing = .west }, .{ .damage = 0, .facing = .north }, .{ .damage = 0, .facing = .east }, .{ .damage = 1, .facing = .south }, .{ .damage = 1, .facing = .west }, .{ .damage = 1, .facing = .north }, .{ .damage = 1, .facing = .east }, .{ .damage = 2, .facing = .south }, .{ .damage = 2, .facing = .west }, .{ .damage = 2, .facing = .north }, .{ .damage = 2, .facing = .east }, undefined, undefined, undefined, undefined })));
    table.set(.trapped_chest, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.trapped_chest, 16, .{ undefined, undefined, .{ .facing = .north }, .{ .facing = .south }, .{ .facing = .west }, .{ .facing = .east }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.light_weighted_pressure_plate, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.light_weighted_pressure_plate, 16, .{ .{ .power = 0 }, .{ .power = 1 }, .{ .power = 2 }, .{ .power = 3 }, .{ .power = 4 }, .{ .power = 5 }, .{ .power = 6 }, .{ .power = 7 }, .{ .power = 8 }, .{ .power = 9 }, .{ .power = 10 }, .{ .power = 11 }, .{ .power = 12 }, .{ .power = 13 }, .{ .power = 14 }, .{ .power = 15 } })));
    table.set(.heavy_weighted_pressure_plate, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.heavy_weighted_pressure_plate, 16, .{ .{ .power = 0 }, .{ .power = 1 }, .{ .power = 2 }, .{ .power = 3 }, .{ .power = 4 }, .{ .power = 5 }, .{ .power = 6 }, .{ .power = 7 }, .{ .power = 8 }, .{ .power = 9 }, .{ .power = 10 }, .{ .power = 11 }, .{ .power = 12 }, .{ .power = 13 }, .{ .power = 14 }, .{ .power = 15 } })));
    table.set(.unpowered_comparator, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.unpowered_comparator, 16, .{ .{ .powered = false, .mode = .compare, .facing = .south }, .{ .powered = false, .mode = .compare, .facing = .west }, .{ .powered = false, .mode = .compare, .facing = .north }, .{ .powered = false, .mode = .compare, .facing = .east }, .{ .powered = false, .mode = .subtract, .facing = .south }, .{ .powered = false, .mode = .subtract, .facing = .west }, .{ .powered = false, .mode = .subtract, .facing = .north }, .{ .powered = false, .mode = .subtract, .facing = .east }, .{ .powered = true, .mode = .compare, .facing = .south }, .{ .powered = true, .mode = .compare, .facing = .west }, .{ .powered = true, .mode = .compare, .facing = .north }, .{ .powered = true, .mode = .compare, .facing = .east }, .{ .powered = true, .mode = .subtract, .facing = .south }, .{ .powered = true, .mode = .subtract, .facing = .west }, .{ .powered = true, .mode = .subtract, .facing = .north }, .{ .powered = true, .mode = .subtract, .facing = .east } })));
    table.set(.powered_comparator, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.powered_comparator, 16, .{ .{ .powered = false, .mode = .compare, .facing = .south }, .{ .powered = false, .mode = .compare, .facing = .west }, .{ .powered = false, .mode = .compare, .facing = .north }, .{ .powered = false, .mode = .compare, .facing = .east }, .{ .powered = false, .mode = .subtract, .facing = .south }, .{ .powered = false, .mode = .subtract, .facing = .west }, .{ .powered = false, .mode = .subtract, .facing = .north }, .{ .powered = false, .mode = .subtract, .facing = .east }, .{ .powered = true, .mode = .compare, .facing = .south }, .{ .powered = true, .mode = .compare, .facing = .west }, .{ .powered = true, .mode = .compare, .facing = .north }, .{ .powered = true, .mode = .compare, .facing = .east }, .{ .powered = true, .mode = .subtract, .facing = .south }, .{ .powered = true, .mode = .subtract, .facing = .west }, .{ .powered = true, .mode = .subtract, .facing = .north }, .{ .powered = true, .mode = .subtract, .facing = .east } })));
    table.set(.daylight_detector, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.daylight_detector, 16, .{ .{ .power = 0 }, .{ .power = 1 }, .{ .power = 2 }, .{ .power = 3 }, .{ .power = 4 }, .{ .power = 5 }, .{ .power = 6 }, .{ .power = 7 }, .{ .power = 8 }, .{ .power = 9 }, .{ .power = 10 }, .{ .power = 11 }, .{ .power = 12 }, .{ .power = 13 }, .{ .power = 14 }, .{ .power = 15 } })));
    table.set(.redstone_block, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.redstone_block, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.quartz_ore, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.quartz_ore, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.hopper, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.hopper, 16, .{ .{ .facing = .down, .enabled = true }, undefined, .{ .facing = .north, .enabled = true }, .{ .facing = .south, .enabled = true }, .{ .facing = .west, .enabled = true }, .{ .facing = .east, .enabled = true }, undefined, undefined, .{ .facing = .down, .enabled = false }, undefined, .{ .facing = .north, .enabled = false }, .{ .facing = .south, .enabled = false }, .{ .facing = .west, .enabled = false }, .{ .facing = .east, .enabled = false }, undefined, undefined })));
    table.set(.quartz_block, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.quartz_block, 16, .{ .{ .variant = .default }, .{ .variant = .chiseled }, .{ .variant = .lines_x }, .{ .variant = .lines_y }, .{ .variant = .lines_z }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.quartz_stairs, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.quartz_stairs, 16, .{ .{ .half = .bottom, .facing = .east }, .{ .half = .bottom, .facing = .west }, .{ .half = .bottom, .facing = .south }, .{ .half = .bottom, .facing = .north }, .{ .half = .top, .facing = .east }, .{ .half = .top, .facing = .west }, .{ .half = .top, .facing = .south }, .{ .half = .top, .facing = .north }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.activator_rail, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.activator_rail, 16, .{ .{ .powered = false, .shape = .north_south }, .{ .powered = false, .shape = .east_west }, .{ .powered = false, .shape = .ascending_east }, .{ .powered = false, .shape = .ascending_west }, .{ .powered = false, .shape = .ascending_north }, .{ .powered = false, .shape = .ascending_south }, undefined, undefined, .{ .powered = true, .shape = .north_south }, .{ .powered = true, .shape = .east_west }, .{ .powered = true, .shape = .ascending_east }, .{ .powered = true, .shape = .ascending_west }, .{ .powered = true, .shape = .ascending_north }, .{ .powered = true, .shape = .ascending_south }, undefined, undefined })));
    table.set(.dropper, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.dropper, 16, .{ .{ .triggered = false, .facing = .down }, .{ .triggered = false, .facing = .up }, .{ .triggered = false, .facing = .north }, .{ .triggered = false, .facing = .south }, .{ .triggered = false, .facing = .west }, .{ .triggered = false, .facing = .east }, undefined, undefined, .{ .triggered = true, .facing = .down }, .{ .triggered = true, .facing = .up }, .{ .triggered = true, .facing = .north }, .{ .triggered = true, .facing = .south }, .{ .triggered = true, .facing = .west }, .{ .triggered = true, .facing = .east }, undefined, undefined })));
    table.set(.stained_hardened_clay, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.stained_hardened_clay, 16, .{ .{ .color = .white }, .{ .color = .orange }, .{ .color = .magenta }, .{ .color = .light_blue }, .{ .color = .yellow }, .{ .color = .lime }, .{ .color = .pink }, .{ .color = .gray }, .{ .color = .silver }, .{ .color = .cyan }, .{ .color = .purple }, .{ .color = .blue }, .{ .color = .brown }, .{ .color = .green }, .{ .color = .red }, .{ .color = .black } })));
    table.set(.stained_glass_pane, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.stained_glass_pane, 16, .{ .{ .color = .white }, .{ .color = .orange }, .{ .color = .magenta }, .{ .color = .light_blue }, .{ .color = .yellow }, .{ .color = .lime }, .{ .color = .pink }, .{ .color = .gray }, .{ .color = .silver }, .{ .color = .cyan }, .{ .color = .purple }, .{ .color = .blue }, .{ .color = .brown }, .{ .color = .green }, .{ .color = .red }, .{ .color = .black } })));
    table.set(.leaves2, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.leaves2, 16, .{ .{ .variant = .acacia, .check_decay = false, .decayable = true }, .{ .variant = .dark_oak, .check_decay = false, .decayable = true }, undefined, undefined, .{ .variant = .acacia, .check_decay = false, .decayable = false }, .{ .variant = .dark_oak, .check_decay = false, .decayable = false }, undefined, undefined, .{ .variant = .acacia, .check_decay = true, .decayable = true }, .{ .variant = .dark_oak, .check_decay = true, .decayable = true }, undefined, undefined, .{ .variant = .acacia, .check_decay = true, .decayable = false }, .{ .variant = .dark_oak, .check_decay = true, .decayable = false }, undefined, undefined })));
    table.set(.log2, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.log2, 16, .{ .{ .axis = .y, .variant = .acacia }, .{ .axis = .y, .variant = .dark_oak }, undefined, undefined, .{ .axis = .x, .variant = .acacia }, .{ .axis = .x, .variant = .dark_oak }, undefined, undefined, .{ .axis = .z, .variant = .acacia }, .{ .axis = .z, .variant = .dark_oak }, undefined, undefined, .{ .axis = .none, .variant = .acacia }, .{ .axis = .none, .variant = .dark_oak }, undefined, undefined })));
    table.set(.acacia_stairs, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.acacia_stairs, 16, .{ .{ .half = .bottom, .facing = .east }, .{ .half = .bottom, .facing = .west }, .{ .half = .bottom, .facing = .south }, .{ .half = .bottom, .facing = .north }, .{ .half = .top, .facing = .east }, .{ .half = .top, .facing = .west }, .{ .half = .top, .facing = .south }, .{ .half = .top, .facing = .north }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.dark_oak_stairs, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.dark_oak_stairs, 16, .{ .{ .half = .bottom, .facing = .east }, .{ .half = .bottom, .facing = .west }, .{ .half = .bottom, .facing = .south }, .{ .half = .bottom, .facing = .north }, .{ .half = .top, .facing = .east }, .{ .half = .top, .facing = .west }, .{ .half = .top, .facing = .south }, .{ .half = .top, .facing = .north }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.slime, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.slime, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.barrier, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.barrier, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.iron_trapdoor, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.iron_trapdoor, 16, .{ .{ .open = false, .half = .bottom, .facing = .north }, .{ .open = false, .half = .bottom, .facing = .south }, .{ .open = false, .half = .bottom, .facing = .west }, .{ .open = false, .half = .bottom, .facing = .east }, .{ .open = true, .half = .bottom, .facing = .north }, .{ .open = true, .half = .bottom, .facing = .south }, .{ .open = true, .half = .bottom, .facing = .west }, .{ .open = true, .half = .bottom, .facing = .east }, .{ .open = false, .half = .top, .facing = .north }, .{ .open = false, .half = .top, .facing = .south }, .{ .open = false, .half = .top, .facing = .west }, .{ .open = false, .half = .top, .facing = .east }, .{ .open = true, .half = .top, .facing = .north }, .{ .open = true, .half = .top, .facing = .south }, .{ .open = true, .half = .top, .facing = .west }, .{ .open = true, .half = .top, .facing = .east } })));
    table.set(.prismarine, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.prismarine, 16, .{ .{ .variant = .prismarine }, .{ .variant = .prismarine_bricks }, .{ .variant = .dark_prismarine }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.sea_lantern, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.sea_lantern, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.hay_block, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.hay_block, 16, .{ .{ .axis = .y }, undefined, undefined, undefined, .{ .axis = .x }, undefined, undefined, undefined, .{ .axis = .z }, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.carpet, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.carpet, 16, .{ .{ .color = .white }, .{ .color = .orange }, .{ .color = .magenta }, .{ .color = .light_blue }, .{ .color = .yellow }, .{ .color = .lime }, .{ .color = .pink }, .{ .color = .gray }, .{ .color = .silver }, .{ .color = .cyan }, .{ .color = .purple }, .{ .color = .blue }, .{ .color = .brown }, .{ .color = .green }, .{ .color = .red }, .{ .color = .black } })));
    table.set(.hardened_clay, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.hardened_clay, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.coal_block, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.coal_block, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.packed_ice, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.packed_ice, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.double_plant, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.double_plant, 16, .{ .{ .variant = .sunflower, .half = .lower }, .{ .variant = .syringa, .half = .lower }, .{ .variant = .double_grass, .half = .lower }, .{ .variant = .double_fern, .half = .lower }, .{ .variant = .double_rose, .half = .lower }, .{ .variant = .paeonia, .half = .lower }, undefined, undefined, .{ .variant = .paeonia, .half = .upper }, .{ .variant = .paeonia, .half = .upper }, .{ .variant = .paeonia, .half = .upper }, .{ .variant = .paeonia, .half = .upper }, undefined, undefined, undefined, undefined })));
    table.set(.standing_banner, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.standing_banner, 16, .{ .{ .rotation = 0 }, .{ .rotation = 1 }, .{ .rotation = 2 }, .{ .rotation = 3 }, .{ .rotation = 4 }, .{ .rotation = 5 }, .{ .rotation = 6 }, .{ .rotation = 7 }, .{ .rotation = 8 }, .{ .rotation = 9 }, .{ .rotation = 10 }, .{ .rotation = 11 }, .{ .rotation = 12 }, .{ .rotation = 13 }, .{ .rotation = 14 }, .{ .rotation = 15 } })));
    table.set(.wall_banner, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.wall_banner, 16, .{ undefined, undefined, .{ .facing = .north }, .{ .facing = .south }, .{ .facing = .west }, .{ .facing = .east }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.daylight_detector_inverted, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.daylight_detector_inverted, 16, .{ .{ .power = 0 }, .{ .power = 1 }, .{ .power = 2 }, .{ .power = 3 }, .{ .power = 4 }, .{ .power = 5 }, .{ .power = 6 }, .{ .power = 7 }, .{ .power = 8 }, .{ .power = 9 }, .{ .power = 10 }, .{ .power = 11 }, .{ .power = 12 }, .{ .power = 13 }, .{ .power = 14 }, .{ .power = 15 } })));
    table.set(.red_sandstone, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.red_sandstone, 16, .{ .{ .variant = .red_sandstone }, .{ .variant = .chiseled_red_sandstone }, .{ .variant = .smooth_red_sandstone }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.red_sandstone_stairs, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.red_sandstone_stairs, 16, .{ .{ .half = .bottom, .facing = .east }, .{ .half = .bottom, .facing = .west }, .{ .half = .bottom, .facing = .south }, .{ .half = .bottom, .facing = .north }, .{ .half = .top, .facing = .east }, .{ .half = .top, .facing = .west }, .{ .half = .top, .facing = .south }, .{ .half = .top, .facing = .north }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.double_stone_slab2, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.double_stone_slab2, 16, .{ .{ .seamless = false }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, .{ .seamless = true }, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.stone_slab2, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.stone_slab2, 16, .{ .{ .half = .bottom }, undefined, undefined, undefined, undefined, undefined, undefined, undefined, .{ .half = .top }, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.spruce_fence_gate, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.spruce_fence_gate, 16, .{ .{ .open = false, .powered = false, .facing = .south }, .{ .open = false, .powered = false, .facing = .west }, .{ .open = false, .powered = false, .facing = .north }, .{ .open = false, .powered = false, .facing = .east }, .{ .open = true, .powered = false, .facing = .south }, .{ .open = true, .powered = false, .facing = .west }, .{ .open = true, .powered = false, .facing = .north }, .{ .open = true, .powered = false, .facing = .east }, .{ .open = false, .powered = true, .facing = .south }, .{ .open = false, .powered = true, .facing = .west }, .{ .open = false, .powered = true, .facing = .north }, .{ .open = false, .powered = true, .facing = .east }, .{ .open = true, .powered = true, .facing = .south }, .{ .open = true, .powered = true, .facing = .west }, .{ .open = true, .powered = true, .facing = .north }, .{ .open = true, .powered = true, .facing = .east } })));
    table.set(.birch_fence_gate, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.birch_fence_gate, 16, .{ .{ .open = false, .powered = false, .facing = .south }, .{ .open = false, .powered = false, .facing = .west }, .{ .open = false, .powered = false, .facing = .north }, .{ .open = false, .powered = false, .facing = .east }, .{ .open = true, .powered = false, .facing = .south }, .{ .open = true, .powered = false, .facing = .west }, .{ .open = true, .powered = false, .facing = .north }, .{ .open = true, .powered = false, .facing = .east }, .{ .open = false, .powered = true, .facing = .south }, .{ .open = false, .powered = true, .facing = .west }, .{ .open = false, .powered = true, .facing = .north }, .{ .open = false, .powered = true, .facing = .east }, .{ .open = true, .powered = true, .facing = .south }, .{ .open = true, .powered = true, .facing = .west }, .{ .open = true, .powered = true, .facing = .north }, .{ .open = true, .powered = true, .facing = .east } })));
    table.set(.jungle_fence_gate, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.jungle_fence_gate, 16, .{ .{ .open = false, .powered = false, .facing = .south }, .{ .open = false, .powered = false, .facing = .west }, .{ .open = false, .powered = false, .facing = .north }, .{ .open = false, .powered = false, .facing = .east }, .{ .open = true, .powered = false, .facing = .south }, .{ .open = true, .powered = false, .facing = .west }, .{ .open = true, .powered = false, .facing = .north }, .{ .open = true, .powered = false, .facing = .east }, .{ .open = false, .powered = true, .facing = .south }, .{ .open = false, .powered = true, .facing = .west }, .{ .open = false, .powered = true, .facing = .north }, .{ .open = false, .powered = true, .facing = .east }, .{ .open = true, .powered = true, .facing = .south }, .{ .open = true, .powered = true, .facing = .west }, .{ .open = true, .powered = true, .facing = .north }, .{ .open = true, .powered = true, .facing = .east } })));
    table.set(.dark_oak_fence_gate, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.dark_oak_fence_gate, 16, .{ .{ .open = false, .powered = false, .facing = .south }, .{ .open = false, .powered = false, .facing = .west }, .{ .open = false, .powered = false, .facing = .north }, .{ .open = false, .powered = false, .facing = .east }, .{ .open = true, .powered = false, .facing = .south }, .{ .open = true, .powered = false, .facing = .west }, .{ .open = true, .powered = false, .facing = .north }, .{ .open = true, .powered = false, .facing = .east }, .{ .open = false, .powered = true, .facing = .south }, .{ .open = false, .powered = true, .facing = .west }, .{ .open = false, .powered = true, .facing = .north }, .{ .open = false, .powered = true, .facing = .east }, .{ .open = true, .powered = true, .facing = .south }, .{ .open = true, .powered = true, .facing = .west }, .{ .open = true, .powered = true, .facing = .north }, .{ .open = true, .powered = true, .facing = .east } })));
    table.set(.acacia_fence_gate, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.acacia_fence_gate, 16, .{ .{ .open = false, .powered = false, .facing = .south }, .{ .open = false, .powered = false, .facing = .west }, .{ .open = false, .powered = false, .facing = .north }, .{ .open = false, .powered = false, .facing = .east }, .{ .open = true, .powered = false, .facing = .south }, .{ .open = true, .powered = false, .facing = .west }, .{ .open = true, .powered = false, .facing = .north }, .{ .open = true, .powered = false, .facing = .east }, .{ .open = false, .powered = true, .facing = .south }, .{ .open = false, .powered = true, .facing = .west }, .{ .open = false, .powered = true, .facing = .north }, .{ .open = false, .powered = true, .facing = .east }, .{ .open = true, .powered = true, .facing = .south }, .{ .open = true, .powered = true, .facing = .west }, .{ .open = true, .powered = true, .facing = .north }, .{ .open = true, .powered = true, .facing = .east } })));
    table.set(.spruce_fence, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.spruce_fence, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.birch_fence, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.birch_fence, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.jungle_fence, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.jungle_fence, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.dark_oak_fence, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.dark_oak_fence, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.acacia_fence, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.acacia_fence, 16, .{ .{}, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined })));
    table.set(.spruce_door, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.spruce_door, 16, .{ .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .east } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .south } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .west } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .north } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .east } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .south } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .west } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .north } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = false, .hinge = .left } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = false, .hinge = .right } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = true, .hinge = .left } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = true, .hinge = .right } } }, undefined, undefined, undefined, undefined })));
    table.set(.birch_door, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.birch_door, 16, .{ .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .east } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .south } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .west } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .north } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .east } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .south } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .west } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .north } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = false, .hinge = .left } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = false, .hinge = .right } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = true, .hinge = .left } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = true, .hinge = .right } } }, undefined, undefined, undefined, undefined })));
    table.set(.jungle_door, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.jungle_door, 16, .{ .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .east } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .south } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .west } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .north } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .east } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .south } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .west } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .north } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = false, .hinge = .left } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = false, .hinge = .right } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = true, .hinge = .left } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = true, .hinge = .right } } }, undefined, undefined, undefined, undefined })));
    table.set(.acacia_door, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.acacia_door, 16, .{ .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .east } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .south } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .west } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .north } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .east } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .south } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .west } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .north } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = false, .hinge = .left } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = false, .hinge = .right } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = true, .hinge = .left } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = true, .hinge = .right } } }, undefined, undefined, undefined, undefined })));
    table.set(.dark_oak_door, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.dark_oak_door, 16, .{ .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .east } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .south } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .west } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = false, .facing = .north } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .east } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .south } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .west } } }, .{ .half = .lower, .other = .{ .when_lower = .{ .open = true, .facing = .north } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = false, .hinge = .left } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = false, .hinge = .right } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = true, .hinge = .left } } }, .{ .half = .upper, .other = .{ .when_upper = .{ .powered = true, .hinge = .right } } }, undefined, undefined, undefined, undefined })));

    break :blk table;
};

test ConcreteBlockState {
    std.debug.print("\n------------------\n", .{});
}
