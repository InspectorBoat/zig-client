const Block = @import("block.zig").Block;

pub const VirtualState = union(Block) {
    air: packed struct {},
    stone: packed struct { variant: StoneVariant },
    grass: packed struct { snowy: bool },
    dirt: packed struct { variant: DirtVariant, snowy: bool },
    cobblestone: packed struct {},
    planks: packed struct { variant: WoodVariant },
    sapling: packed struct { variant: WoodVariant, stage: u1 },
    bedrock: packed struct {},
    flowing_water: packed struct { level: u4 },
    water: packed struct { level: u4 },
    flowing_lava: packed struct { level: u4 },
    lava: packed struct { level: u4 },
    sand: packed struct { variant: SandVariant },
    gravel: packed struct {},
    gold_ore: packed struct {},
    iron_ore: packed struct {},
    coal_ore: packed struct {},
    log: packed struct { variant: WoodVariant1, axis: LogAxis },
    leaves: packed struct { variant: WoodVariant1, not_decayable: bool, check_decay: bool },
    sponge: packed struct { wet: bool },
    glass: packed struct {},
    lapis_ore: packed struct {},
    lapis_block: packed struct {},
    dispenser: packed struct { facing: Facing, triggered: bool },
    sandstone: packed struct { variant: SandstoneVariant },
    noteblock: packed struct {},
    bed: packed struct { facing: PackedHorizontalFacing, occupied: bool, part: BedPart },
    golden_rail: packed struct { shape: StraightRailShape, powered: bool },
    detector_rail: packed struct { shape: StraightRailShape, powered: bool },
    sticky_piston: packed struct { facing: Facing, extended: bool },
    web: packed struct {},
    tallgrass: packed struct { variant: TallGrassVariant },
    deadbush: packed struct {},
    piston: packed struct { facing: Facing, extended: bool },
    piston_head: packed struct { facing: Facing, sticky: bool },
    wool: packed struct { color: Color },
    piston_extension: packed struct { facing: Facing, sticky: bool },
    yellow_flower: packed struct {},
    red_flower: packed struct { variant: RedFlowerVariant },
    brown_mushroom: packed struct {},
    red_mushroom: packed struct {},
    gold_block: packed struct {},
    iron_block: packed struct {},
    double_stone_slab: packed struct { variant: StoneSlabVariant, seamless: bool },
    stone_slab: packed struct { variant: StoneSlabVariant, half: Half },
    brick_block: packed struct {},
    tnt: packed struct { explode: bool },
    bookshelf: packed struct {},
    mossy_cobblestone: packed struct {},
    obsidian: packed struct {},
    torch: packed struct { facing: TorchFacing },
    fire: packed struct { age: u4, flip: bool, alt: bool, north: bool, east: bool, south: bool, west: bool },
    mob_spawner: packed struct {},
    oak_stairs: packed struct { facing: StairFacing, half: Half, shape: StairShape },
    chest: packed struct { facing: HorizontalFacing },
    redstone_wire: packed struct { power: u4, north: RedstoneWireConnection, east: RedstoneWireConnection, south: RedstoneWireConnection, west: RedstoneWireConnection },
    diamond_ore: packed struct {},
    diamond_block: packed struct {},
    crafting_table: packed struct {},
    wheat: packed struct { age: u3 },
    farmland: packed struct { moisture: u3 },
    furnace: packed struct { facing: HorizontalFacing },
    lit_furnace: packed struct { facing: HorizontalFacing },
    standing_sign: packed struct { rotation: u4 },
    wooden_door: packed struct { hinge_right: bool, powered: bool, open: bool, facing: PackedHorizontalFacing },
    ladder: packed struct { facing: HorizontalFacing },
    rail: packed struct { shape: CurveableRailShape },
    stone_stairs: packed struct { facing: StairFacing, half: Half, shape: StairShape },
    wall_sign: packed struct { facing: HorizontalFacing },
    lever: packed struct { facing: LeverFacing, powered: bool },
    stone_pressure_plate: packed struct { powered: bool },
    iron_door: packed struct { hinge_right: bool, powered: bool, open: bool, facing: PackedHorizontalFacing },
    wooden_pressure_plate: packed struct { powered: bool },
    redstone_ore: packed struct {},
    lit_redstone_ore: packed struct {},
    unlit_redstone_torch: packed struct { facing: TorchFacing },
    redstone_torch: packed struct { facing: TorchFacing },
    stone_button: packed struct { facing: ButtonFacing, powered: bool },
    snow_layer: packed struct { layers: u3 },
    ice: packed struct {},
    snow: packed struct {},
    cactus: packed struct { age: u4 },
    clay: packed struct {},
    reeds: packed struct { age: u4 },
    jukebox: packed struct { has_record: bool },
    fence: packed struct { north: bool, east: bool, south: bool, west: bool },
    pumpkin: packed struct { facing: PackedHorizontalFacing },
    netherrack: packed struct {},
    soul_sand: packed struct {},
    glowstone: packed struct {},
    portal: packed struct { axis: PortalAxis },
    lit_pumpkin: packed struct { facing: PackedHorizontalFacing },
    cake: packed struct { bites: u3 },
    unpowered_repeater: packed struct { facing: PackedHorizontalFacing, delay: RepeaterDelay },
    powered_repeater: packed struct { facing: PackedHorizontalFacing, delay: RepeaterDelay },
    stained_glass: packed struct { color: Color },
    trapdoor: packed struct { facing: PackedHorizontalFacing, open: bool, half: Half },
    monster_egg: packed struct { variant: MonsterEggVariant },
    stonebrick: packed struct { variant: StoneBrickVariant },
    brown_mushroom_block: packed struct { variant: MushroomBlockVariant },
    red_mushroom_block: packed struct { variant: MushroomBlockVariant },
    iron_bars: packed struct { north: bool, east: bool, south: bool, west: bool },
    glass_pane: packed struct { north: bool, east: bool, south: bool, west: bool },
    melon_block: packed struct {},
    pumpkin_stem: packed struct { age: u3, facing: StemFacing },
    melon_stem: packed struct { age: u3, facing: StemFacing },
    vine: packed struct { south: bool, west: bool, north: bool, east: bool, up: bool },
    fence_gate: packed struct { facing: PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool },
    brick_stairs: packed struct { facing: StairFacing, half: Half, shape: StairShape },
    stone_brick_stairs: packed struct { facing: StairFacing, half: Half, shape: StairShape },
    mycelium: packed struct { snowy: bool },
    waterlily: packed struct {},
    nether_brick: packed struct {},
    nether_brick_fence: packed struct { north: bool, east: bool, south: bool, west: bool },
    nether_brick_stairs: packed struct { facing: StairFacing, half: Half, shape: StairShape },
    nether_wart: packed struct { age: NetherWartAge },
    enchanting_table: packed struct {},
    brewing_stand: packed struct { has_bottle_0: bool, has_bottle_1: bool, has_bottle_2: bool },
    cauldron: packed struct { level: u2 },
    end_portal: packed struct {},
    end_portal_frame: packed struct { facing: PackedHorizontalFacing, eye: bool },
    end_stone: packed struct {},
    dragon_egg: packed struct {},
    redstone_lamp: packed struct {},
    lit_redstone_lamp: packed struct {},
    double_wooden_slab: packed struct { variant: WoodVariant },
    wooden_slab: packed struct { variant: WoodVariant, half: Half },
    cocoa: packed struct { facing: PackedHorizontalFacing, age: u2 },
    sandstone_stairs: packed struct { facing: StairFacing, half: Half, shape: StairShape },
    emerald_ore: packed struct {},
    ender_chest: packed struct { facing: HorizontalFacing },
    tripwire_hook: packed struct { facing: PackedHorizontalFacing, attached: bool, powered: bool, suspended: bool },
    tripwire: packed struct { powered: bool, suspended: bool, attached: bool, disarmed: bool, north: bool, east: bool, south: bool, west: bool },
    emerald_block: packed struct {},
    spruce_stairs: packed struct { facing: StairFacing, half: Half, shape: StairShape },
    birch_stairs: packed struct { facing: StairFacing, half: Half, shape: StairShape },
    jungle_stairs: packed struct { facing: StairFacing, half: Half, shape: StairShape },
    command_block: packed struct { triggered: bool },
    beacon: packed struct {},
    cobblestone_wall: packed struct { variant: CobblestoneWallVariant, up: bool, north: bool, east: bool, south: bool, west: bool },
    flower_pot: packed struct { legacy_data: u4 },
    carrots: packed struct { age: u3 },
    potatoes: packed struct { age: u3 },
    wooden_button: packed struct { facing: ButtonFacing, powered: bool },
    skull: packed struct { facing: Facing, nodrop: bool },
    anvil: packed struct { facing: PackedHorizontalFacing, damage: u2 },
    trapped_chest: packed struct { facing: HorizontalFacing },
    light_weighted_pressure_plate: packed struct { power: u4 },
    heavy_weighted_pressure_plate: packed struct { power: u4 },
    unpowered_comparator: packed struct { facing: PackedHorizontalFacing, subtract: bool, powered: bool },
    powered_comparator: packed struct { facing: PackedHorizontalFacing, subtract: bool, powered: bool },
    daylight_detector: packed struct { power: u4 },
    redstone_block: packed struct {},
    quartz_ore: packed struct {},
    hopper: packed struct { facing: HopperFacing, disabled: bool },
    quartz_block: packed struct { variant: QuartzBlockVariant },
    quartz_stairs: packed struct { facing: StairFacing, half: Half, shape: StairShape },
    activator_rail: packed struct { shape: StraightRailShape, powered: bool },
    dropper: packed struct { facing: Facing, triggered: bool },
    stained_hardened_clay: packed struct { color: Color },
    stained_glass_pane: packed struct { color: Color, north: bool, east: bool, south: bool, west: bool },
    leaves2: packed struct { variant: WoodVariant2, not_decayable: bool, check_decay: bool },
    log2: packed struct { variant: WoodVariant2, axis: LogAxis },
    acacia_stairs: packed struct { facing: StairFacing, half: Half, shape: StairShape },
    dark_oak_stairs: packed struct { facing: StairFacing, half: Half, shape: StairShape },
    slime: packed struct {},
    barrier: packed struct {},
    iron_trapdoor: packed struct { facing: PackedHorizontalFacing, open: bool, half: Half },
    prismarine: packed struct { variant: PrismarineVariant },
    sea_lantern: packed struct {},
    hay_block: packed struct { axis: HayBlockAxis },
    carpet: packed struct { color: Color },
    hardened_clay: packed struct {},
    coal_block: packed struct {},
    packed_ice: packed struct {},
    double_plant: packed struct { variant: DoublePlantVariant, half: DoublePlantHalf },
    standing_banner: packed struct { rotation: u4 },
    wall_banner: packed struct { facing: HorizontalFacing },
    daylight_detector_inverted: packed struct { power: u4 },
    red_sandstone: packed struct { variant: RedSandstoneVariant },
    red_sandstone_stairs: packed struct { facing: StairFacing, half: Half, shape: StairShape },
    double_stone_slab2: packed struct { seamless: bool },
    stone_slab2: packed struct { half: Half },
    spruce_fence_gate: packed struct { facing: PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool },
    birch_fence_gate: packed struct { facing: PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool },
    jungle_fence_gate: packed struct { facing: PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool },
    dark_oak_fence_gate: packed struct { facing: PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool },
    acacia_fence_gate: packed struct { facing: PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool },
    spruce_fence: packed struct { north: bool, east: bool, south: bool, west: bool },
    birch_fence: packed struct { north: bool, east: bool, south: bool, west: bool },
    jungle_fence: packed struct { north: bool, east: bool, south: bool, west: bool },
    dark_oak_fence: packed struct { north: bool, east: bool, south: bool, west: bool },
    acacia_fence: packed struct { north: bool, east: bool, south: bool, west: bool },
    spruce_door: packed struct { hinge_right: bool, powered: bool, open: bool, facing: PackedHorizontalFacing },
    birch_door: packed struct { hinge_right: bool, powered: bool, open: bool, facing: PackedHorizontalFacing },
    jungle_door: packed struct { hinge_right: bool, powered: bool, open: bool, facing: PackedHorizontalFacing },
    acacia_door: packed struct { hinge_right: bool, powered: bool, open: bool, facing: PackedHorizontalFacing },
    dark_oak_door: packed struct { hinge_right: bool, powered: bool, open: bool, facing: PackedHorizontalFacing },

    pub fn resolve(physical: PhysicalBlockState, world: *const World, block_pos: Vector3(i32)) @This() {
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
                .up = world.getBlock(block_pos.up()).isFullCube(),
            } },
            .tripwire_hook => .{ .tripwire_hook = .{
                .facing = physical.payload(.tripwire_hook).facing,
                .attached = physical.payload(.tripwire_hook).attached,
                .powered = physical.payload(.tripwire_hook).powered,
                .suspended = !hasSolidTop(world.getBlock(block_pos.down())),
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
                    break :blk if (world.getBlockState(block_pos.down()).maybePayload(.double_plant)) |other| other.variant else .sunflower;
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
                        .open = physical.payload(block).other.when_lower.open,
                        .facing = physical.payload(block).other.when_lower.facing,
                        .hinge_right = if (maybe_neighbor) |neighbor| neighbor.other.when_upper.hinge_right else false,
                        .powered = if (maybe_neighbor) |neighbor| neighbor.other.when_upper.powered else false,
                    } else .{
                        .open = if (maybe_neighbor) |neighbor| neighbor.other.when_lower.open else false,
                        .facing = if (maybe_neighbor) |neighbor| neighbor.other.when_lower.facing else .north,
                        .hinge_right = physical.payload(block).other.when_upper.hinge_right,
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

            inline else => |block| {
                var properties: @FieldType(VirtualState, @tagName(block)) = undefined;
                inline for (@typeInfo(@TypeOf(properties)).@"struct".fields) |field| {
                    @field(properties, field.name) = @field(physical.payload(block), field.name);
                }
                return @unionInit(@This(), @tagName(block), properties);
            },
        };
    }
};

