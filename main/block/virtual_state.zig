const std = @import("std");

const main = @import("main");

const physical_state = @import("physical_state.zig");
const Block = @import("block.zig").Block;

const Box = main.Box;
const Direction = main.Direction;
const Vector3 = main.Vector3;
const World = main.World;
const PhysicalState = physical_state.PhysicalState;

pub const VirtualState = union(Block) {
    pub const StairShape = enum(u3) { straight, inner_left, inner_right, outer_left, outer_right };
    pub const StemFacing = enum(u3) { up = 0, north = 1, south = 2, west = 3, east = 4 };
    pub const DoorFacing = enum(u2) { north = 0, south = 1, west = 2, east = 3 };
    pub const RedstoneWireConnection = enum(u2) { up, side, none };

    air: packed struct {},
    stone: packed struct { variant: PhysicalState.StoneVariant },
    grass: packed struct { snowy: bool },
    dirt: packed struct { variant: PhysicalState.DirtVariant, snowy: bool },
    cobblestone: packed struct {},
    planks: packed struct { variant: PhysicalState.WoodVariant },
    sapling: packed struct { variant: PhysicalState.WoodVariant, stage: u1 },
    bedrock: packed struct {},
    flowing_water: packed struct { level: u4 },
    water: packed struct { level: u4 },
    flowing_lava: packed struct { level: u4 },
    lava: packed struct { level: u4 },
    sand: packed struct { variant: PhysicalState.SandVariant },
    gravel: packed struct {},
    gold_ore: packed struct {},
    iron_ore: packed struct {},
    coal_ore: packed struct {},
    log: packed struct { variant: PhysicalState.WoodVariant1, axis: PhysicalState.LogAxis },
    leaves: packed struct { variant: PhysicalState.WoodVariant1, not_decayable: bool, check_decay: bool },
    sponge: packed struct { wet: bool },
    glass: packed struct {},
    lapis_ore: packed struct {},
    lapis_block: packed struct {},
    dispenser: packed struct { facing: PhysicalState.Facing, triggered: bool },
    sandstone: packed struct { variant: PhysicalState.SandstoneVariant },
    noteblock: packed struct {},
    bed: packed struct { facing: PhysicalState.PackedHorizontalFacing, occupied: bool, part: PhysicalState.BedPart },
    golden_rail: packed struct { shape: PhysicalState.StraightRailShape, powered: bool },
    detector_rail: packed struct { shape: PhysicalState.StraightRailShape, powered: bool },
    sticky_piston: packed struct { facing: PhysicalState.Facing, extended: bool },
    web: packed struct {},
    tallgrass: packed struct { variant: PhysicalState.TallGrassVariant },
    deadbush: packed struct {},
    piston: packed struct { facing: PhysicalState.Facing, extended: bool },
    piston_head: packed struct { facing: PhysicalState.Facing, type: PhysicalState.PistonType, short: bool },
    wool: packed struct { color: PhysicalState.Color },
    piston_extension: packed struct { facing: PhysicalState.Facing, sticky: bool },
    yellow_flower: packed struct {},
    red_flower: packed struct { variant: PhysicalState.RedFlowerVariant },
    brown_mushroom: packed struct {},
    red_mushroom: packed struct {},
    gold_block: packed struct {},
    iron_block: packed struct {},
    double_stone_slab: packed struct { variant: PhysicalState.StoneSlabVariant, seamless: bool },
    stone_slab: packed struct { variant: PhysicalState.StoneSlabVariant, half: PhysicalState.Half },
    brick_block: packed struct {},
    tnt: packed struct { explode: bool },
    bookshelf: packed struct {},
    mossy_cobblestone: packed struct {},
    obsidian: packed struct {},
    torch: packed struct { facing: PhysicalState.TorchFacing },
    fire: packed struct { age: u4, flip: bool, alt: bool, north: bool, east: bool, south: bool, west: bool, upper: enum(u2) { @"0", @"1", @"2" } },
    mob_spawner: packed struct {},
    oak_stairs: packed struct { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape },
    chest: packed struct { facing: PhysicalState.HorizontalFacing },
    redstone_wire: packed struct { power: u4, north: RedstoneWireConnection, east: RedstoneWireConnection, south: RedstoneWireConnection, west: RedstoneWireConnection },
    diamond_ore: packed struct {},
    diamond_block: packed struct {},
    crafting_table: packed struct {},
    wheat: packed struct { age: u3 },
    farmland: packed struct { moisture: u3 },
    furnace: packed struct { facing: PhysicalState.HorizontalFacing },
    lit_furnace: packed struct { facing: PhysicalState.HorizontalFacing },
    standing_sign: packed struct { rotation: u4 },
    wooden_door: packed struct { half: PhysicalState.DoorHalf, hinge: PhysicalState.DoorHinge, powered: bool, open: bool, facing: PhysicalState.DoorFacing },
    ladder: packed struct { facing: PhysicalState.HorizontalFacing },
    rail: packed struct { shape: PhysicalState.CurveableRailShape },
    stone_stairs: packed struct { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape },
    wall_sign: packed struct { facing: PhysicalState.HorizontalFacing },
    lever: packed struct { facing: PhysicalState.LeverFacing, powered: bool },
    stone_pressure_plate: packed struct { powered: bool },
    iron_door: packed struct { half: PhysicalState.DoorHalf, hinge: PhysicalState.DoorHinge, powered: bool, open: bool, facing: PhysicalState.DoorFacing },
    wooden_pressure_plate: packed struct { powered: bool },
    redstone_ore: packed struct {},
    lit_redstone_ore: packed struct {},
    unlit_redstone_torch: packed struct { facing: PhysicalState.TorchFacing },
    redstone_torch: packed struct { facing: PhysicalState.TorchFacing },
    stone_button: packed struct { facing: PhysicalState.ButtonFacing, powered: bool },
    snow_layer: packed struct { layers: PhysicalState.SnowLayers },
    ice: packed struct {},
    snow: packed struct {},
    cactus: packed struct { age: u4 },
    clay: packed struct {},
    reeds: packed struct { age: u4 },
    jukebox: packed struct { has_record: bool },
    fence: packed struct { north: bool, east: bool, south: bool, west: bool },
    pumpkin: packed struct { facing: PhysicalState.PackedHorizontalFacing },
    netherrack: packed struct {},
    soul_sand: packed struct {},
    glowstone: packed struct {},
    portal: packed struct { axis: PhysicalState.PortalAxis },
    lit_pumpkin: packed struct { facing: PhysicalState.PackedHorizontalFacing },
    cake: packed struct { bites: PhysicalState.CakeBites },
    unpowered_repeater: packed struct { facing: PhysicalState.PackedHorizontalFacing, delay: PhysicalState.RepeaterDelay, locked: bool },
    powered_repeater: packed struct { facing: PhysicalState.PackedHorizontalFacing, delay: PhysicalState.RepeaterDelay, locked: bool },
    stained_glass: packed struct { color: PhysicalState.Color },
    trapdoor: packed struct { facing: PhysicalState.TrapdoorFacing, open: bool, half: PhysicalState.Half },
    monster_egg: packed struct { variant: PhysicalState.MonsterEggVariant },
    stonebrick: packed struct { variant: PhysicalState.StoneBrickVariant },
    brown_mushroom_block: packed struct { variant: PhysicalState.MushroomBlockVariant },
    red_mushroom_block: packed struct { variant: PhysicalState.MushroomBlockVariant },
    iron_bars: packed struct { north: bool, east: bool, south: bool, west: bool },
    glass_pane: packed struct { north: bool, east: bool, south: bool, west: bool },
    melon_block: packed struct {},
    pumpkin_stem: packed struct { age: u3, facing: StemFacing },
    melon_stem: packed struct { age: u3, facing: StemFacing },
    vine: packed struct { south: bool, west: bool, north: bool, east: bool, up: bool },
    fence_gate: packed struct { facing: PhysicalState.PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool },
    brick_stairs: packed struct { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape },
    stone_brick_stairs: packed struct { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape },
    mycelium: packed struct { snowy: bool },
    waterlily: packed struct {},
    nether_brick: packed struct {},
    nether_brick_fence: packed struct { north: bool, east: bool, south: bool, west: bool },
    nether_brick_stairs: packed struct { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape },
    nether_wart: packed struct { age: u2 },
    enchanting_table: packed struct {},
    brewing_stand: packed struct { has_bottle_0: bool, has_bottle_1: bool, has_bottle_2: bool },
    cauldron: packed struct { level: u2 },
    end_portal: packed struct {},
    end_portal_frame: packed struct { facing: PhysicalState.PackedHorizontalFacing, eye: bool },
    end_stone: packed struct {},
    dragon_egg: packed struct {},
    redstone_lamp: packed struct {},
    lit_redstone_lamp: packed struct {},
    double_wooden_slab: packed struct { variant: PhysicalState.WoodVariant },
    wooden_slab: packed struct { variant: PhysicalState.WoodVariant, half: PhysicalState.Half },
    cocoa: packed struct { facing: PhysicalState.PackedHorizontalFacing, age: PhysicalState.Age02 },
    sandstone_stairs: packed struct { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape },
    emerald_ore: packed struct {},
    ender_chest: packed struct { facing: PhysicalState.HorizontalFacing },
    tripwire_hook: packed struct { facing: PhysicalState.PackedHorizontalFacing, attached: bool, powered: bool, suspended: bool },
    tripwire: packed struct { powered: bool, suspended: bool, attached: bool, disarmed: bool, north: bool, east: bool, south: bool, west: bool },
    emerald_block: packed struct {},
    spruce_stairs: packed struct { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape },
    birch_stairs: packed struct { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape },
    jungle_stairs: packed struct { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape },
    command_block: packed struct { triggered: bool },
    beacon: packed struct {},
    cobblestone_wall: packed struct { variant: PhysicalState.CobblestoneWallVariant, up: bool, north: bool, east: bool, south: bool, west: bool },
    flower_pot: packed struct { legacy_data: u4 },
    carrots: packed struct { age: u3 },
    potatoes: packed struct { age: u3 },
    wooden_button: packed struct { facing: PhysicalState.ButtonFacing, powered: bool },
    skull: packed struct { facing: PhysicalState.Facing, nodrop: bool },
    anvil: packed struct { facing: PhysicalState.PackedHorizontalFacing, damage: PhysicalState.Age02 },
    trapped_chest: packed struct { facing: PhysicalState.HorizontalFacing },
    light_weighted_pressure_plate: packed struct { power: u4 },
    heavy_weighted_pressure_plate: packed struct { power: u4 },
    unpowered_comparator: packed struct { facing: PhysicalState.PackedHorizontalFacing, mode: PhysicalState.ComparatorMode, powered: bool },
    powered_comparator: packed struct { facing: PhysicalState.PackedHorizontalFacing, mode: PhysicalState.ComparatorMode, powered: bool },
    daylight_detector: packed struct { power: u4 },
    redstone_block: packed struct {},
    quartz_ore: packed struct {},
    hopper: packed struct { facing: PhysicalState.HopperFacing, enabled: bool },
    quartz_block: packed struct { variant: PhysicalState.QuartzBlockVariant },
    quartz_stairs: packed struct { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape },
    activator_rail: packed struct { shape: PhysicalState.StraightRailShape, powered: bool },
    dropper: packed struct { facing: PhysicalState.Facing, triggered: bool },
    stained_hardened_clay: packed struct { color: PhysicalState.Color },
    stained_glass_pane: packed struct { color: PhysicalState.Color, north: bool, east: bool, south: bool, west: bool },
    leaves2: packed struct { variant: PhysicalState.WoodVariant2, not_decayable: bool, check_decay: bool },
    log2: packed struct { variant: PhysicalState.WoodVariant2, axis: PhysicalState.LogAxis },
    acacia_stairs: packed struct { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape },
    dark_oak_stairs: packed struct { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape },
    slime: packed struct {},
    barrier: packed struct {},
    iron_trapdoor: packed struct { facing: PhysicalState.TrapdoorFacing, open: bool, half: PhysicalState.Half },
    prismarine: packed struct { variant: PhysicalState.PrismarineVariant },
    sea_lantern: packed struct {},
    hay_block: packed struct { axis: PhysicalState.HayBlockAxis },
    carpet: packed struct { color: PhysicalState.Color },
    hardened_clay: packed struct {},
    coal_block: packed struct {},
    packed_ice: packed struct {},
    double_plant: packed struct { variant: PhysicalState.DoublePlantVariant, half: PhysicalState.DoublePlantHalf },
    standing_banner: packed struct { rotation: u4 },
    wall_banner: packed struct { facing: PhysicalState.HorizontalFacing },
    daylight_detector_inverted: packed struct { power: u4 },
    red_sandstone: packed struct { variant: PhysicalState.RedSandstoneVariant },
    red_sandstone_stairs: packed struct { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape },
    double_stone_slab2: packed struct { seamless: bool },
    stone_slab2: packed struct { half: PhysicalState.Half },
    spruce_fence_gate: packed struct { facing: PhysicalState.PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool },
    birch_fence_gate: packed struct { facing: PhysicalState.PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool },
    jungle_fence_gate: packed struct { facing: PhysicalState.PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool },
    dark_oak_fence_gate: packed struct { facing: PhysicalState.PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool },
    acacia_fence_gate: packed struct { facing: PhysicalState.PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool },
    spruce_fence: packed struct { north: bool, east: bool, south: bool, west: bool },
    birch_fence: packed struct { north: bool, east: bool, south: bool, west: bool },
    jungle_fence: packed struct { north: bool, east: bool, south: bool, west: bool },
    dark_oak_fence: packed struct { north: bool, east: bool, south: bool, west: bool },
    acacia_fence: packed struct { north: bool, east: bool, south: bool, west: bool },
    spruce_door: packed struct { half: PhysicalState.DoorHalf, hinge: PhysicalState.DoorHinge, powered: bool, open: bool, facing: PhysicalState.DoorFacing },
    birch_door: packed struct { half: PhysicalState.DoorHalf, hinge: PhysicalState.DoorHinge, powered: bool, open: bool, facing: PhysicalState.DoorFacing },
    jungle_door: packed struct { half: PhysicalState.DoorHalf, hinge: PhysicalState.DoorHinge, powered: bool, open: bool, facing: PhysicalState.DoorFacing },
    acacia_door: packed struct { half: PhysicalState.DoorHalf, hinge: PhysicalState.DoorHinge, powered: bool, open: bool, facing: PhysicalState.DoorFacing },
    dark_oak_door: packed struct { half: PhysicalState.DoorHalf, hinge: PhysicalState.DoorHinge, powered: bool, open: bool, facing: PhysicalState.DoorFacing },

    pub fn resolve(physical: PhysicalState, world: *const World, block_pos: Vector3(i32)) @This() {
        return switch (physical.block) {
            .grass => .{ .grass = .{
                .snowy = isSnow(world.getBlockState(block_pos.up()).block),
            } },
            .mycelium => .{ .mycelium = .{
                .snowy = isSnow(world.getBlockState(block_pos.up()).block),
            } },
            .dirt => .{ .dirt = .{
                .variant = physical.payload(.dirt).variant,
                .snowy = physical.payload(.dirt).variant == .podzol and isSnow(world.getBlockState(block_pos.up()).block),
            } },
            .bed => .{ .bed = .{
                .facing = physical.payload(.bed).facing,
                .occupied = if (physical.payload(.bed).part == .foot) blk: {
                    break :blk if (world.getBlockState(block_pos.dir(.from(physical.payload(.bed).facing))).maybePayload(.bed)) |other_bed|
                        other_bed.occupied
                    else
                        false;
                } else physical.payload(.bed).occupied,
                .part = physical.payload(.bed).part,
            } },
            .vine => .{ .vine = .{
                .south = physical.payload(.vine).south,
                .west = physical.payload(.vine).west,
                .north = physical.payload(.vine).north,
                .east = physical.payload(.vine).east,
                .up = world.getBlock(block_pos.up()).blocksAmbientLight(),
            } },
            .tripwire_hook => .{ .tripwire_hook = .{
                .facing = physical.payload(.tripwire_hook).facing,
                .attached = physical.payload(.tripwire_hook).attached,
                .powered = physical.payload(.tripwire_hook).powered,
                .suspended = !world.getBlockState(block_pos.down()).hasSolidTop(),
            } },
            .pumpkin_stem => .{ .pumpkin_stem = .{
                .age = physical.payload(.pumpkin_stem).age,
                .facing = stemFacingFor(world, block_pos, .pumpkin_stem),
            } },
            .melon_stem => .{ .melon_stem = .{
                .age = physical.payload(.melon_stem).age,
                .facing = stemFacingFor(world, block_pos, .melon_stem),
            } },
            .double_plant => .{ .double_plant = .{
                .variant = if (physical.payload(.double_plant).half == .upper) blk: {
                    break :blk if (world.getBlockState(block_pos.down()).maybePayload(.double_plant)) |other| other.variant else .paeonia;
                } else physical.payload(.double_plant).variant,
                .half = physical.payload(.double_plant).half,
            } },
            .fire => .{ .fire = .{
                .age = physical.payload(.fire).age,
                .flip = false,
                .alt = false,
                .north = false,
                .east = false,
                .south = false,
                .west = false,
                .upper = .@"0",
            } },
            .redstone_wire => .{ .redstone_wire = .{
                .power = physical.payload(.redstone_wire).power,
                .north = .none,
                .east = .none,
                .south = .none,
                .west = .none,
            } },
            .iron_bars => .{ .iron_bars = .{
                .north = paneShouldConnectTo(world.getBlock(block_pos.north())),
                .south = paneShouldConnectTo(world.getBlock(block_pos.south())),
                .west = paneShouldConnectTo(world.getBlock(block_pos.west())),
                .east = paneShouldConnectTo(world.getBlock(block_pos.east())),
            } },
            .glass_pane => .{ .glass_pane = .{
                .north = paneShouldConnectTo(world.getBlock(block_pos.north())),
                .south = paneShouldConnectTo(world.getBlock(block_pos.south())),
                .west = paneShouldConnectTo(world.getBlock(block_pos.west())),
                .east = paneShouldConnectTo(world.getBlock(block_pos.east())),
            } },
            .stained_glass_pane => .{ .stained_glass_pane = .{
                .color = physical.payload(.stained_glass_pane).color,
                .north = paneShouldConnectTo(world.getBlock(block_pos.north())),
                .south = paneShouldConnectTo(world.getBlock(block_pos.south())),
                .west = paneShouldConnectTo(world.getBlock(block_pos.west())),
                .east = paneShouldConnectTo(world.getBlock(block_pos.east())),
            } },
            .cobblestone_wall => .{ .cobblestone_wall = .{
                .variant = physical.payload(.cobblestone_wall).variant,
                .up = world.getBlock(block_pos.up()) != .air,
                .north = wallShouldConnectTo(world.getBlock(block_pos.north())),
                .east = wallShouldConnectTo(world.getBlock(block_pos.east())),
                .south = wallShouldConnectTo(world.getBlock(block_pos.south())),
                .west = wallShouldConnectTo(world.getBlock(block_pos.west())),
            } },
            .tripwire => {
                const suspended = physical.payload(.tripwire).suspended;
                return .{ .tripwire = .{
                    .powered = physical.payload(.tripwire).powered,
                    .suspended = physical.payload(.tripwire).suspended,
                    .attached = physical.payload(.tripwire).attached,
                    .disarmed = physical.payload(.tripwire).disarmed,
                    .north = tripwireShouldConnectTo(world, block_pos, suspended, .north),
                    .east = tripwireShouldConnectTo(world, block_pos, suspended, .east),
                    .south = tripwireShouldConnectTo(world, block_pos, suspended, .south),
                    .west = tripwireShouldConnectTo(world, block_pos, suspended, .west),
                } };
            },
            inline .powered_repeater, .unpowered_repeater => |block| @unionInit(VirtualState, @tagName(block), .{
                .facing = physical.payload(block).facing,
                .delay = physical.payload(block).delay,
                .locked = false,
            }),
            inline .fence_gate, .spruce_fence_gate, .birch_fence_gate, .jungle_fence_gate, .dark_oak_fence_gate, .acacia_fence_gate => |block| @unionInit(@This(), @tagName(block), .{
                .facing = physical.payload(block).facing,
                .open = physical.payload(block).open,
                .powered = physical.payload(block).powered,
                .in_wall = switch (physical.payload(block).facing) {
                    .north, .south => world.getBlock(block_pos.west()) == .cobblestone_wall or
                        world.getBlock(block_pos.east()) == .cobblestone_wall,
                    .west, .east => world.getBlock(block_pos.north()) == .cobblestone_wall or
                        world.getBlock(block_pos.south()) == .cobblestone_wall,
                },
            }),
            inline .wooden_door, .iron_door, .spruce_door, .birch_door, .jungle_door, .acacia_door, .dark_oak_door => |block| {
                const maybe_neighbor = world.getBlockState(if (physical.payload(block).half == .lower) block_pos.up() else block_pos.down()).maybePayload(block);
                return @unionInit(
                    @This(),
                    @tagName(block),
                    if (physical.payload(block).half == .lower) .{
                        .half = physical.payload(block).half,
                        .open = physical.payload(block).other.when_lower.open,
                        .facing = physical.payload(block).other.when_lower.facing,
                        .hinge = if (maybe_neighbor) |neighbor| neighbor.other.when_upper.hinge else .right,
                        .powered = if (maybe_neighbor) |neighbor| neighbor.other.when_upper.powered else false,
                    } else .{
                        .half = physical.payload(block).half,
                        .open = if (maybe_neighbor) |neighbor| neighbor.other.when_lower.open else false,
                        .facing = if (maybe_neighbor) |neighbor| neighbor.other.when_lower.facing else .east,
                        .hinge = physical.payload(block).other.when_upper.hinge,
                        .powered = physical.payload(block).other.when_upper.powered,
                    },
                );
            },
            inline .fence, .nether_brick_fence, .spruce_fence, .birch_fence, .jungle_fence, .dark_oak_fence, .acacia_fence => |block| @unionInit(@This(), @tagName(block), .{
                .north = fenceShouldConnectTo(world, block_pos.north(), block),
                .east = fenceShouldConnectTo(world, block_pos.east(), block),
                .south = fenceShouldConnectTo(world, block_pos.south(), block),
                .west = fenceShouldConnectTo(world, block_pos.west(), block),
            }),
            inline .oak_stairs, .stone_stairs, .brick_stairs, .stone_brick_stairs, .nether_brick_stairs, .sandstone_stairs, .spruce_stairs, .birch_stairs, .jungle_stairs, .quartz_stairs, .acacia_stairs, .dark_oak_stairs, .red_sandstone_stairs => |block| @unionInit(@This(), @tagName(block), .{
                .facing = physical.payload(block).facing,
                .half = physical.payload(block).half,
                .shape = resolveStairShape(world, block_pos),
            }),
            .piston_head => .{ .piston_head = .{
                .facing = physical.payload(.piston_head).facing,
                .type = physical.payload(.piston_head).type,
                .short = false,
            } },
            inline else => |block| {
                var properties: @FieldType(VirtualState, @tagName(block)) = undefined;
                inline for (@typeInfo(@TypeOf(properties)).@"struct".field_names) |field_name| {
                    @field(properties, field_name) = @field(physical.payload(block), field_name);
                }
                return @unionInit(@This(), @tagName(block), properties);
            },
        };
    }

    pub fn canBeReplaced(self: @This()) bool {
        return switch (self) {
            .air, .deadbush, .tallgrass, .vine => true,
            .snow_layer => |s| s.layers == .@"1",
            .double_plant => |s| s.variant == .double_fern or s.variant == .double_grass,
            else => false,
        };
    }

    pub fn getCollisionHitboxes(self: @This()) [5]?Box(f64) {
        var c: Collisions = .{};
        switch (self) {
            .air, .sapling, .flowing_water, .water, .flowing_lava, .lava, .tallgrass, .deadbush, .web, .yellow_flower, .red_flower, .brown_mushroom, .red_mushroom, .fire, .golden_rail, .detector_rail, .rail, .activator_rail, .redstone_wire, .torch, .unlit_redstone_torch, .redstone_torch, .standing_sign, .wall_sign, .lever, .stone_pressure_plate, .wooden_pressure_plate, .light_weighted_pressure_plate, .heavy_weighted_pressure_plate, .stone_button, .wooden_button, .reeds, .wheat, .carrots, .potatoes, .nether_wart, .pumpkin_stem, .melon_stem, .double_plant, .vine, .tripwire, .tripwire_hook, .standing_banner, .wall_banner, .end_portal, .piston_extension, .portal => {},

            .stone, .grass, .dirt, .cobblestone, .planks, .bedrock, .sand, .gravel, .gold_ore, .iron_ore, .coal_ore, .log, .leaves, .sponge, .glass, .lapis_ore, .lapis_block, .dispenser, .sandstone, .noteblock, .bed, .wool, .gold_block, .iron_block, .double_stone_slab, .brick_block, .tnt, .bookshelf, .mossy_cobblestone, .obsidian, .mob_spawner, .diamond_ore, .diamond_block, .crafting_table, .furnace, .lit_furnace, .redstone_ore, .lit_redstone_ore, .ice, .snow, .clay, .jukebox, .pumpkin, .netherrack, .glowstone, .lit_pumpkin, .stained_glass, .monster_egg, .stonebrick, .brown_mushroom_block, .red_mushroom_block, .melon_block, .mycelium, .nether_brick, .end_stone, .redstone_lamp, .lit_redstone_lamp, .double_wooden_slab, .emerald_ore, .emerald_block, .command_block, .beacon, .anvil, .unpowered_comparator, .powered_comparator, .redstone_block, .quartz_ore, .quartz_block, .dropper, .stained_hardened_clay, .leaves2, .log2, .slime, .barrier, .prismarine, .sea_lantern, .hay_block, .hardened_clay, .coal_block, .packed_ice, .red_sandstone, .double_stone_slab2 => {
                c.add(full_cube);
            },

            .farmland => c.add(full_cube),

            .stone_slab => |s| c.add(slab_collision(s.half)),
            .wooden_slab => |s| c.add(slab_collision(s.half)),
            .stone_slab2 => |s| c.add(slab_collision(s.half)),
            .cactus => c.add(collision_box(0.0625, 0, 0.0625, 0.9375, 0.9375, 0.9375)),
            .soul_sand => c.add(collision_box(0, 0, 0, 1, 0.875, 1)),
            .cake => |s| c.add(cake_collision(s.bites)),
            .waterlily => c.add(collision_box(0, 0, 0, 1, 0.015625, 1)),
            .enchanting_table => c.add(collision_box(0, 0, 0, 1, 0.75, 1)),
            .dragon_egg => c.add(collision_box(0.0625, 0, 0.0625, 0.9375, 1, 0.9375)),
            .flower_pot => c.add(collision_box(0.3125, 0, 0.3125, 0.6875, 0.375, 0.6875)),
            .chest, .trapped_chest, .ender_chest => c.add(collision_box(0.0625, 0, 0.0625, 0.9375, 0.875, 0.9375)),
            .carpet => c.add(collision_box(0, 0, 0, 1, 0.0625, 1)),
            .unpowered_repeater, .powered_repeater => c.add(collision_box(0, 0, 0, 1, 0.125, 1)),
            .daylight_detector, .daylight_detector_inverted => c.add(collision_box(0, 0, 0, 1, 0.375, 1)),
            .snow_layer => |s| c.add(snow_layer_collision(s.layers)),
            .ladder => |s| c.add(ladder_collision(s.facing)),
            .cocoa => |s| c.add(cocoa_collision(s.facing, s.age)),
            .skull => |s| c.add(skull_collision(s.facing)),
            inline .trapdoor, .iron_trapdoor => |s| c.add(trapdoor_collision(s.half, s.open, s.facing)),

            inline .sticky_piston, .piston => |s| c.add(piston_collision(s.facing, s.extended)),
            .piston_head => |s| piston_head_collisions(&c, s.facing),

            inline .wooden_door, .iron_door, .spruce_door, .birch_door, .jungle_door, .acacia_door, .dark_oak_door => |s| {
                c.add(door_collision(s.facing, s.open, s.hinge));
            },

            inline .fence_gate, .spruce_fence_gate, .birch_fence_gate, .jungle_fence_gate, .dark_oak_fence_gate, .acacia_fence_gate => |s| {
                if (fence_gate_collision(s.open, s.facing)) |b| c.add(b);
            },

            inline .fence, .nether_brick_fence, .spruce_fence, .birch_fence, .jungle_fence, .dark_oak_fence, .acacia_fence => |s| {
                fence_collisions(&c, s.north, s.south, s.west, s.east);
            },

            inline .iron_bars, .glass_pane, .stained_glass_pane => |s| pane_collisions(&c, s.north, s.south, s.west, s.east),

            .cobblestone_wall => |s| c.add(wall_collision(s.north, s.south, s.west, s.east)),

            .brewing_stand => {
                c.add(collision_box(0.4375, 0, 0.4375, 0.5625, 0.875, 0.5625));
                c.add(collision_box(0, 0, 0, 1, 0.125, 1));
            },

            .end_portal_frame => |s| {
                c.add(collision_box(0, 0, 0, 1, 0.8125, 1));
                if (s.eye) c.add(collision_box(0.3125, 0.8125, 0.3125, 0.6875, 1, 0.6875));
            },

            .cauldron => funnel_collisions(&c, 0.3125),
            .hopper => funnel_collisions(&c, 0.625),

            inline .oak_stairs, .stone_stairs, .brick_stairs, .stone_brick_stairs, .nether_brick_stairs, .sandstone_stairs, .spruce_stairs, .birch_stairs, .jungle_stairs, .quartz_stairs, .acacia_stairs, .dark_oak_stairs, .red_sandstone_stairs => |s| {
                stair_collisions(&c, s.facing, s.half, s.shape);
            },
        }
        return c.boxes;
    }

    pub fn getRaytraceHitboxes(self: @This()) [5]?Box(f64) {
        switch (self) {
            .piston_extension, .air => return no_ray_box,

            .cactus, .soul_sand, .glass_pane, .stained_glass_pane, .iron_bars => return ray(full_cube),
            .fire, .flowing_water, .water, .flowing_lava, .lava => return ray(full_cube),
            .web, .double_plant => return ray(full_cube),
            .cauldron, .hopper => return ray(full_cube),
            .brewing_stand => return ray(collision_box(0, 0, 0, 1, 0.125, 1)),

            .sapling, .tallgrass, .deadbush => return ray(collision_box(0.1, 0, 0.1, 0.9, 0.8, 0.9)),
            .brown_mushroom, .red_mushroom => return ray(collision_box(0.3, 0, 0.3, 0.7, 0.4, 0.7)),
            .yellow_flower, .red_flower => return ray(collision_box(0.3, 0, 0.3, 0.7, 0.6, 0.7)),
            .wheat, .carrots, .potatoes, .nether_wart => return ray(collision_box(0, 0, 0, 1, 0.25, 1)),
            .reeds => return ray(collision_box(0.125, 0, 0.125, 0.875, 1, 0.875)),
            .redstone_wire => return ray(collision_box(0, 0, 0, 1, 0.0625, 1)),
            .standing_sign, .standing_banner => return ray(collision_box(0.25, 0, 0.25, 0.75, 1, 0.75)),
            .end_portal => return ray(collision_box(0, 0, 0, 1, 0.0625, 1)),
            .end_portal_frame => return ray(collision_box(0, 0, 0, 1, 0.8125, 1)),
            .farmland => return ray(collision_box(0, 0, 0, 1, 0.9375, 1)),

            .stone_slab => |s| return ray(slab_collision(s.half)),
            .wooden_slab => |s| return ray(slab_collision(s.half)),
            .stone_slab2 => |s| return ray(slab_collision(s.half)),
            .double_stone_slab, .double_wooden_slab, .double_stone_slab2 => return ray(full_cube),

            .snow_layer => |s| return ray(collision_box(0, 0, 0, 1, (@as(f64, @backingInt(s.layers)) + 1) / 8.0, 1)),
            .cake => |s| return ray(cake_collision(s.bites)),
            .melon_stem => |s| return ray(stem_ray(s.age)),
            .pumpkin_stem => |s| return ray(stem_ray(s.age)),
            .ladder => |s| return ray(ladder_collision(s.facing)),
            .skull => |s| return ray(skull_collision(s.facing)),
            .cocoa => |s| return ray(cocoa_collision(s.facing, s.age)),

            inline .trapdoor, .iron_trapdoor => |s| return ray(trapdoor_collision(s.half, s.open, s.facing)),

            inline .sticky_piston, .piston => |s| return ray(piston_collision(s.facing, s.extended)),
            .piston_head => |s| return ray(piston_head_collision(s.facing)),

            inline .wooden_door, .iron_door, .spruce_door, .birch_door, .jungle_door, .acacia_door, .dark_oak_door => |s| {
                return ray(door_collision(s.facing, s.open, s.hinge));
            },

            inline .fence_gate, .spruce_fence_gate, .birch_fence_gate, .jungle_fence_gate, .dark_oak_fence_gate, .acacia_fence_gate => |s| {
                return ray(fence_gate_ray(s.facing));
            },

            inline .fence, .nether_brick_fence, .spruce_fence, .birch_fence, .jungle_fence, .dark_oak_fence, .acacia_fence => |s| {
                return ray(fence_ray(s.north, s.south, s.west, s.east));
            },

            .cobblestone_wall => |s| return ray(wall_ray(s.north, s.south, s.west, s.east)),

            .golden_rail => |s| return ray(rail_ray(s.shape)),
            .detector_rail => |s| return ray(rail_ray(s.shape)),
            .activator_rail => |s| return ray(rail_ray(s.shape)),
            .rail => |s| return ray(rail_ray(s.shape)),

            .torch => |s| return ray(torch_ray(s.facing)),
            .redstone_torch => |s| return ray(torch_ray(s.facing)),
            .unlit_redstone_torch => |s| return ray(torch_ray(s.facing)),
            .lever => |s| return ray(lever_ray(s.facing)),
            .stone_button => |s| return ray(button_ray(s.facing, s.powered)),
            .wooden_button => |s| return ray(button_ray(s.facing, s.powered)),

            .stone_pressure_plate => |s| return ray(pressure_plate_ray(s.powered)),
            .wooden_pressure_plate => |s| return ray(pressure_plate_ray(s.powered)),
            .light_weighted_pressure_plate => |s| return ray(pressure_plate_ray(s.power != 0)),
            .heavy_weighted_pressure_plate => |s| return ray(pressure_plate_ray(s.power != 0)),

            .wall_sign => |s| return ray(wall_sign_ray(s.facing)),
            .wall_banner => |s| return ray(wall_sign_ray(s.facing)),
            .tripwire_hook => |s| return ray(tripwire_hook_ray(s.facing)),
            .tripwire => |s| return ray(tripwire_ray(s.suspended, s.attached)),
            .vine => |s| return ray(vine_ray(s.north, s.east, s.south, s.west, false)),
            .portal => |s| return ray(portal_ray(s.axis)),

            inline .oak_stairs, .stone_stairs, .brick_stairs, .stone_brick_stairs, .nether_brick_stairs, .sandstone_stairs, .spruce_stairs, .birch_stairs, .jungle_stairs, .quartz_stairs, .acacia_stairs, .dark_oak_stairs, .red_sandstone_stairs => {
                return self.getCollisionHitboxes();
            },

            else => return self.getCollisionHitboxes(),
        }
    }

    pub fn isFullCube(self: @This()) bool {
        const first = self.getCollisionHitboxes()[0] orelse return false;
        const dx = first.max.x - first.min.x;
        const dy = first.max.y - first.min.y;
        const dz = first.max.z - first.min.z;
        return (dx + dy + dz) / 3.0 >= 1.0;
    }
};

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

