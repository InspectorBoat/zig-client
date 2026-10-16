const std = @import("std");

const Block = @import("block.zig").Block;

pub const is_liquid: std.EnumSet(Material) = .initMany(&.{ .water, .lava });

pub const is_solid: std.EnumSet(Material) = .initMany(&.{ .grass, .dirt, .wood, .stone, .iron, .anvil, .leaves, .sponge, .wool, .sand, .glass, .redstone_lamp, .tnt, .coral, .ice, .packed_ice, .snow, .cactus, .clay, .pumpkin, .egg, .cake, .cobweb, .piston, .barrier });

pub const is_opaque: std.EnumSet(Material) = .initMany(&.{ .grass, .dirt, .wood, .stone, .iron, .anvil, .water, .lava, .leaves, .sponge, .wool, .sand, .glass, .redstone_lamp, .tnt, .coral, .ice, .packed_ice, .snow, .cactus, .clay, .pumpkin, .egg, .cake, .cobweb, .piston, .barrier });

pub const tool_not_required: std.EnumSet(Material) = .initMany(&.{ .stone, .iron, .anvil, .snow_layer, .snow, .cobweb, .barrier });

pub const block_to_material: std.EnumArray(Block, Material) = .init(.{ .air = .air, .stone = .stone, .grass = .grass, .dirt = .dirt, .cobblestone = .stone, .planks = .wood, .sapling = .plant, .bedrock = .stone, .flowing_water = .water, .water = .water, .flowing_lava = .lava, .lava = .lava, .sand = .sand, .gravel = .sand, .gold_ore = .stone, .iron_ore = .stone, .coal_ore = .stone, .log = .wood, .leaves = .leaves, .sponge = .sponge, .glass = .glass, .lapis_ore = .stone, .lapis_block = .iron, .dispenser = .stone, .sandstone = .stone, .noteblock = .wood, .bed = .wool, .golden_rail = .decoration, .detector_rail = .decoration, .sticky_piston = .piston, .web = .cobweb, .tallgrass = .replaceable_plant, .deadbush = .replaceable_plant, .piston = .piston, .piston_head = .piston, .wool = .wool, .piston_extension = .piston, .yellow_flower = .plant, .red_flower = .plant, .brown_mushroom = .plant, .red_mushroom = .plant, .gold_block = .iron, .iron_block = .iron, .double_stone_slab = .stone, .stone_slab = .stone, .brick_block = .stone, .tnt = .tnt, .bookshelf = .wood, .mossy_cobblestone = .stone, .obsidian = .stone, .torch = .decoration, .fire = .fire, .mob_spawner = .stone, .oak_stairs = .wood, .chest = .wood, .redstone_wire = .decoration, .diamond_ore = .stone, .diamond_block = .iron, .crafting_table = .wood, .wheat = .plant, .farmland = .dirt, .furnace = .stone, .lit_furnace = .stone, .standing_sign = .wood, .wooden_door = .wood, .ladder = .decoration, .rail = .decoration, .stone_stairs = .stone, .wall_sign = .wood, .lever = .decoration, .stone_pressure_plate = .stone, .iron_door = .iron, .wooden_pressure_plate = .wood, .redstone_ore = .stone, .lit_redstone_ore = .stone, .unlit_redstone_torch = .decoration, .redstone_torch = .decoration, .stone_button = .decoration, .snow_layer = .snow_layer, .ice = .ice, .snow = .snow, .cactus = .cactus, .clay = .clay, .reeds = .plant, .jukebox = .wood, .fence = .wood, .pumpkin = .pumpkin, .netherrack = .stone, .soul_sand = .sand, .glowstone = .glass, .portal = .portal, .lit_pumpkin = .pumpkin, .cake = .cake, .unpowered_repeater = .decoration, .powered_repeater = .decoration, .stained_glass = .glass, .trapdoor = .wood, .monster_egg = .clay, .stonebrick = .stone, .brown_mushroom_block = .wood, .red_mushroom_block = .wood, .iron_bars = .iron, .glass_pane = .glass, .melon_block = .pumpkin, .pumpkin_stem = .plant, .melon_stem = .plant, .vine = .replaceable_plant, .fence_gate = .wood, .brick_stairs = .stone, .stone_brick_stairs = .stone, .mycelium = .grass, .waterlily = .plant, .nether_brick = .stone, .nether_brick_fence = .stone, .nether_brick_stairs = .stone, .nether_wart = .plant, .enchanting_table = .stone, .brewing_stand = .iron, .cauldron = .iron, .end_portal = .portal, .end_portal_frame = .stone, .end_stone = .stone, .dragon_egg = .egg, .redstone_lamp = .redstone_lamp, .lit_redstone_lamp = .redstone_lamp, .double_wooden_slab = .wood, .wooden_slab = .wood, .cocoa = .plant, .sandstone_stairs = .stone, .emerald_ore = .stone, .ender_chest = .stone, .tripwire_hook = .decoration, .tripwire = .decoration, .emerald_block = .iron, .spruce_stairs = .wood, .birch_stairs = .wood, .jungle_stairs = .wood, .command_block = .iron, .beacon = .glass, .cobblestone_wall = .stone, .flower_pot = .decoration, .carrots = .plant, .potatoes = .plant, .wooden_button = .decoration, .skull = .decoration, .anvil = .anvil, .trapped_chest = .wood, .light_weighted_pressure_plate = .iron, .heavy_weighted_pressure_plate = .iron, .unpowered_comparator = .decoration, .powered_comparator = .decoration, .daylight_detector = .wood, .redstone_block = .iron, .quartz_ore = .stone, .hopper = .iron, .quartz_block = .stone, .quartz_stairs = .stone, .activator_rail = .decoration, .dropper = .stone, .stained_hardened_clay = .stone, .stained_glass_pane = .glass, .leaves2 = .leaves, .log2 = .wood, .acacia_stairs = .wood, .dark_oak_stairs = .wood, .slime = .clay, .barrier = .barrier, .iron_trapdoor = .iron, .prismarine = .stone, .sea_lantern = .glass, .hay_block = .grass, .carpet = .carpet, .hardened_clay = .stone, .coal_block = .stone, .packed_ice = .packed_ice, .double_plant = .replaceable_plant, .standing_banner = .wood, .wall_banner = .wood, .daylight_detector_inverted = .wood, .red_sandstone = .stone, .red_sandstone_stairs = .stone, .double_stone_slab2 = .stone, .stone_slab2 = .stone, .spruce_fence_gate = .wood, .birch_fence_gate = .wood, .jungle_fence_gate = .wood, .dark_oak_fence_gate = .wood, .acacia_fence_gate = .wood, .spruce_fence = .wood, .birch_fence = .wood, .jungle_fence = .wood, .dark_oak_fence = .wood, .acacia_fence = .wood, .spruce_door = .wood, .birch_door = .wood, .jungle_door = .wood, .acacia_door = .wood, .dark_oak_door = .wood });

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

    pub fn toolNotRequired(self: @This()) bool {
        return tool_not_required.contains(self);
    }
};
