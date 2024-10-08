const std = @import("std");
const ConcreteBlock = @import("block.zig").ConcreteBlock;
const EnumBoolArray = @import("util").EnumBoolArray;

pub const @"export" = EnumBoolArray(ConcreteBlock).init(.{
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
