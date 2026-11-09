pub const culls_adjacent_faces: std.EnumSet(Block) = .initMany(&.{
    .stone,                 .grass,              .dirt,          .cobblestone,
    .planks,                .bedrock,            .sand,          .gravel,
    .gold_ore,              .iron_ore,           .coal_ore,      .log,
    .sponge,                .lapis_ore,          .lapis_block,   .dispenser,
    .sandstone,             .noteblock,          .wool,          .gold_block,
    .iron_block,            .double_stone_slab,  .brick_block,   .tnt,
    .bookshelf,             .mossy_cobblestone,  .obsidian,      .diamond_ore,
    .diamond_block,         .crafting_table,     .furnace,       .lit_furnace,
    .redstone_ore,          .lit_redstone_ore,   .snow,          .clay,
    .jukebox,               .pumpkin,            .netherrack,    .soul_sand,
    .glowstone,             .lit_pumpkin,        .monster_egg,   .stonebrick,
    .brown_mushroom_block,  .red_mushroom_block, .melon_block,   .mycelium,
    .nether_brick,          .end_stone,          .redstone_lamp, .lit_redstone_lamp,
    .double_wooden_slab,    .emerald_ore,        .emerald_block, .command_block,
    .redstone_block,        .quartz_ore,         .quartz_block,  .dropper,
    .stained_hardened_clay, .log2,               .prismarine,    .sea_lantern,
    .hay_block,             .hardened_clay,      .coal_block,    .packed_ice,
    .red_sandstone,         .double_stone_slab2,
});

const std = @import("std");

const Block = @import("main").Block;