fn stemFacingFor(world: *const World, block_pos: Vector3(i32), self_block: Block) VirtualState.StemFacing {
    const plant: Block = if (self_block == .pumpkin_stem) .melon_block else .pumpkin;
    if (world.getBlock(block_pos.north()) == plant) return .north;
    if (world.getBlock(block_pos.east()) == plant) return .east;
    if (world.getBlock(block_pos.south()) == plant) return .south;
    if (world.getBlock(block_pos.west()) == plant) return .west;
    return .up;
}

fn fenceShouldConnectTo(world: *const World, block_pos: Vector3(i32), self_block: Block) bool {
    _ = world;
    _ = block_pos;
    _ = self_block;
    return true;
}

fn paneShouldConnectTo(neighbour: Block) bool {
    return switch (neighbour) {
        .iron_bars, .glass_pane, .stained_glass_pane, .glass, .stained_glass => true,
        else => neighbour.isSolid(),
    };
}

fn wallShouldConnectTo(neighbor: Block) bool {
    return neighbor.isSolid();
}

fn tripwireShouldConnectTo(world: *const World, block_pos: Vector3(i32), suspended: bool, dir: PhysicalState.HorizontalFacing) bool {
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

fn isStairSameHalfSameFacing(world: *const World, other_pos: Vector3(i32), self_props: anytype) bool {
    const other = world.getBlockState(other_pos);
    if (!isStair(other.block)) return false;
    const p = other.properties.oak_stairs;
    return p.half == self_props.half and p.facing == self_props.facing;
}

fn isInnerStair(world: *const World, block_pos: Vector3(i32), self_props: anytype) bool {
    const facing = self_props.facing;

    const first: PhysicalState.StairFacing, const second: PhysicalState.StairFacing = switch (facing) {
        .east, .west => .{ .north, .south },
        .south, .north => .{ .west, .east },
    };

    const neighbour = world.getBlockState(block_pos.dir(switch (facing) {
        .east => .east,
        .west => .west,
        .south => .south,
        .north => .north,
    }));
    if (!isStair(neighbour.block) or neighbour.properties.oak_stairs.half != self_props.half) return true;
    const neighbour_facing = neighbour.properties.oak_stairs.facing;
    if (neighbour_facing == first and
        !isStairSameHalfSameFacing(world, block_pos.dir(.from(second)), self_props)) return false;
    if (neighbour_facing == second and
        !isStairSameHalfSameFacing(world, block_pos.dir(.from(first)), self_props)) return false;
    return true;
}

fn stairCorner(world: *const World, block_pos: Vector3(i32), self_props: anytype, inner: bool) u2 {
    const top = self_props.half == .top;
    const facing = self_props.facing;

    const neighbour_dir: PhysicalState.StairFacing = if (inner) switch (facing) {
        .east => .west,
        .west => .east,
        .south => .north,
        .north => .south,
    } else facing;
    const first: PhysicalState.StairFacing, const second: PhysicalState.StairFacing = switch (facing) {
        .east, .west => .{ .north, .south },
        .south, .north => .{ .west, .east },
    };

    const check_first = if (inner) first else second;
    const check_second = if (inner) second else first;

    const neighbour = world.getBlockState(block_pos.dir(.from(neighbour_dir)));
    if (!isStair(neighbour.block) or neighbour.properties.oak_stairs.half != self_props.half) return 0;
    const neighbour_facing = neighbour.properties.oak_stairs.facing;

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

fn resolveStairShape(world: *const World, block_pos: Vector3(i32)) VirtualState.StairShape {
    const props = world.getBlockState(block_pos).properties.oak_stairs;
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

const Collisions = struct {
    boxes: [5]?Box(f64) = @splat(null),
    total: u4 = 0,

    fn add(self: *@This(), b: Box(f64)) void {
        std.debug.assert(self.total < self.boxes.len);
        self.boxes[self.total] = b;
        self.total += 1;
    }
};

fn collision_box(min_x: f64, min_y: f64, min_z: f64, max_x: f64, max_y: f64, max_z: f64) Box(f64) {
    return .{
        .min = .{ .x = min_x, .y = min_y, .z = min_z },
        .max = .{ .x = max_x, .y = max_y, .z = max_z },
    };
}

const full_cube: Box(f64) = collision_box(0, 0, 0, 1, 1, 1);

fn ray(b: Box(f64)) [5]?Box(f64) {
    return .{ b, null, null, null, null };
}

const no_ray_box: [5]?Box(f64) = @splat(null);

fn stem_ray(age: u3) Box(f64) {
    const h: f64 = (@as(f64, age) * 2.0 + 2.0) / 16.0;
    return collision_box(0.375, 0, 0.375, 0.625, h, 0.625);
}

fn fence_ray(north: bool, south: bool, west: bool, east: bool) Box(f64) {
    var min_x: f64 = 0.375;
    var max_x: f64 = 0.625;
    var min_z: f64 = 0.375;
    var max_z: f64 = 0.625;
    if (north) min_z = 0;
    if (south) max_z = 1;
    if (west) min_x = 0;
    if (east) max_x = 1;
    return collision_box(min_x, 0, min_z, max_x, 1, max_z);
}

fn wall_ray(north: bool, south: bool, west: bool, east: bool) Box(f64) {
    var min_x: f64 = 0.25;
    var max_x: f64 = 0.75;
    var min_z: f64 = 0.25;
    var max_z: f64 = 0.75;
    var max_y: f64 = 1;
    if (north) min_z = 0;
    if (south) max_z = 1;
    if (west) min_x = 0;
    if (east) max_x = 1;
    if ((north and south and !west and !east) or (!north and !south and west and east)) {
        max_y = 0.8125;
        min_x = 0.3125;
        max_x = 0.6875;
        min_z = 0.3125;
        max_z = 0.6875;
    }
    return collision_box(min_x, 0, min_z, max_x, max_y, max_z);
}

fn fence_gate_ray(facing: PhysicalState.PackedHorizontalFacing) Box(f64) {
    return switch (facing) {
        .north, .south => collision_box(0, 0, 0.375, 1, 1, 0.625),
        .west, .east => collision_box(0.375, 0, 0, 0.625, 1, 1),
    };
}

fn rail_ray(shape: anytype) Box(f64) {
    const ascending = switch (shape) {
        .ascending_east, .ascending_west, .ascending_north, .ascending_south => true,
        else => false,
    };
    return collision_box(0, 0, 0, 1, if (ascending) 0.625 else 0.125, 1);
}

fn torch_ray(facing: PhysicalState.TorchFacing) Box(f64) {
    const t: f64 = 0.15;
    return switch (facing) {
        .east => collision_box(0, 0.2, 0.5 - t, t * 2, 0.8, 0.5 + t),
        .west => collision_box(1 - t * 2, 0.2, 0.5 - t, 1, 0.8, 0.5 + t),
        .south => collision_box(0.5 - t, 0.2, 0, 0.5 + t, 0.8, t * 2),
        .north => collision_box(0.5 - t, 0.2, 1 - t * 2, 0.5 + t, 0.8, 1),
        .up => collision_box(0.4, 0, 0.4, 0.6, 0.6, 0.6),
    };
}

fn lever_ray(facing: PhysicalState.LeverFacing) Box(f64) {
    const t: f64 = 0.1875;
    return switch (facing) {
        .east => collision_box(0, 0.2, 0.5 - t, t * 2, 0.8, 0.5 + t),
        .west => collision_box(1 - t * 2, 0.2, 0.5 - t, 1, 0.8, 0.5 + t),
        .south => collision_box(0.5 - t, 0.2, 0, 0.5 + t, 0.8, t * 2),
        .north => collision_box(0.5 - t, 0.2, 1 - t * 2, 0.5 + t, 0.8, 1),
        .up_z, .up_x => collision_box(0.25, 0, 0.25, 0.75, 0.6, 0.75),
        .down_x, .down_z => collision_box(0.25, 0.4, 0.25, 0.75, 1, 0.75),
    };
}

fn button_ray(facing: PhysicalState.ButtonFacing, powered: bool) Box(f64) {
    const h: f64 = @as(f64, if (powered) 1.0 else 2.0) / 16.0;
    return switch (facing) {
        .east => collision_box(0, 0.375, 0.3125, h, 0.625, 0.6875),
        .west => collision_box(1 - h, 0.375, 0.3125, 1, 0.625, 0.6875),
        .south => collision_box(0.3125, 0.375, 0, 0.6875, 0.625, h),
        .north => collision_box(0.3125, 0.375, 1 - h, 0.6875, 0.625, 1),
        .up => collision_box(0.3125, 0, 0.375, 0.6875, h, 0.625),
        .down => collision_box(0.3125, 1 - h, 0.375, 0.6875, 1, 0.625),
    };
}

fn pressure_plate_ray(powered: bool) Box(f64) {
    return collision_box(0.0625, 0, 0.0625, 0.9375, if (powered) 0.03125 else 0.0625, 0.9375);
}

fn wall_sign_ray(facing: PhysicalState.HorizontalFacing) Box(f64) {
    const f: f64 = 0.28125;
    const g: f64 = 0.78125;
    const j: f64 = 0.125;
    return switch (facing) {
        .north => collision_box(0, f, 1 - j, 1, g, 1),
        .south => collision_box(0, f, 0, 1, g, j),
        .west => collision_box(1 - j, f, 0, 1, g, 1),
        .east => collision_box(0, f, 0, j, g, 1),
    };
}

fn tripwire_hook_ray(facing: PhysicalState.PackedHorizontalFacing) Box(f64) {
    const f: f64 = 0.1875;
    return switch (facing) {
        .east => collision_box(0, 0.2, 0.5 - f, f * 2, 0.8, 0.5 + f),
        .west => collision_box(1 - f * 2, 0.2, 0.5 - f, 1, 0.8, 0.5 + f),
        .south => collision_box(0.5 - f, 0.2, 0, 0.5 + f, 0.8, f * 2),
        .north => collision_box(0.5 - f, 0.2, 1 - f * 2, 0.5 + f, 0.8, 1),
    };
}

fn tripwire_ray(suspended: bool, attached: bool) Box(f64) {
    if (!suspended) return collision_box(0, 0, 0, 1, 0.09375, 1);
    if (!attached) return collision_box(0, 0, 0, 1, 0.5, 1);
    return collision_box(0, 0.0625, 0, 1, 0.15625, 1);
}

fn portal_ray(axis: PhysicalState.PortalAxis) Box(f64) {
    const f: f64 = if (axis == .x) 0.5 else 0.125;
    const g: f64 = if (axis == .z) 0.5 else 0.125;
    return collision_box(0.5 - f, 0, 0.5 - g, 0.5 + f, 1, 0.5 + g);
}

fn piston_head_collision(facing: PhysicalState.Facing) Box(f64) {
    return switch (facing) {
        .down => collision_box(0, 0, 0, 1, 0.25, 1),
        .up => collision_box(0, 0.75, 0, 1, 1, 1),
        .north => collision_box(0, 0, 0, 1, 1, 0.25),
        .south => collision_box(0, 0, 0.75, 1, 1, 1),
        .west => collision_box(0, 0, 0, 0.25, 1, 1),
        .east => collision_box(0.75, 0, 0, 1, 1, 1),
    };
}

fn vine_ray(north: bool, east: bool, south: bool, west: bool, grow_above: bool) Box(f64) {
    var min_x: f64 = 1.0;
    var min_y: f64 = 1.0;
    var min_z: f64 = 1.0;
    var max_x: f64 = 0.0;
    var max_y: f64 = 0.0;
    var max_z: f64 = 0.0;
    var joined = false;

    if (west) {
        max_x = @max(max_x, 0.0625);
        min_x = 0;
        min_y = 0;
        max_y = 1;
        min_z = 1;
        max_z = 0;
        joined = true;
    }
    if (east) {
        min_x = @min(min_x, 0.9375);
        max_x = 1;
        min_y = 0;
        max_y = 1;
        min_z = 1;
        max_z = 0;
        joined = true;
    }
    if (north) {
        max_z = @max(max_z, 0.0625);
        min_z = 0;
        min_x = 0;
        max_x = 1;
        min_y = 0;
        max_y = 1;
        joined = true;
    }
    if (south) {
        min_z = @min(min_z, 0.9375);
        max_z = 1;
        min_x = 0;
        max_x = 1;
        min_y = 0;
        max_y = 1;
        joined = true;
    }
    if (!joined and grow_above) {
        min_y = @min(min_y, 0.9375);
        max_y = 1;
        min_x = 0;
        max_x = 1;
        min_z = 0;
        max_z = 1;
    }
    return collision_box(min_x, min_y, min_z, max_x, max_y, max_z);
}

fn slab_collision(half: PhysicalState.Half) Box(f64) {
    return if (half == .top)
        collision_box(0, 0.5, 0, 1, 1, 1)
    else
        collision_box(0, 0, 0, 1, 0.5, 1);
}

fn snow_layer_collision(layers: PhysicalState.SnowLayers) Box(f64) {
    return collision_box(0, 0, 0, 1, @as(f64, @backingInt(layers)) / 8.0, 1);
}

fn cake_collision(bites: PhysicalState.CakeBites) Box(f64) {
    return collision_box((@as(f64, @backingInt(bites)) * 2.0 + 1.0) / 16.0, 0, 0.0625, 0.9375, 0.5, 0.9375);
}

fn ladder_collision(facing: PhysicalState.HorizontalFacing) Box(f64) {
    const t: f64 = 0.125;
    return switch (facing) {
        .north => collision_box(0, 0, 1 - t, 1, 1, 1),
        .south => collision_box(0, 0, 0, 1, 1, t),
        .west => collision_box(1 - t, 0, 0, 1, 1, 1),
        .east => collision_box(0, 0, 0, t, 1, 1),
    };
}

fn trapdoor_collision(half: PhysicalState.Half, open: bool, facing: PhysicalState.TrapdoorFacing) Box(f64) {
    const t: f64 = 0.1875;
    if (!open) return if (half == .top)
        collision_box(0, 0.8125, 0, 1, 1, 1)
    else
        collision_box(0, 0, 0, 1, t, 1);
    return switch (facing) {
        .north => collision_box(0, 0, 1 - t, 1, 1, 1),
        .south => collision_box(0, 0, 0, 1, 1, t),
        .west => collision_box(1 - t, 0, 0, 1, 1, 1),
        .east => collision_box(0, 0, 0, t, 1, 1),
    };
}

fn cocoa_collision(facing: PhysicalState.PackedHorizontalFacing, age: PhysicalState.Age02) Box(f64) {
    const j = 4.0 + @as(f64, @backingInt(age)) * 2.0;
    const k = 5.0 + @as(f64, @backingInt(age)) * 2.0;
    const w = j / 2.0;
    const y0 = (12.0 - k) / 16.0;
    return switch (facing) {
        .south => collision_box((8.0 - w) / 16.0, y0, (15.0 - j) / 16.0, (8.0 + w) / 16.0, 0.75, 0.9375),
        .north => collision_box((8.0 - w) / 16.0, y0, 0.0625, (8.0 + w) / 16.0, 0.75, (1.0 + j) / 16.0),
        .west => collision_box(0.0625, y0, (8.0 - w) / 16.0, (1.0 + j) / 16.0, 0.75, (8.0 + w) / 16.0),
        .east => collision_box((15.0 - j) / 16.0, y0, (8.0 - w) / 16.0, 0.9375, 0.75, (8.0 + w) / 16.0),
    };
}

fn skull_collision(facing: PhysicalState.Facing) Box(f64) {
    return switch (facing) {
        .north => collision_box(0.25, 0.25, 0.5, 0.75, 0.75, 1),
        .south => collision_box(0.25, 0.25, 0, 0.75, 0.75, 0.5),
        .west => collision_box(0.5, 0.25, 0.25, 1, 0.75, 0.75),
        .east => collision_box(0, 0.25, 0.25, 0.5, 0.75, 0.75),

        .up, .down => collision_box(0.25, 0, 0.25, 0.75, 0.5, 0.75),
    };
}

fn piston_collision(facing: PhysicalState.Facing, extended: bool) Box(f64) {
    if (!extended) return full_cube;
    const t: f64 = 0.25;
    return switch (facing) {
        .down => collision_box(0, t, 0, 1, 1, 1),
        .up => collision_box(0, 0, 0, 1, 1 - t, 1),
        .north => collision_box(0, 0, t, 1, 1, 1),
        .south => collision_box(0, 0, 0, 1, 1, 1 - t),
        .west => collision_box(t, 0, 0, 1, 1, 1),
        .east => collision_box(0, 0, 0, 1 - t, 1, 1),
    };
}

fn piston_head_collisions(c: *Collisions, facing: PhysicalState.Facing) void {
    c.add(switch (facing) {
        .down => collision_box(0, 0, 0, 1, 0.25, 1),
        .up => collision_box(0, 0.75, 0, 1, 1, 1),
        .north => collision_box(0, 0, 0, 1, 1, 0.25),
        .south => collision_box(0, 0, 0.75, 1, 1, 1),
        .west => collision_box(0, 0, 0, 0.25, 1, 1),
        .east => collision_box(0.75, 0, 0, 1, 1, 1),
    });
    c.add(switch (facing) {
        .down => collision_box(0.375, 0.25, 0.375, 0.625, 1, 0.625),
        .up => collision_box(0.375, 0, 0.375, 0.625, 0.75, 0.625),
        .north => collision_box(0.25, 0.375, 0.25, 0.75, 0.625, 1),
        .south => collision_box(0.25, 0.375, 0, 0.75, 0.625, 0.75),
        .west => collision_box(0.375, 0.25, 0.25, 0.625, 0.75, 1),
        .east => collision_box(0, 0.375, 0.25, 0.75, 0.625, 0.75),
    });
}

fn door_collision(facing: PhysicalState.DoorFacing, open: bool, hinge: PhysicalState.DoorHinge) Box(f64) {
    const t: f64 = 0.1875;
    if (open) return switch (facing) {
        .east => if (hinge == .right) collision_box(0, 0, 1 - t, 1, 1, 1) else collision_box(0, 0, 0, 1, 1, t),
        .south => if (hinge == .right) collision_box(0, 0, 0, t, 1, 1) else collision_box(1 - t, 0, 0, 1, 1, 1),
        .west => if (hinge == .right) collision_box(0, 0, 0, 1, 1, t) else collision_box(0, 0, 1 - t, 1, 1, 1),
        .north => if (hinge == .right) collision_box(1 - t, 0, 0, 1, 1, 1) else collision_box(0, 0, 0, t, 1, 1),
    };
    return switch (facing) {
        .east => collision_box(0, 0, 0, t, 1, 1),
        .south => collision_box(0, 0, 0, 1, 1, t),
        .west => collision_box(1 - t, 0, 0, 1, 1, 1),
        .north => collision_box(0, 0, 1 - t, 1, 1, 1),
    };
}

fn fence_gate_collision(open: bool, facing: PhysicalState.PackedHorizontalFacing) ?Box(f64) {
    if (open) return null;
    return switch (facing) {
        .north, .south => collision_box(0, 0, 0.375, 1, 1.5, 0.625),
        .west, .east => collision_box(0.375, 0, 0, 0.625, 1.5, 1),
    };
}

fn fence_collisions(c: *Collisions, north: bool, south: bool, west: bool, east: bool) void {
    const width: f64 = 0.375; // 4/16 post, centred

    // A neighbour on an axis extends the post out to that edge, so the box covers
    // the post plus however far it connects.
    const z0: f64 = if (north) 0 else width;
    const z1: f64 = if (south) 1 else 1 - width;
    if (north or south) c.add(collision_box(width, 0, z0, 1 - width, 1.5, z1));

    const x0: f64 = if (west) 0 else width;
    const x1: f64 = if (east) 1 else 1 - width;
    // an unconnected fence is still one post
    if (west or east or !(north or south)) c.add(collision_box(x0, 0, width, x1, 1.5, 1 - width));
}

fn pane_collisions(c: *Collisions, north: bool, south: bool, west: bool, east: bool) void {
    const width: f64 = 0.4375; // 2/16 thick, centred
    const far: f64 = 1 - width;
    const anchored = north or south or west or east;

    // A pane joined on both sides of an axis spans it; joined on one side it only
    // covers that half. Joined on neither it contributes no box, except when it is
    // unconnected everywhere - vanilla still gives that case the full post.
    if (west and east) {
        c.add(collision_box(0, 0, width, 1, 1, far));
    } else if (west) {
        c.add(collision_box(0, 0, width, 0.5, 1, far));
    } else if (east) {
        c.add(collision_box(0.5, 0, width, 1, 1, far));
    } else if (!anchored) {
        c.add(collision_box(0, 0, width, 1, 1, far));
    }

    if (north and south) {
        c.add(collision_box(width, 0, 0, far, 1, 1));
    } else if (north) {
        c.add(collision_box(width, 0, 0, far, 1, 0.5));
    } else if (south) {
        c.add(collision_box(width, 0, 0.5, far, 1, 1));
    } else if (!anchored) {
        c.add(collision_box(width, 0, 0, far, 1, 1));
    }
}

fn wall_collision(north: bool, south: bool, west: bool, east: bool) Box(f64) {
    const width: f64 = 0.25; // 8/16 wall, centred
    const x0: f64 = if (west) 0 else width;
    const x1: f64 = if (east) 1 else 1 - width;
    const z0: f64 = if (north) 0 else width;
    const z1: f64 = if (south) 1 else 1 - width;

    // When joined on both sides of one axis and neither side of the other,
    // the wall narrows to 5/16 across the unconnected axis.
    if (north and south and !(west or east)) return collision_box(0.3125, 0, z0, 0.6875, 1.5, z1);
    if (west and east and !(north or south)) return collision_box(x0, 0, 0.3125, x1, 1.5, 0.6875);

    return collision_box(x0, 0, z0, x1, 1.5, z1);
}

fn funnel_collisions(c: *Collisions, inner_height: f64) void {
    c.add(collision_box(0, 0, 0, 1, inner_height, 1));
    c.add(collision_box(0, 0, 0, 0.125, 1, 1));
    c.add(collision_box(0, 0, 0, 1, 1, 0.125));
    c.add(collision_box(0.875, 0, 0, 1, 1, 1));
    c.add(collision_box(0, 0, 0.875, 1, 1, 1));
}

fn stair_base_collision(half: PhysicalState.Half) Box(f64) {
    return if (half == .top)
        collision_box(0, 0.5, 0, 1, 1, 1)
    else
        collision_box(0, 0, 0, 1, 0.5, 1);
}

fn stair_collisions(c: *Collisions, facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: VirtualState.StairShape) void {
    const y0: f64 = if (half == .top) 0 else 0.5;
    const y1: f64 = if (half == .top) 0.5 else 1;

    var bx0: f64 = 0;
    var bx1: f64 = 1;
    var bz0: f64 = 0;
    var bz1: f64 = 1;
    switch (facing) {
        .east => bx0 = 0.5,
        .west => bx1 = 0.5,
        .north => bz1 = 0.5,
        .south => bz0 = 0.5,
    }

    const axis_is_x = facing == .north or facing == .south;
    const base_low = facing == .east or facing == .north;
    const is_left = shape == .inner_left or shape == .outer_left;
    const low = (base_low != (half == .top)) == is_left;
    const s0: f64 = if (low) 0 else 0.5;
    const s1: f64 = if (low) 0.5 else 1;

    c.add(stair_base_collision(half));

    const split = shape == .outer_left or shape == .outer_right;
    c.add(if (split)
        (if (axis_is_x)
            collision_box(s0, y0, bz0, s1, y1, bz1)
        else
            collision_box(bx0, y0, s0, bx1, y1, s1))
    else
        collision_box(bx0, y0, bz0, bx1, y1, bz1));

    if (shape == .inner_left or shape == .inner_right) {
        c.add(if (axis_is_x)
            collision_box(s0, y0, 1 - bz1, s1, y1, 1 - bz0)
        else
            collision_box(1 - bx1, y0, s0, 1 - bx0, y1, s1));
    }
}
