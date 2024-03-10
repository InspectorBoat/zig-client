const std = @import("std");

// Converts an int into enum, returning a default value with ordinal 0 if the tag is out of bounds, and panicking on an invalid value in bounds
pub fn enumFromIntDefault0(comptime EnumTag: type, tag_int: anytype) EnumTag {
    const min, const max = comptime blk: {
        const enum_info = @typeInfo(EnumTag).Enum;
        var min = std.math.maxInt(enum_info.tag_type);
        var max = std.math.minInt(enum_info.tag_type);
        for (enum_info.fields) |field| {
            min = @min(field.value, min);
            max = @max(field.value, max);
        }
        break :blk .{ min, max };
    };

    // if tag out of bounds, return enum ordinal 0
    if (tag_int > max or tag_int < min) return @enumFromInt(0);

    // vanilla probably crashes from a NPE, and we definitely don't want to continue with an illegal world state
    return std.meta.intToEnum(EnumTag, tag_int) catch std.debug.panic("Illegal enum ordinal {} for enum {s}\n", .{ tag_int, @typeName(EnumTag) });
}

// Converts an int into an enum, supplying a default value to be returned if the tag is out of bounds, and panicking on an invalid value in bounds
pub fn enumFromIntDefault(comptime EnumTag: type, tag_int: anytype, comptime default: EnumTag) EnumTag {
    const min, const max = comptime blk: {
        const enum_info = @typeInfo(EnumTag).Enum;
        var min = std.math.maxInt(enum_info.tag_type);
        var max = std.math.minInt(enum_info.tag_type);
        for (enum_info.fields) |field| {
            min = @min(field.value, min);
            max = @max(field.value, max);
        }
        break :blk .{ min, max };
    };

    // if tag out of bounds, return default value
    if (tag_int > max or tag_int < min) return default;

    // vanilla probably crashes from a NPE, and we definitely don't want to continue with an illegal world state
    return std.meta.intToEnum(EnumTag, tag_int) catch std.debug.panic("Illegal enum ordinal {} for enum {s}\n", .{ tag_int, @typeName(EnumTag) });
}

// Converts an int into enum, panicking on any invalid value
pub fn enumFromIntErroring(comptime EnumTag: type, tag_int: anytype) EnumTag {
    return std.meta.intToEnum(EnumTag, tag_int) catch std.debug.panic("Illegal enum ordinal {} for enum {s}\n", .{ tag_int, @typeName(EnumTag) });
}

// Converts an int into enum, modulo the max ordinal if the tag is out of bounds, and panicking on an invalid value
pub fn enumFromIntModulo(comptime EnumTag: type, tag_int: anytype) EnumTag {
    const enum_info = @typeInfo(EnumTag).Enum;
    if (@typeInfo(enum_info.tag_type).Int.signedness == .signed) @compileError("Enum must be unsigned");
    const max = comptime blk: {
        var max = std.math.minInt(enum_info.tag_type);
        for (enum_info.fields) |field| {
            max = @max(field.value, max);
        }
        break :blk max;
    };

    // if tag out of bounds, modulo tag by max ordinal
    if (tag_int > max or tag_int < 0) return std.meta.intToEnum(EnumTag, tag_int % (max + 1)) catch std.debug.panic("Illegal enum ordinal {} for enum {s}\n", .{ tag_int, @typeName(EnumTag) });

    // vanilla probably crashes from a NPE, and we definitely don't want to continue with an illegal world state
    return std.meta.intToEnum(EnumTag, tag_int) catch std.debug.panic("Illegal enum ordinal {} for enum {s}\n", .{ tag_int, @typeName(EnumTag) });
}