pub const StairShape = enum(u3) { straight, inner_left, inner_right, outer_left, outer_right };
pub const StemFacing = enum(u3) { up = 0, north = 1, south = 2, west = 3, east = 4 };
pub const DoorFacing = enum(u2) { north = 0, south = 1, west = 2, east = 3 };
pub const RedstoneWireConnection = enum(u2) { up, side, none };

const physical_properties = @import("physical_properties.zig");

const PhysicalProperties = physical_properties.PhysicalProperties;

const StairFacing = physical_properties.StairFacing;
const Facing = physical_properties.Facing;
const HorizontalFacing = physical_properties.HorizontalFacing;
const PackedHorizontalFacing = physical_properties.PackedHorizontalFacing;
const TorchFacing = physical_properties.TorchFacing;
const ButtonFacing = physical_properties.ButtonFacing;
const LeverFacing = physical_properties.LeverFacing;
const HopperFacing = physical_properties.HopperFacing;
const WoodVariant = physical_properties.WoodVariant;
const WoodVariant1 = physical_properties.WoodVariant1;
const WoodVariant2 = physical_properties.WoodVariant2;
const RepeaterDelay = physical_properties.RepeaterDelay;
const LogAxis = physical_properties.LogAxis;
const Half = physical_properties.Half;
const StoneVariant = physical_properties.StoneVariant;
const DirtVariant = physical_properties.DirtVariant;
const SandVariant = physical_properties.SandVariant;
const SandstoneVariant = physical_properties.SandstoneVariant;
const RedSandstoneVariant = physical_properties.RedSandstoneVariant;
const StraightRailShape = physical_properties.StraightRailShape;
const Color = physical_properties.Color;
const NetherWartAge = physical_properties.NetherWartAge;
const CurveableRailShape = physical_properties.CurveableRailShape;
const QuartzBlockVariant = physical_properties.QuartzBlockVariant;
const DoorHalf = physical_properties.DoorHalf;
const BedPart = physical_properties.BedPart;
const TallGrassVariant = physical_properties.TallGrassVariant;
const RedFlowerVariant = physical_properties.RedFlowerVariant;
const StoneSlabVariant = physical_properties.StoneSlabVariant;
const MonsterEggVariant = physical_properties.MonsterEggVariant;
const PortalAxis = physical_properties.PortalAxis;
const StoneBrickVariant = physical_properties.StoneBrickVariant;
const MushroomBlockVariant = physical_properties.MushroomBlockVariant;
const CobblestoneWallVariant = physical_properties.CobblestoneWallVariant;
const PrismarineVariant = physical_properties.PrismarineVariant;
const HayBlockAxis = physical_properties.HayBlockAxis;
const DoublePlantVariant = physical_properties.DoublePlantVariant;
const DoublePlantHalf = physical_properties.DoublePlantHalf;

const PhysicalBlockState = @import("block.zig").PhysicalBlockState;
const root = @import("root");
const World = root.World;
const Vector3 = root.Vector3;
const Direction = root.Direction;

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

fn hasSolidTop(block: Block) bool {
    _ = block;
    return false;
}

fn stemFacingFor(world: *const World, block_pos: Vector3(i32), self_block: Block) StemFacing {
    const plant: Block = if (self_block == .pumpkin_stem) .melon_block else .pumpkin;
    if (world.getBlock(block_pos.north()) == plant) return .north;
    if (world.getBlock(block_pos.south()) == plant) return .south;
    if (world.getBlock(block_pos.west()) == plant) return .west;
    if (world.getBlock(block_pos.east()) == plant) return .east;
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

fn stairProps(state: PhysicalBlockState) @FieldType(PhysicalProperties, "oak_stairs") {
    return state.properties.oak_stairs;
}

comptime {
    _ = VirtualState;
    _ = &VirtualState.resolve;
}