// The types of each block
pub const Block = enum(u8) {
    air,
    stone,
    grass, // snowy
    dirt, // snowy
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
    fire, // alt north east south west upper flip
    mob_spawner,
    oak_stairs,
    chest,
    redstone_wire, // south north west east
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
    stone_stairs, // shape
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
    fence, // north east south west
    pumpkin,
    netherrack,
    soul_sand,
    glowstone,
    portal,
    lit_pumpkin,
    cake,
    unpowered_repeater, // locked
    powered_repeater, // locked
    stained_glass,
    trapdoor,
    monster_egg,
    stonebrick,
    brown_mushroom_block,
    red_mushroom_block,
    iron_bars, // north east south west
    glass_pane, // north east south west
    melon_block,
    pumpkin_stem, // facing
    melon_stem, // facing
    vine, // up
    fence_gate, // in_wall
    brick_stairs, // shape
    stone_brick_stairs, // shape
    mycelium, // snowy
    waterlily,
    nether_brick,
    nether_brick_fence, // north east south west
    nether_brick_stairs, // shape
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
    sandstone_stairs, // shape
    emerald_ore,
    ender_chest,
    tripwire_hook, // suspended
    tripwire, // north east south west
    emerald_block,
    spruce_stairs, // shape
    birch_stairs, // shape
    jungle_stairs, // shape
    command_block,
    beacon,
    cobblestone_wall, // north east south west up
    flower_pot, // contents
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
    quartz_stairs, // shape
    activator_rail,
    dropper,
    stained_hardened_clay,
    stained_glass_pane, // north east south west
    leaves2,
    log2,
    acacia_stairs, // shape
    dark_oak_stairs, // shape
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
    red_sandstone_stairs, // shape
    double_stone_slab2,
    stone_slab2,
    spruce_fence_gate, // in_wall
    birch_fence_gate, // in_wall
    jungle_fence_gate, // in_wall
    dark_oak_fence_gate, // in_wall
    acacia_fence_gate, // in_wall
    spruce_fence, // north east south west
    birch_fence, // north east south west
    jungle_fence, // north east south west
    dark_oak_fence, // north east south west
    acacia_fence, // north east south west
    spruce_door,
    birch_door,
    jungle_door,
    acacia_door,
    dark_oak_door,
};

// The raw bytes sent over
pub const RawBlockState = packed struct(u16) {
    metadata: u4,
    block: Block,
    _: u4 = 0,

    pub const AIR: @This() = .{ .block = .air, .metadata = 0 };

    pub fn from_u16(block: u16) @This() {
        const Intermediate = packed struct {
            metadata: u4,
            block: u12,
        };
        const intermediate = @as(Intermediate, @bitCast(block));
        if (intermediate.block > 198) return AIR;
        return @bitCast(block);
    }
    pub fn toFiltered(self: @This()) FilteredBlockState {
        if (!valid_metadata_table.get(self.block).isSet(self.metadata)) return .{ .block = .air, .properties = .{ .raw_bits = 0 } };
        return .{
            .block = self.block,
            .properties = .{ .raw_bits = raw_to_filtered_conversion_table.get(self.block).get(self.metadata) },
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
        pub const wool = packed struct(u4) { color: enum(u4) { white, orange, magenta, lightBlue, yellow, lime, pink, gray, silver, cyan, purple, blue, brown, green, red, black } };
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
        pub const stained_glass = packed struct(u4) { color: enum(u4) { white, orange, magenta, lightBlue, yellow, lime, pink, gray, silver, cyan, purple, blue, brown, green, red, black } };
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
        pub const flower_pot = packed struct(u4) { legacy_data: u4 };
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
        pub const stained_hardened_clay = packed struct(u4) { color: enum(u4) { white, orange, magenta, lightBlue, yellow, lime, pink, gray, silver, cyan, purple, blue, brown, green, red, black } };
        pub const stained_glass_pane = packed struct(u4) { color: enum(u4) { white, orange, magenta, lightBlue, yellow, lime, pink, gray, silver, cyan, purple, blue, brown, green, red, black } };
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
        pub const carpet = packed struct(u4) { color: enum(u4) { white, orange, magenta, lightBlue, yellow, lime, pink, gray, silver, cyan, purple, blue, brown, green, red, black } };
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

    pub fn toConcreteBlockState(self: @This()) void {
        switch (self.block) {}
    }
};

// FilteredBlockState, but with virtual properties resolved
pub const ConcreteBlockState = union(Block) {
    air: packed struct(u4) { _: u4 = 0 },
    stone: packed struct(u4) { variant: enum(u3) { stone, granite, smooth_granite, diorite, smooth_diorite, andesite, smooth_andesite }, _: u1 = 0 },
    grass: packed struct(u4) { _: u4 = 0 },
    dirt: packed struct(u4) { variant: enum(u2) { dirt, coarse_dirt, podzol }, _: u2 = 0 },
    cobblestone: packed struct(u4) { _: u4 = 0 },
    planks: packed struct(u4) { variant: enum(u3) { oak, spruce, birch, jungle, acacia, dark_oak }, _: u1 = 0 },
    sapling: packed struct(u4) { variant: enum(u3) { oak, spruce, birch, jungle, acacia, dark_oak }, stage: u1 },
    bedrock: packed struct(u4) { _: u4 = 0 },
    flowing_water: packed struct(u4) { level: u4 },
    water: packed struct(u4) { level: u4 },
    flowing_lava: packed struct(u4) { level: u4 },
    lava: packed struct(u4) { level: u4 },
    sand: packed struct(u4) { variant: enum(u1) { sand, red_sand }, _: u3 = 0 },
    gravel: packed struct(u4) { _: u4 = 0 },
    gold_ore: packed struct(u4) { _: u4 = 0 },
    iron_ore: packed struct(u4) { _: u4 = 0 },
    coal_ore: packed struct(u4) { _: u4 = 0 },
    log: packed struct(u4) { axis: enum(u2) { x, y, z, none }, variant: enum(u2) { oak, spruce, birch, jungle } },
    leaves: packed struct(u4) { variant: enum(u2) { oak, spruce, birch, jungle }, check_decay: bool, decayable: bool },
    sponge: packed struct(u4) { wet: bool, _: u3 = 0 },
    glass: packed struct(u4) { _: u4 = 0 },
    lapis_ore: packed struct(u4) { _: u4 = 0 },
    lapis_block: packed struct(u4) { _: u4 = 0 },
    dispenser: packed struct(u4) { triggered: bool, facing: enum(u3) { down, up, north, south, west, east } },
    sandstone: packed struct(u4) { variant: enum(u2) { sandstone, chiseled_sandstone, smooth_sandstone }, _: u2 = 0 },
    noteblock: packed struct(u4) { _: u4 = 0 },
    bed: packed struct(u4) { occupied: bool, facing: enum(u2) { north, south, west, east }, part: enum(u1) { head, foot } },
    golden_rail: packed struct(u4) { powered: bool, shape: enum(u3) { north_south, east_west, ascending_east, ascending_west, ascending_north, ascending_south } },
    detector_rail: packed struct(u4) { powered: bool, shape: enum(u3) { north_south, east_west, ascending_east, ascending_west, ascending_north, ascending_south } },
    sticky_piston: packed struct(u4) { facing: enum(u3) { down, up, north, south, west, east }, extended: bool },
    web: packed struct(u4) { _: u4 = 0 },
    tallgrass: packed struct(u4) { variant: enum(u2) { dead_bush, tall_grass, fern }, _: u2 = 0 },
    deadbush: packed struct(u4) { _: u4 = 0 },
    piston: packed struct(u4) { facing: enum(u3) { down, up, north, south, west, east }, extended: bool },
    piston_head: packed struct(u4) { variant: enum(u1) { normal, sticky }, facing: enum(u3) { down, up, north, south, west, east } },
    wool: packed struct(u4) { color: enum(u4) { white, orange, magenta, lightBlue, yellow, lime, pink, gray, silver, cyan, purple, blue, brown, green, red, black } },
    piston_extension: packed struct(u4) { variant: enum(u1) { normal, sticky }, facing: enum(u3) { down, up, north, south, west, east } },
    yellow_flower: packed struct(u4) { _: u4 = 0 },
    red_flower: packed struct(u4) { variant: enum(u4) { poppy, blue_orchid, allium, houstonia, red_tulip, orange_tulip, white_tulip, pink_tulip, oxeye_daisy } },
    brown_mushroom: packed struct(u4) { _: u4 = 0 },
    red_mushroom: packed struct(u4) { _: u4 = 0 },
    gold_block: packed struct(u4) { _: u4 = 0 },
    iron_block: packed struct(u4) { _: u4 = 0 },
    double_stone_slab: packed struct(u4) { seamless: bool, variant: enum(u3) { stone, sandstone, wood_old, cobblestone, brick, stone_brick, nether_brick, quartz } },
    stone_slab: packed struct(u4) { variant: enum(u3) { stone, sandstone, wood_old, cobblestone, brick, stone_brick, nether_brick, quartz }, half: enum(u1) { top, bottom } },
    brick_block: packed struct(u4) { _: u4 = 0 },
    tnt: packed struct(u4) { explode: bool, _: u3 = 0 },
    bookshelf: packed struct(u4) { _: u4 = 0 },
    mossy_cobblestone: packed struct(u4) { _: u4 = 0 },
    obsidian: packed struct(u4) { _: u4 = 0 },
    torch: packed struct(u4) { facing: enum(u3) { up, north, south, west, east }, _: u1 = 0 },
    fire: packed struct(u4) { age: u4 },
    mob_spawner: packed struct(u4) { _: u4 = 0 },
    oak_stairs: packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 },
    chest: packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 },
    redstone_wire: packed struct(u4) { power: u4 },
    diamond_ore: packed struct(u4) { _: u4 = 0 },
    diamond_block: packed struct(u4) { _: u4 = 0 },
    crafting_table: packed struct(u4) { _: u4 = 0 },
    wheat: packed struct(u4) { age: u3, _: u1 = 0 },
    farmland: packed struct(u4) { moisture: u3, _: u1 = 0 },
    furnace: packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 },
    lit_furnace: packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 },
    standing_sign: packed struct(u4) { rotation: u4 },
    wooden_door: packed struct(u4) { half: enum(u1) { upper, lower }, other: packed union { when_upper: packed struct(u3) { hinge: enum(u1) { left, right }, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: enum(u2) { north, south, west, east }, open: bool } } },
    ladder: packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 },
    rail: packed struct(u4) { shape: enum(u4) { north_south, east_west, ascending_east, ascending_west, ascending_north, ascending_south, south_east, south_west, north_west, north_east } },
    stone_stairs: packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 },
    wall_sign: packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 },
    lever: packed struct(u4) { powered: bool, facing: enum(u3) { down_x, east, west, south, north, up_z, up_x, down_z } },
    stone_pressure_plate: packed struct(u4) { powered: bool, _: u3 = 0 },
    iron_door: packed struct(u4) { half: enum(u1) { upper, lower }, other: packed union { when_upper: packed struct(u3) { hinge: enum(u1) { left, right }, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: enum(u2) { north, south, west, east }, open: bool } } },
    wooden_pressure_plate: packed struct(u4) { powered: bool, _: u3 = 0 },
    redstone_ore: packed struct(u4) { _: u4 = 0 },
    lit_redstone_ore: packed struct(u4) { _: u4 = 0 },
    unlit_redstone_torch: packed struct(u4) { facing: enum(u3) { up, north, south, west, east }, _: u1 = 0 },
    redstone_torch: packed struct(u4) { facing: enum(u3) { up, north, south, west, east }, _: u1 = 0 },
    stone_button: packed struct(u4) { powered: bool, facing: enum(u3) { down, up, north, south, west, east } },
    snow_layer: packed struct(u4) { layers: u3, _: u1 = 0 },
    ice: packed struct(u4) { _: u4 = 0 },
    snow: packed struct(u4) { _: u4 = 0 },
    cactus: packed struct(u4) { age: u4 },
    clay: packed struct(u4) { _: u4 = 0 },
    reeds: packed struct(u4) { age: u4 },
    jukebox: packed struct(u4) { has_record: bool, _: u3 = 0 },
    fence: packed struct(u4) { _: u4 = 0 },
    pumpkin: packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 },
    netherrack: packed struct(u4) { _: u4 = 0 },
    soul_sand: packed struct(u4) { _: u4 = 0 },
    glowstone: packed struct(u4) { _: u4 = 0 },
    portal: packed struct(u4) { axis: enum(u1) { x, z }, _: u3 = 0 },
    lit_pumpkin: packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 },
    cake: packed struct(u4) { bites: u3, _: u1 = 0 },
    unpowered_repeater: packed struct(u4) { delay: u2, facing: enum(u2) { north, south, west, east } },
    powered_repeater: packed struct(u4) { delay: u2, facing: enum(u2) { north, south, west, east } },
    stained_glass: packed struct(u4) { color: enum(u4) { white, orange, magenta, lightBlue, yellow, lime, pink, gray, silver, cyan, purple, blue, brown, green, red, black } },
    trapdoor: packed struct(u4) { open: bool, half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east } },
    monster_egg: packed struct(u4) { variant: enum(u3) { stone, cobblestone, stone_brick, mossy_brick, cracked_brick, chiseled_brick }, _: u1 = 0 },
    stonebrick: packed struct(u4) { variant: enum(u2) { stonebrick, mossy_stonebrick, cracked_stonebrick, chiseled_stonebrick }, _: u2 = 0 },
    brown_mushroom_block: packed struct(u4) { variant: enum(u4) { north_west, north, north_east, west, center, east, south_west, south, south_east, stem, all_inside, all_outside, all_stem } },
    red_mushroom_block: packed struct(u4) { variant: enum(u4) { north_west, north, north_east, west, center, east, south_west, south, south_east, stem, all_inside, all_outside, all_stem } },
    iron_bars: packed struct(u4) { _: u4 = 0 },
    glass_pane: packed struct(u4) { _: u4 = 0 },
    melon_block: packed struct(u4) { _: u4 = 0 },
    pumpkin_stem: packed struct(u4) { age: u3, _: u1 = 0 },
    melon_stem: packed struct(u4) { age: u3, _: u1 = 0 },
    vine: packed struct(u4) { west: bool, south: bool, north: bool, east: bool },
    fence_gate: packed struct(u4) { open: bool, powered: bool, facing: enum(u2) { north, south, west, east } },
    brick_stairs: packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 },
    stone_brick_stairs: packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 },
    mycelium: packed struct(u4) { _: u4 = 0 },
    waterlily: packed struct(u4) { _: u4 = 0 },
    nether_brick: packed struct(u4) { _: u4 = 0 },
    nether_brick_fence: packed struct(u4) { _: u4 = 0 },
    nether_brick_stairs: packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 },
    nether_wart: packed struct(u4) { age: u2, _: u2 = 0 },
    enchanting_table: packed struct(u4) { _: u4 = 0 },
    brewing_stand: packed struct(u4) { has_bottle_2: bool, has_bottle_0: bool, has_bottle_1: bool, _: u1 = 0 },
    cauldron: packed struct(u4) { level: u2, _: u2 = 0 },
    end_portal: packed struct(u4) { _: u4 = 0 },
    end_portal_frame: packed struct(u4) { eye: bool, facing: enum(u2) { north, south, west, east }, _: u1 = 0 },
    end_stone: packed struct(u4) { _: u4 = 0 },
    dragon_egg: packed struct(u4) { _: u4 = 0 },
    redstone_lamp: packed struct(u4) { _: u4 = 0 },
    lit_redstone_lamp: packed struct(u4) { _: u4 = 0 },
    double_wooden_slab: packed struct(u4) { variant: enum(u3) { oak, spruce, birch, jungle, acacia, dark_oak }, _: u1 = 0 },
    wooden_slab: packed struct(u4) { variant: enum(u3) { oak, spruce, birch, jungle, acacia, dark_oak }, half: enum(u1) { top, bottom } },
    cocoa: packed struct(u4) { age: u2, facing: enum(u2) { north, south, west, east } },
    sandstone_stairs: packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 },
    emerald_ore: packed struct(u4) { _: u4 = 0 },
    ender_chest: packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 },
    tripwire_hook: packed struct(u4) { powered: bool, facing: enum(u2) { north, south, west, east }, attached: bool },
    tripwire: packed struct(u4) { powered: bool, disarmed: bool, attached: bool, suspended: bool },
    emerald_block: packed struct(u4) { _: u4 = 0 },
    spruce_stairs: packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 },
    birch_stairs: packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 },
    jungle_stairs: packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 },
    command_block: packed struct(u4) { triggered: bool, _: u3 = 0 },
    beacon: packed struct(u4) { _: u4 = 0 },
    cobblestone_wall: packed struct(u4) { variant: enum(u1) { cobblestone, mossy_cobblestone }, _: u3 = 0 },
    flower_pot: packed struct(u4) { legacy_data: u4 },
    carrots: packed struct(u4) { age: u3, _: u1 = 0 },
    potatoes: packed struct(u4) { age: u3, _: u1 = 0 },
    wooden_button: packed struct(u4) { powered: bool, facing: enum(u3) { down, up, north, south, west, east } },
    skull: packed struct(u4) { facing: enum(u3) { down, up, north, south, west, east }, nodrop: bool },
    anvil: packed struct(u4) { damage: u2, facing: enum(u2) { north, south, west, east } },
    trapped_chest: packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 },
    light_weighted_pressure_plate: packed struct(u4) { power: u4 },
    heavy_weighted_pressure_plate: packed struct(u4) { power: u4 },
    unpowered_comparator: packed struct(u4) { powered: bool, mode: enum(u1) { compare, subtract }, facing: enum(u2) { north, south, west, east } },
    powered_comparator: packed struct(u4) { powered: bool, mode: enum(u1) { compare, subtract }, facing: enum(u2) { north, south, west, east } },
    daylight_detector: packed struct(u4) { power: u4 },
    redstone_block: packed struct(u4) { _: u4 = 0 },
    quartz_ore: packed struct(u4) { _: u4 = 0 },
    hopper: packed struct(u4) { facing: enum(u3) { down, north, south, west, east }, enabled: bool },
    quartz_block: packed struct(u4) { variant: enum(u3) { default, chiseled, lines_x, lines_y, lines_z }, _: u1 = 0 },
    quartz_stairs: packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 },
    activator_rail: packed struct(u4) { powered: bool, shape: enum(u3) { north_south, east_west, ascending_east, ascending_west, ascending_north, ascending_south } },
    dropper: packed struct(u4) { triggered: bool, facing: enum(u3) { down, up, north, south, west, east } },
    stained_hardened_clay: packed struct(u4) { color: enum(u4) { white, orange, magenta, lightBlue, yellow, lime, pink, gray, silver, cyan, purple, blue, brown, green, red, black } },
    stained_glass_pane: packed struct(u4) { color: enum(u4) { white, orange, magenta, lightBlue, yellow, lime, pink, gray, silver, cyan, purple, blue, brown, green, red, black } },
    leaves2: packed struct(u4) { variant: enum(u1) { acacia, dark_oak }, check_decay: bool, decayable: bool, _: u1 = 0 },
    log2: packed struct(u4) { axis: enum(u2) { x, y, z, none }, variant: enum(u1) { acacia, dark_oak }, _: u1 = 0 },
    acacia_stairs: packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 },
    dark_oak_stairs: packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 },
    slime: packed struct(u4) { _: u4 = 0 },
    barrier: packed struct(u4) { _: u4 = 0 },
    iron_trapdoor: packed struct(u4) { open: bool, half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east } },
    prismarine: packed struct(u4) { variant: enum(u2) { prismarine, prismarine_bricks, dark_prismarine }, _: u2 = 0 },
    sea_lantern: packed struct(u4) { _: u4 = 0 },
    hay_block: packed struct(u4) { axis: enum(u2) { x, y, z }, _: u2 = 0 },
    carpet: packed struct(u4) { color: enum(u4) { white, orange, magenta, lightBlue, yellow, lime, pink, gray, silver, cyan, purple, blue, brown, green, red, black } },
    hardened_clay: packed struct(u4) { _: u4 = 0 },
    coal_block: packed struct(u4) { _: u4 = 0 },
    packed_ice: packed struct(u4) { _: u4 = 0 },
    double_plant: packed struct(u4) { variant: enum(u3) { sunflower, syringa, double_grass, double_fern, double_rose, paeonia }, half: enum(u1) { upper, lower } },
    standing_banner: packed struct(u4) { rotation: u4 },
    wall_banner: packed struct(u4) { facing: enum(u2) { north, south, west, east }, _: u2 = 0 },
    daylight_detector_inverted: packed struct(u4) { power: u4 },
    red_sandstone: packed struct(u4) { variant: enum(u2) { red_sandstone, chiseled_red_sandstone, smooth_red_sandstone }, _: u2 = 0 },
    red_sandstone_stairs: packed struct(u4) { half: enum(u1) { top, bottom }, facing: enum(u2) { north, south, west, east }, _: u1 = 0 },
    double_stone_slab2: packed struct(u4) { seamless: bool, _: u3 = 0 },
    stone_slab2: packed struct(u4) { half: enum(u1) { top, bottom }, _: u3 = 0 },
    spruce_fence_gate: packed struct(u4) { open: bool, powered: bool, facing: enum(u2) { north, south, west, east } },
    birch_fence_gate: packed struct(u4) { open: bool, powered: bool, facing: enum(u2) { north, south, west, east } },
    jungle_fence_gate: packed struct(u4) { open: bool, powered: bool, facing: enum(u2) { north, south, west, east } },
    dark_oak_fence_gate: packed struct(u4) { open: bool, powered: bool, facing: enum(u2) { north, south, west, east } },
    acacia_fence_gate: packed struct(u4) { open: bool, powered: bool, facing: enum(u2) { north, south, west, east } },
    spruce_fence: packed struct(u4) { _: u4 = 0 },
    birch_fence: packed struct(u4) { _: u4 = 0 },
    jungle_fence: packed struct(u4) { _: u4 = 0 },
    dark_oak_fence: packed struct(u4) { _: u4 = 0 },
    acacia_fence: packed struct(u4) { _: u4 = 0 },
    spruce_door: packed struct(u4) { half: enum(u1) { upper, lower }, other: packed union { when_upper: packed struct(u3) { hinge: enum(u1) { left, right }, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: enum(u2) { north, south, west, east }, open: bool } } },
    birch_door: packed struct(u4) { half: enum(u1) { upper, lower }, other: packed union { when_upper: packed struct(u3) { hinge: enum(u1) { left, right }, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: enum(u2) { north, south, west, east }, open: bool } } },
    jungle_door: packed struct(u4) { half: enum(u1) { upper, lower }, other: packed union { when_upper: packed struct(u3) { hinge: enum(u1) { left, right }, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: enum(u2) { north, south, west, east }, open: bool } } },
    acacia_door: packed struct(u4) { half: enum(u1) { upper, lower }, other: packed union { when_upper: packed struct(u3) { hinge: enum(u1) { left, right }, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: enum(u2) { north, south, west, east }, open: bool } } },
    dark_oak_door: packed struct(u4) { half: enum(u1) { upper, lower }, other: packed union { when_upper: packed struct(u3) { hinge: enum(u1) { left, right }, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: enum(u2) { north, south, west, east }, open: bool } } },
};

/// A table of valid metadata values for each block
/// Zero represents an valid value that will become air and One represents a valid value that should be looked up
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

pub fn bitCastArrayElements(comptime ElementType: type, comptime length: usize, array: [length]ElementType) [length]std.meta.Int(.unsigned, @bitSizeOf(ElementType)) {
    @setEvalBranchQuota(1000000);
    var casted: [length]std.meta.Int(.unsigned, @bitSizeOf(ElementType)) = undefined;
    for (array, &casted) |original, *casted_ptr| {
        casted_ptr.* = @bitCast(original);
    }
    return casted;
}

/// converts metadata -> packed struct through lookup table
const raw_to_filtered_conversion_table = blk: {
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
    table.set(.wool, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.wool, 16, .{ .{ .color = .white }, .{ .color = .orange }, .{ .color = .magenta }, .{ .color = .lightBlue }, .{ .color = .yellow }, .{ .color = .lime }, .{ .color = .pink }, .{ .color = .gray }, .{ .color = .silver }, .{ .color = .cyan }, .{ .color = .purple }, .{ .color = .blue }, .{ .color = .brown }, .{ .color = .green }, .{ .color = .red }, .{ .color = .black } })));
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
    table.set(.stained_glass, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.stained_glass, 16, .{ .{ .color = .white }, .{ .color = .orange }, .{ .color = .magenta }, .{ .color = .lightBlue }, .{ .color = .yellow }, .{ .color = .lime }, .{ .color = .pink }, .{ .color = .gray }, .{ .color = .silver }, .{ .color = .cyan }, .{ .color = .purple }, .{ .color = .blue }, .{ .color = .brown }, .{ .color = .green }, .{ .color = .red }, .{ .color = .black } })));
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
    table.set(.flower_pot, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.flower_pot, 16, .{ .{ .legacy_data = 0 }, .{ .legacy_data = 1 }, .{ .legacy_data = 2 }, .{ .legacy_data = 3 }, .{ .legacy_data = 4 }, .{ .legacy_data = 5 }, .{ .legacy_data = 6 }, .{ .legacy_data = 7 }, .{ .legacy_data = 8 }, .{ .legacy_data = 9 }, .{ .legacy_data = 10 }, .{ .legacy_data = 11 }, .{ .legacy_data = 12 }, .{ .legacy_data = 13 }, .{ .legacy_data = 14 }, .{ .legacy_data = 15 } })));
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
    table.set(.stained_hardened_clay, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.stained_hardened_clay, 16, .{ .{ .color = .white }, .{ .color = .orange }, .{ .color = .magenta }, .{ .color = .lightBlue }, .{ .color = .yellow }, .{ .color = .lime }, .{ .color = .pink }, .{ .color = .gray }, .{ .color = .silver }, .{ .color = .cyan }, .{ .color = .purple }, .{ .color = .blue }, .{ .color = .brown }, .{ .color = .green }, .{ .color = .red }, .{ .color = .black } })));
    table.set(.stained_glass_pane, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.stained_glass_pane, 16, .{ .{ .color = .white }, .{ .color = .orange }, .{ .color = .magenta }, .{ .color = .lightBlue }, .{ .color = .yellow }, .{ .color = .lime }, .{ .color = .pink }, .{ .color = .gray }, .{ .color = .silver }, .{ .color = .cyan }, .{ .color = .purple }, .{ .color = .blue }, .{ .color = .brown }, .{ .color = .green }, .{ .color = .red }, .{ .color = .black } })));
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
    table.set(.carpet, std.PackedIntArray(u4, 16).init(bitCastArrayElements(properties.carpet, 16, .{ .{ .color = .white }, .{ .color = .orange }, .{ .color = .magenta }, .{ .color = .lightBlue }, .{ .color = .yellow }, .{ .color = .lime }, .{ .color = .pink }, .{ .color = .gray }, .{ .color = .silver }, .{ .color = .cyan }, .{ .color = .purple }, .{ .color = .blue }, .{ .color = .brown }, .{ .color = .green }, .{ .color = .red }, .{ .color = .black } })));
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