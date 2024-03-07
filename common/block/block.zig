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

pub const Block = enum(u8) {
    Air,
    Stone,
    Grass,
    Dirt,
    Cobblestone,
    Planks,
    Sapling,
    Bedrock,
    FlowingWater,
    Water,
    FlowingLava,
    Lava,
    Sand,
    Gravel,
    GoldOre,
    IronOre,
    CoalOre,
    Log,
    Leaves,
    Sponge,
    Glass,
    LapisOre,
    LapisBlock,
    Dispenser,
    Sandstone,
    Noteblock,
    Bed,
    GoldenRail,
    DetectorRail,
    StickyPiston,
    Web,
    Tallgrass,
    Deadbush,
    Piston,
    PistonHead,
    Wool,
    PistonExtension,
    YellowFlower,
    RedFlower,
    BrownMushroom,
    RedMushroom,
    GoldBlock,
    IronBlock,
    DoubleStoneSlab,
    StoneSlab,
    BrickBlock,
    Tnt,
    Bookshelf,
    MossyCobblestone,
    Obsidian,
    Torch,
    Fire,
    MobSpawner,
    OakStairs,
    Chest,
    RedstoneWire,
    DiamondOre,
    DiamondBlock,
    CraftingTable,
    Wheat,
    Farmland,
    Furnace,
    LitFurnace,
    StandingSign,
    WoodenDoor,
    Ladder,
    Rail,
    StoneStairs,
    WallSign,
    Lever,
    StonePressurePlate,
    IronDoor,
    WoodenPressurePlate,
    RedstoneOre = 73,
    LitRedstoneOre,
    UnlitRedstoneTorch,
    RedstoneTorch,
    StoneButton = 77,
    SnowLayer,
    Ice,
    Snow,
    Cactus,
    Clay,
    Reeds,
    Jukebox,
    Fence,
    Pumpkin,
    Netherrack,
    SoulSand,
    Glowstone,
    Portal,
    LitPumpkin,
    Cake,
    UnpoweredRepeater,
    PoweredRepeater,
    StainedGlass,
    Trapdoor,
    MonsterEgg,
    Stonebrick,
    BrownMushroomBlock,
    RedMushroomBlock,
    IronBars,
    GlassPane,
    MelonBlock,
    PumpkinStem,
    MelonStem,
    Vine,
    FenceGate,
    BrickStairs,
    StoneBrickStairs,
    Mycelium,
    Waterlily,
    NetherBrick,
    NetherBrickFence,
    NetherBrickStairs,
    NetherWart,
    EnchantingTable,
    BrewingStand,
    Cauldron,
    EndPortal,
    EndPortalFrame,
    EndStone,
    DragonEgg,
    RedstoneLamp,
    LitRedstoneLamp,
    DoubleWoodenSlab,
    WoodenSlab,
    Cocoa,
    SandstoneStairs,
    EmeraldOre,
    EnderChest,
    TripwireHook,
    Tripwire,
    EmeraldBlock,
    SpruceStairs,
    BirchStairs,
    JungleStairs,
    CommandBlock,
    Beacon,
    CobblestoneWall,
    FlowerPot,
    Carrots,
    Potatoes,
    WoodenButton,
    Skull,
    Anvil,
    TrappedChest,
    LightWeightedPressurePlate,
    HeavyWeightedPressurePlate,
    UnpoweredComparator,
    PoweredComparator,
    DaylightDetector,
    RedstoneBlock,
    QuartzOre,
    Hopper,
    QuartzBlock,
    QuartzStairs,
    ActivatorRail,
    Dropper,
    StainedHardenedClay,
    StainedGlassPane,
    Leaves2,
    Log2,
    AcaciaStairs,
    DarkOakStairs,
    Slime,
    Barrier,
    IronTrapdoor,
    Prismarine,
    SeaLantern,
    HayBlock,
    Carpet,
    HardenedClay,
    CoalBlock,
    PackedIce,
    DoublePlant,
    StandingBanner,
    WallBanner,
    DaylightDetectorInverted,
    RedSandstone,
    RedSandstoneStairs,
    DoubleStoneSlab2,
    StoneSlab2,
    SpruceFenceGate,
    BirchFenceGate,
    JungleFenceGate,
    DarkOakFenceGate,
    AcaciaFenceGate,
    SpruceFence,
    BirchFence,
    JungleFence,
    DarkOakFence,
    AcaciaFence,
    SpruceDoor,
    BirchDoor,
    JungleDoor,
    AcaciaDoor,
    DarkOakDoor,
};

// The raw bytes sent over
pub const RawStoredBlockState = packed struct {
    block: Block,
    metadata: u4,

    fn unimplemented() noreturn {
        @panic("Unimplemented");
    }

    pub fn toConcreteBlockState(self: @This()) ConcreteBlockState {
        switch (self.block) {
            .Air => return .Air,
            .Stone => return .{ .Stone = .{ .variant = enumFromIntDefault0(StoneType, self.metadata) } },
            .Grass => unimplemented(),
            .Dirt => unimplemented(),
            .Cobblestone => return .Cobblestone,
            .Planks => return .{ .Planks = .{ .variant = enumFromIntDefault0(WoodType, self.metadata) } },
            .Sapling => return .{ .Sapling = .{ .variant = enumFromIntDefault0(WoodType, self.metadata) } },
            .Bedrock => return .Bedrock,
            .FlowingWater => return .{ .FlowingWater = .{ .level = self.metadata } },
            .Water => return .{ .Water = .{ .level = self.metadata } },
            .FlowingLava => return .{ .FlowingLava = .{ .level = self.metadata } },
            .Lava => return .{ .Lava = .{ .level = self.metadata } },
            .Sand => return .{ .Sand = .{ .variant = enumFromIntDefault0(SandType, self.metadata) } },
            .Gravel => return .Gravel,
            .GoldOre => return .GoldOre,
            .IronOre => return .IronOre,
            .CoalOre => return .CoalOre,
            .Log => {
                const Metadata = packed struct(u4) { variant: WoodType1, axis: LogAxis };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .Log = .{
                    .variant = metadata.variant,
                    .axis = metadata.axis,
                } };
            },
            .Leaves => {
                const Metadata = packed struct(u4) { variant: WoodType1, decayable: bool, check_decay: bool };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .Leaves = .{
                    .variant = metadata.variant,
                    .decayable = metadata.decayable,
                    .check_decay = metadata.check_decay,
                } };
            },
            .Sponge => {
                const Metadata = packed struct(u4) {
                    wet: bool,
                    _: u3,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{
                    .Sponge = .{ .wet = metadata.wet },
                };
            },
            .Glass => return .Glass,
            .LapisOre => return .LapisOre,
            .LapisBlock => return .LapisBlock,
            .Dispenser => {
                const Metadata = packed struct {
                    facing: u3,
                    triggered: bool,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .Dispenser = .{
                    .facing = enumFromIntModulo(Facing, metadata.facing),
                    .triggered = metadata.triggered,
                } };
            },
            .Sandstone => return .{ .Sandstone = .{ .variant = enumFromIntDefault0(SandstoneType, self.metadata) } },
            .Noteblock => return .Noteblock,
            .Bed => {
                const Metadata = packed struct {
                    facing: HorizontalFacing,
                    occupied: bool,
                    part: BedHalf,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .Bed = .{
                    .facing = metadata.facing,
                    .occupied = if (metadata.part == .Head) metadata.occupied else undefined,
                    .part = metadata.part,
                } };
            },
            .GoldenRail => {
                const Metadata = packed struct {
                    shape: StraightRailShape,
                    powered: bool,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .GoldenRail = .{
                    .shape = metadata.shape,
                    .powered = metadata.powered,
                } };
            },
            .DetectorRail => {
                const Metadata = packed struct {
                    shape: StraightRailShape,
                    powered: bool,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .DetectorRail = .{
                    .shape = metadata.shape,
                    .powered = metadata.powered,
                } };
            },
            .StickyPiston => {
                const Metadata = packed struct {
                    facing: u3,
                    extended: bool,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .StickyPiston = .{
                    .facing = enumFromIntErroring(Facing, metadata.facing),
                    .extended = metadata.extended,
                } };
            },
            .Web => return .Web,
            .Tallgrass => return .{ .Tallgrass = .{ .variant = enumFromIntDefault0(TallgrassType, self.metadata) } },
            .Deadbush => return .Deadbush,
            .Piston => {
                const Metadata = packed struct {
                    facing: u3,
                    extended: bool,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .Piston = .{
                    .facing = enumFromIntErroring(Facing, metadata.facing),
                    .extended = metadata.extended,
                } };
            },
            .PistonHead => {
                const Metadata = packed struct {
                    facing: u3,
                    type: PistonType,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                // TODO: Is `short` even used?
                return .{ .PistonHead = .{
                    .facing = enumFromIntErroring(Facing, metadata.facing),
                    .type = metadata.type,
                    .short = undefined,
                } };
            },
            .Wool => return .{ .Wool = .{ .color = enumFromIntDefault0(Color, self.metadata) } },
            .PistonExtension => {
                const Metadata = packed struct {
                    facing: u3,
                    type: PistonType,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .PistonExtension = .{
                    .facing = enumFromIntErroring(Facing, metadata.facing),
                    .type = metadata.type,
                } };
            },
            .YellowFlower => return .YellowFlower,
            .RedFlower => return .RedFlower,
            .BrownMushroom => return .BrownMushroom,
            .RedMushroom => return .RedMushroom,
            .GoldBlock => return .GoldBlock,
            .IronBlock => return .IronBlock,
            .DoubleStoneSlab => {
                const Metadata = packed struct {
                    variant: StoneSlabType,
                    seamless: bool,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .DoubleStoneSlab = .{
                    .variant = metadata.variant,
                    .seamless = metadata.seamless,
                    .half = undefined,
                } };
            },
            .StoneSlab => {
                const Metadata = packed struct {
                    variant: StoneSlabType,
                    half: SingleSlabHalf,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .StoneSlab = .{
                    .variant = metadata.variant,
                    .half = metadata.half,
                } };
            },
            .BrickBlock => return .BrickBlock,
            .Tnt => {
                const Metadata = packed struct {
                    explode_on_break: bool,
                    // unused
                    _: u3,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .Tnt = .{
                    .explode_on_break = metadata.explode_on_break,
                } };
            },
            .Bookshelf => return .Bookshelf,
            .MossyCobblestone => return .MossyCobblestone,
            .Obsidian => return .Obsidian,
            .Torch => return .{ .Torch = .{ .facing = enumFromIntDefault(TorchFacing, self.metadata, .Up) } },
            .Fire => unimplemented(),
            .MobSpawner => return .MobSpawner,
            .OakStairs => {
                const Metadata = packed struct {
                    facing: StairFacing,
                    half: StairHalf,
                    _: u1,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .OakStairs = .{
                    .facing = metadata.facing,
                    .half = metadata.half,
                    .shape = unimplemented(),
                } };
            },
            .Chest => return .{ .Chest = .{ .facing = @enumFromInt(@rem(self.metadata, 6) -| 2) } },
            .RedstoneWire => return .{ .RedstoneWire = .{ .north = undefined, .east = undefined, .south = undefined, .west = undefined, .power = self.metadata } },
            .DiamondOre => return .DiamondOre,
            .DiamondBlock => return .DiamondBlock,
            .CraftingTable => return .CraftingTable,
            .Wheat => return .{ .Wheat = .{ .age = std.math.cast(u3, self.metadata) orelse std.debug.panic("Illegal wheat age", .{}) } },
            .Farmland => {
                const Metadata = packed struct {
                    moisture: u3,
                    _: u1,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .Farmland = .{
                    .moisture = metadata.moisture,
                } };
            },
            .Furnace => return .{ .Furnace = .{ .facing = @enumFromInt(@rem(self.metadata, 6) -| 2) } },
            .LitFurnace => return .{ .LitFurnace = .{ .facing = @enumFromInt(@rem(self.metadata, 6) -| 2) } },
            .StandingSign => return .{ .StandingSign = .{ .rotation = self.metadata } },
            .WoodenDoor => {
                const Metadata = packed struct {
                    other: packed union {
                        upper: packed struct {
                            hinge: DoorHinge,
                            powered: bool,
                            _: u1,
                        },
                        lower: packed struct {
                            facing: u2,
                            open: bool,
                        },
                    },
                    half: DoorHalf,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .WoodenDoor = .{
                    .half = metadata.half,
                    .hinge = if (metadata.half == .Upper) metadata.other.upper.hinge else undefined,
                    .powered = if (metadata.half == .Upper) metadata.other.upper.powered else undefined,
                    .facing = if (metadata.half == .Lower) @enumFromInt(metadata.other.lower.facing +% 3) else undefined,
                    .open = if (metadata.half == .Lower) metadata.other.lower.open else undefined,
                } };
            },
            .Ladder => return .{ .Ladder = .{ .facing = @enumFromInt(@rem(self.metadata, 6) -| 2) } },
            .Rail => return .{ .Rail = .{ .shape = enumFromIntDefault0(RailShape, self.metadata) } },
            .StoneStairs => {
                const Metadata = packed struct {
                    facing: StairFacing,
                    half: StairHalf,
                    _: u1,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .StoneStairs = .{
                    .facing = metadata.facing,
                    .half = metadata.half,
                    .shape = unimplemented(),
                } };
            },
            .WallSign => return .{ .WallSign = .{ .facing = @enumFromInt(@rem(self.metadata, 6) -| 2) } },
            .Lever => {
                const Metadata = packed struct {
                    facing: LeverFacing,
                    powered: bool,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .Lever = .{
                    .facing = metadata.facing,
                    .powered = metadata.powered,
                } };
            },
            .StonePressurePlate => {
                const Metadata = packed struct {
                    powered: bool,
                    _: u3,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .StonePressurePlate = .{ .powered = metadata.powered } };
            },
            .IronDoor => {
                const Metadata = packed struct {
                    other: packed union {
                        upper: packed struct {
                            hinge: DoorHinge,
                            powered: bool,
                            _: u1,
                        },
                        lower: packed struct {
                            facing: u2,
                            open: bool,
                        },
                    },
                    half: DoorHalf,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .IronDoor = .{
                    .half = metadata.half,
                    .hinge = if (metadata.half == .Upper) metadata.other.upper.hinge else undefined,
                    .powered = if (metadata.half == .Upper) metadata.other.upper.powered else undefined,
                    .facing = if (metadata.half == .Lower) @enumFromInt(metadata.other.lower.facing +% 3) else undefined,
                    .open = if (metadata.half == .Lower) metadata.other.lower.open else undefined,
                } };
            },
            .WoodenPressurePlate => {
                const Metadata = packed struct {
                    powered: bool,
                    _: u3,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .StonePressurePlate = .{ .powered = metadata.powered } };
            },
            .RedstoneOre => return .RedstoneOre,
            .LitRedstoneOre => return .LitRedstoneOre,
            .UnlitRedstoneTorch => return .{ .UnlitRedstoneTorch = .{ .facing = enumFromIntDefault(TorchFacing, self.metadata, .Up) } },
            .RedstoneTorch => return .{ .RedstoneTorch = .{ .facing = enumFromIntDefault(TorchFacing, self.metadata, .Up) } },
            .StoneButton => {
                const Metadata = packed struct {
                    facing: u3,
                    powered: bool,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .StoneButton = .{
                    .facing = enumFromIntDefault(Facing, self.metadata, .Up),
                    .powered = metadata.powered,
                } };
            },
            .SnowLayer => {
                const Metadata = packed struct {
                    layers: u3,
                    _: u1,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .SnowLayer = .{
                    .layers = metadata.layers,
                } };
            },
            .Ice => return .Ice,
            .Snow => return .Snow,
            .Cactus => return .{ .Cactus = .{ .age = self.metadata } },
            .Clay => return .Clay,
            .Reeds => return .{ .Reeds = .{ .age = self.metadata } },
            .Jukebox => return .{ .Jukebox = .{ .has_record = self.metadata > 0 } },
            .Fence => return unimplemented(),
            .Pumpkin => return .{ .Pumpkin = .{ .facing = enumFromIntModulo(HorizontalFacing, self.metadata) } },
            .Netherrack => return .Netherrack,
            .SoulSand => return .SoulSand,
            .Glowstone => return .Glowstone,
            .Portal => return .{ .Portal = .{ .axis = if (self.metadata & 3 == 2) .Z else .X } },
            .LitPumpkin => return .{ .LitPumpkin = .{ .facing = enumFromIntModulo(HorizontalFacing, self.metadata) } },
            .Cake => return .{ .Cake = .{ .bites = if (self.metadata <= 6) @truncate(self.metadata) else std.debug.panic("Cake had more than 6 slices eaten", .{}) } },
            .UnpoweredRepeater => {
                const Metadata = packed struct {
                    facing: HorizontalFacing,
                    delay: u2,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .UnpoweredRepeater = .{
                    .facing = metadata.facing,
                    .delay = metadata.delay,
                    .locked = unimplemented(),
                } };
            },
            .PoweredRepeater => {
                const Metadata = packed struct {
                    facing: HorizontalFacing,
                    delay: u2,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .PoweredRepeater = .{
                    .facing = metadata.facing,
                    .delay = metadata.delay,
                    .locked = unimplemented(),
                } };
            },
            .StainedGlass => return .{ .StainedGlass = .{ .color = @enumFromInt(self.metadata) } },
            .Trapdoor => {
                const Metadata = packed struct {
                    facing: u2,
                    open: bool,
                    half: TrapdoorHalf,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .Trapdoor = .{
                    .facing = switch (metadata.facing) {
                        0 => .North,
                        1 => .South,
                        2 => .West,
                        3 => .East,
                    },
                    .open = metadata.open,
                    .half = metadata.half,
                } };
            },
            .MonsterEgg => return .{ .MonsterEgg = .{ .variant = enumFromIntDefault0(MonsterEggType, self.metadata) } },
            .Stonebrick => return .{ .Stonebrick = .{ .variant = enumFromIntDefault0(StoneBrickType, self.metadata) } },
            .BrownMushroomBlock => return .{ .BrownMushroomBlock = .{ .sides = std.meta.intToEnum(MushroomSides, self.metadata) catch .AllInside } },
            .RedMushroomBlock => return .{ .RedMushroomBlock = .{ .sides = std.meta.intToEnum(MushroomSides, self.metadata) catch .AllInside } },
            .IronBars => return unimplemented(),
            .GlassPane => return unimplemented(),
            .MelonBlock => return .MelonBlock,
            .PumpkinStem => return .{ .PumpkinStem = .{ .age = std.math.cast(u3, self.metadata) orelse std.debug.panic("Pumpkin stem too old!", .{}), .facing = unimplemented() } },
            .MelonStem => return .{ .MelonStem = .{ .age = std.math.cast(u3, self.metadata) orelse std.debug.panic("Melon stem too old!", .{}), .facing = unimplemented() } },
            .Vine => {
                const Metadata = packed struct {
                    south: bool,
                    west: bool,
                    north: bool,
                    east: bool,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .Vine = .{
                    .south = metadata.south,
                    .west = metadata.west,
                    .north = metadata.north,
                    .east = metadata.east,
                    .up = unimplemented(),
                } };
            },
            .FenceGate => {
                const Metadata = packed struct {
                    facing: HorizontalFacing,
                    open: bool,
                    powered: bool,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .FenceGate = .{
                    .facing = metadata.facing,
                    .open = metadata.open,
                    .powered = metadata.powered,
                    .in_wall = unimplemented(),
                } };
            },
            .BrickStairs => {
                const Metadata = packed struct {
                    facing: StairFacing,
                    half: StairHalf,
                    _: u1,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .BrickStairs = .{
                    .facing = metadata.facing,
                    .half = metadata.half,
                    .shape = unimplemented(),
                } };
            },
            .StoneBrickStairs => {
                const Metadata = packed struct {
                    facing: StairFacing,
                    half: StairHalf,
                    _: u1,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .StoneBrickStairs = .{
                    .facing = metadata.facing,
                    .half = metadata.half,
                    .shape = unimplemented(),
                } };
            },
            .Mycelium => {},
            .Waterlily => {},
            .NetherBrick => {},
            .NetherBrickFence => {},
            .NetherBrickStairs => {},
            .NetherWart => {},
            .EnchantingTable => {},
            .BrewingStand => {},
            .Cauldron => {},
            .EndPortal => {},
            .EndPortalFrame => {},
            .EndStone => {},
            .DragonEgg => {},
            .RedstoneLamp => {},
            .LitRedstoneLamp => {},
            .DoubleWoodenSlab => {},
            .WoodenSlab => {},
            .Cocoa => {},
            .SandstoneStairs => {},
            .EmeraldOre => {},
            .EnderChest => {},
            .TripwireHook => {},
            .Tripwire => {},
            .EmeraldBlock => {},
            .SpruceStairs => {},
            .BirchStairs => {},
            .JungleStairs => {},
            .CommandBlock => {},
            .Beacon => {},
            .CobblestoneWall => {},
            .FlowerPot => {},
            .Carrots => {},
            .Potatoes => {},
            .WoodenButton => {},
            .Skull => {},
            .Anvil => {},
            .TrappedChest => {},
            .LightWeightedPressurePlate => {},
            .HeavyWeightedPressurePlate => {},
            .UnpoweredComparator => {},
            .PoweredComparator => {},
            .DaylightDetector => {},
            .RedstoneBlock => {},
            .QuartzOre => {},
            .Hopper => {},
            .QuartzBlock => {},
            .QuartzStairs => {},
            .ActivatorRail => {},
            .Dropper => {},
            .StainedHardenedClay => {},
            .StainedGlassPane => {},
            .Leaves2 => {},
            .Log2 => {},
            .AcaciaStairs => {},
            .DarkOakStairs => {},
            .Slime => {},
            .Barrier => {},
            .IronTrapdoor => {},
            .Prismarine => {},
            .SeaLantern => {},
            .HayBlock => {},
            .Carpet => {},
            .HardenedClay => {},
            .CoalBlock => {},
            .PackedIce => {},
            .DoublePlant => {},
            .StandingBanner => {},
            .WallBanner => {},
            .DaylightDetectorInverted => {},
            .RedSandstone => {},
            .RedSandstoneStairs => {},
            .DoubleStoneSlab2 => {},
            .StoneSlab2 => {},
            .SpruceFenceGate => {},
            .BirchFenceGate => {},
            .JungleFenceGate => {},
            .DarkOakFenceGate => {},
            .AcaciaFenceGate => {},
            .SpruceFence => {},
            .BirchFence => {},
            .JungleFence => {},
            .DarkOakFence => {},
            .AcaciaFence => {},
            .SpruceDoor => {},
            .BirchDoor => {},
            .JungleDoor => {},
            .AcaciaDoor => {},
            .DarkOakDoor => {},
        }
        unimplemented();
    }
};

// RawStoredBlockState, but stipped of invalid states and converted into a sane format
pub const FilteredStoredBlockState = packed struct {
    block: Block,
    metadata: packed union {
        Air: packed struct {},
        Stone: packed struct { variant: StoneType },
        Grass: packed struct {},
        Dirt: packed struct { variant: enum { Dirt, Podzol, Coarse } },
        Cobblestone: packed struct {},
        Planks: packed struct { variant: WoodType },
        Sapling: packed struct { variant: WoodType },
        Bedrock: packed struct {},
        FlowingWater: packed struct { level: u4 },
        Water: packed struct { level: u4 },
        FlowingLava: packed struct { level: u4 },
        Lava: packed struct { level: u4 },
        Sand: packed struct { variant: SandType },
        Gravel: packed struct {},
        GoldOre: packed struct {},
        IronOre: packed struct {},
        CoalOre: packed struct {},
        Log: packed struct { axis: LogAxis, variant: WoodType1 },
        Leaves: packed struct { variant: WoodType1, decayable: bool, check_decay: bool },
        Sponge: packed struct { wet: bool },
        Glass: packed struct {},
        LapisOre: packed struct {},
        LapisBlock: packed struct {},
        Dispenser: packed struct { facing: Facing, triggered: bool },
        Sandstone: packed struct { variant: SandstoneType },
        Noteblock: packed struct {},
        Bed: packed struct { facing: HorizontalFacing, part: BedHalf, occupied: bool },
        GoldenRail: packed struct { shape: StraightRailShape, powered: bool },
        DetectorRail: packed struct { shape: StraightRailShape, powered: bool },
        StickyPiston: packed struct { facing: Facing, extended: bool },
        Web: packed struct {},
        Tallgrass: packed struct { variant: TallgrassType },
        Deadbush: packed struct {},
        Piston: packed struct { facing: Facing, extended: bool },
        PistonHead: packed struct { facing: Facing, type: PistonType },
        Wool: packed struct { color: Color },
        PistonExtension: packed struct { facing: Facing, type: PistonType },
        YellowFlower: packed struct {},
        RedFlower: packed struct {},
        BrownMushroom: packed struct {},
        RedMushroom: packed struct {},
        GoldBlock: packed struct {},
        IronBlock: packed struct {},
        DoubleStoneSlab: packed struct { variant: StoneSlabType, seamless: bool },
        StoneSlab: packed struct { variant: StoneSlabType, half: SingleSlabHalf },
        BrickBlock: packed struct {},
        Tnt: packed struct { explode_on_break: bool },
        Bookshelf: packed struct {},
        MossyCobblestone: packed struct {},
        Obsidian: packed struct {},
        Torch: packed struct { facing: TorchFacing },
        Fire: packed struct { age: u4 },
        MobSpawner: packed struct {},
        OakStairs: packed struct { facing: StairFacing, half: StairHalf },
        Chest: packed struct { facing: HorizontalFacing },
        RedstoneWire: packed struct { power: u4 },
        DiamondOre: packed struct {},
        DiamondBlock: packed struct {},
        CraftingTable: packed struct {},
        Wheat: packed struct { age: u3 },
        Farmland: packed struct { moisture: u3 },
        Furnace: packed struct { facing: HorizontalFacing },
        LitFurnace: packed struct { facing: HorizontalFacing },
        StandingSign: packed struct { rotation: u4 },
        WoodenDoor: packed struct {
            other: packed union {
                when_upper: packed struct { hinge: DoorHinge, powered: bool },
                when_lower: packed struct { facing: HorizontalFacing, open: bool },
            },
            half: DoorHalf,
        },
        Ladder: packed struct { facing: HorizontalFacing },
        Rail: packed struct { shape: RailShape },
        StoneStairs: packed struct { facing: StairFacing, half: StairHalf }, // fixed
        WallSign: packed struct { facing: HorizontalFacing },
        Lever: packed struct { facing: LeverFacing, powered: bool },
        StonePressurePlate: packed struct { powered: bool },
        IronDoor: packed struct {
            other: packed union {
                when_upper: packed struct { hinge: DoorHinge, powered: bool },
                when_lower: packed struct { facing: HorizontalFacing, open: bool },
            },
            half: DoorHalf,
        },
        WoodenPressurePlate: packed struct { powered: bool },
        RedstoneOre: packed struct {},
        LitRedstoneOre: packed struct {},
        UnlitRedstoneTorch: packed struct { facing: TorchFacing },
        RedstoneTorch: packed struct { facing: TorchFacing },
        StoneButton: packed struct { facing: Facing, powered: bool },
        SnowLayer: packed struct { layers: u3 },
        Ice: packed struct {},
        Snow: packed struct {},
        Cactus: packed struct { age: u4 },
        Clay: packed struct {},
        Reeds: packed struct { age: u4 },
        Jukebox: packed struct { has_record: bool },
        Fence: packed struct {},
        Pumpkin: packed struct { facing: HorizontalFacing },
        Netherrack: packed struct {},
        SoulSand: packed struct {},
        Glowstone: packed struct {},
        Portal: packed struct { axis: HorizontalAxis },
        LitPumpkin: packed struct { facing: HorizontalFacing },
        Cake: packed struct { bites: u3 },
        UnpoweredRepeater: packed struct { facing: HorizontalFacing, delay: u2 },
        PoweredRepeater: packed struct { facing: HorizontalFacing, delay: u2 },
        StainedGlass: packed struct { color: Color },
        Trapdoor: packed struct { facing: HorizontalFacing, open: bool, half: TrapdoorHalf },
        MonsterEgg: packed struct { variant: MonsterEggType },
        Stonebrick: packed struct { variant: StoneBrickType },
        BrownMushroomBlock: packed struct { sides: MushroomSides },
        RedMushroomBlock: packed struct { sides: MushroomSides },
        IronBars: packed struct { north: bool, east: bool, south: bool, west: bool },
        GlassPane: packed struct { north: bool, east: bool, south: bool, west: bool },
        MelonBlock: packed struct {},
        PumpkinStem: packed struct { age: u4 },
        MelonStem: packed struct { age: u4 },
        Vine: packed struct { north: bool, east: bool, south: bool, west: bool },
        FenceGate: packed struct { facing: HorizontalFacing, open: bool, powered: bool },
        BrickStairs: packed struct { facing: StairFacing, half: StairHalf }, // fixed
        StoneBrickStairs: packed struct { facing: StairFacing, half: StairHalf }, // fixed
        Mycelium: packed struct {},
        Waterlily: packed struct {},
        NetherBrick: packed struct {},
        NetherBrickFence: packed struct {},
        NetherBrickStairs: packed struct { facing: StairFacing, half: StairHalf }, // fixed
        NetherWart: packed struct { age: u2 },
        EnchantingTable: packed struct {},
        BrewingStand: packed struct { has_bottle_0: bool, has_bottle_1: bool, has_bottle_2: bool },
        Cauldron: packed struct { level: u2 },
        EndPortal: packed struct {},
        EndPortalFrame: packed struct { facing: HorizontalFacing, eye: bool },
        EndStone: packed struct {},
        DragonEgg: packed struct {},
        RedstoneLamp: packed struct {},
        LitRedstoneLamp: packed struct {},
        DoubleWoodenSlab: packed struct { variant: WoodType, half: SingleSlabHalf },
        WoodenSlab: packed struct { variant: WoodType },
        Cocoa: packed struct { age: u2 },
        SandstoneStairs: packed struct { facing: StairFacing, half: StairHalf }, // fixed
        EmeraldOre: packed struct {},
        EnderChest: packed struct { facing: HorizontalFacing },
        TripwireHook: packed struct { facing: HorizontalFacing, powered: bool, attached: bool },
        Tripwire: packed struct { powered: bool, suspended: bool, attached: bool, disarmed: bool },
        EmeraldBlock: packed struct {},
        SpruceStairs: packed struct { facing: StairFacing, half: StairHalf }, // fixed
        BirchStairs: packed struct { facing: StairFacing, half: StairHalf }, // fixed
        JungleStairs: packed struct { facing: StairFacing, half: StairHalf }, // fixed
        CommandBlock: packed struct { triggered: bool },
        Beacon: packed struct {},
        CobblestoneWall: packed struct { variant: CobblestoneWallVariant },
        FlowerPot: packed struct { legacy_data: u4 },
        Carrots: packed struct { age: u4 },
        Potatoes: packed struct { age: u4 },
        WoodenButton: packed struct { facing: Facing, powered: bool },
        Skull: packed struct { facing: Facing, no_drop: bool },
        Anvil: packed struct { facing: HorizontalAxis, damage: u2 },
        TrappedChest: packed struct { facing: HorizontalFacing },
        LightWeightedPressurePlate: packed struct { power: u4 },
        HeavyWeightedPressurePlate: packed struct { power: u4 },
        UnpoweredComparator: packed struct { powered: bool, mode: ComparatorMode },
        PoweredComparator: packed struct { powered: bool, mode: ComparatorMode },
        DaylightDetector: packed struct { power: u4 },
        RedstoneBlock: packed struct {},
        QuartzOre: packed struct {},
        Hopper: packed struct { facing: HopperFacing, enabled: bool },
        QuartzBlock: packed struct {},
        QuartzStairs: packed struct { facing: StairFacing, half: StairHalf }, // fixed
        ActivatorRail: packed struct { shape: StraightRailShape, powered: bool },
        Dropper: packed struct { facing: Facing, triggered: bool },
        StainedHardenedClay: packed struct { color: Color },
        StainedGlassPane: packed struct { color: Color },
        Leaves2: packed struct { variant: WoodType2, decayable: bool, check_decay: bool },
        Log2: packed struct { axis: LogAxis, variant: WoodType2 },
        AcaciaStairs: packed struct { facing: StairFacing, half: StairHalf }, // fixed
        DarkOakStairs: packed struct { facing: StairFacing, half: StairHalf }, // fixed
        Slime: packed struct {},
        Barrier: packed struct {},
        IronTrapdoor: packed struct { facing: HorizontalFacing, open: bool, half: TrapdoorHalf },
        Prismarine: packed struct { variant: PrismarineType },
        SeaLantern: packed struct {},
        HayBlock: packed struct {},
        Carpet: packed struct { color: Color },
        HardenedClay: packed struct {},
        CoalBlock: packed struct {},
        PackedIce: packed struct {},
        DoublePlant: packed struct { variant: DoublePlantType, half: DoublePlantHalf, facing: HorizontalAxis },
        StandingBanner: packed struct { rotation: u4 },
        WallBanner: packed struct { facing: HorizontalFacing },
        DaylightDetectorInverted: packed struct { power: u4 },
        RedSandstone: packed struct { variant: RedSandstoneType },
        RedSandstoneStairs: packed struct { facing: StairFacing, half: StairHalf }, // fixed
        DoubleStoneSlab2: packed struct { half: SlabHalf },
        StoneSlab2: packed struct { half: SlabHalf },
        SpruceFenceGate: packed struct { facing: HorizontalAxis, open: bool, powered: bool, in_wall: bool },
        BirchFenceGate: packed struct { facing: HorizontalAxis, open: bool, powered: bool, in_wall: bool },
        JungleFenceGate: packed struct { facing: HorizontalAxis, open: bool, powered: bool, in_wall: bool },
        DarkOakFenceGate: packed struct { facing: HorizontalAxis, open: bool, powered: bool, in_wall: bool },
        AcaciaFenceGate: packed struct { facing: HorizontalAxis, open: bool, powered: bool, in_wall: bool },
        SpruceFence: packed struct {},
        BirchFence: packed struct {},
        JungleFence: packed struct {},
        DarkOakFence: packed struct {},
        AcaciaFence: packed struct {},
        SpruceDoor: packed struct {
            other: packed union {
                when_upper: packed struct { hinge: DoorHinge, powered: bool },
                when_lower: packed struct { facing: HorizontalFacing, open: bool },
            },
            half: DoorHalf,
        },
        BirchDoor: packed struct {
            other: packed union {
                when_upper: packed struct { hinge: DoorHinge, powered: bool },
                when_lower: packed struct { facing: HorizontalFacing, open: bool },
            },
            half: DoorHalf,
        },
        JungleDoor: packed struct {
            other: packed union {
                when_upper: packed struct { hinge: DoorHinge, powered: bool },
                when_lower: packed struct { facing: HorizontalFacing, open: bool },
            },
            half: DoorHalf,
        },
        AcaciaDoor: packed struct {
            other: packed union {
                when_upper: packed struct { hinge: DoorHinge, powered: bool },
                when_lower: packed struct { facing: HorizontalFacing, open: bool },
            },
            half: DoorHalf,
        },
        DarkOakDoor: packed struct {
            other: packed union {
                when_upper: packed struct { hinge: DoorHinge, powered: bool },
                when_lower: packed struct { facing: HorizontalFacing, open: bool },
            },
            half: DoorHalf,
        },
    },
};

pub const ConcreteBlockState = union(Block) {
    Air: struct {},
    Stone: struct { variant: StoneType },
    Grass: struct { snowy: bool },
    Dirt: struct { variant: enum { Dirt, Podzol, Coarse }, snowy: bool },
    Cobblestone: struct {},
    Planks: struct { variant: WoodType },
    Sapling: struct { variant: WoodType },
    Bedrock: struct {},
    FlowingWater: struct { level: u4 },
    Water: struct { level: u4 },
    FlowingLava: struct { level: u4 },
    Lava: struct { level: u4 },
    Sand: struct { variant: SandType },
    Gravel: struct {},
    GoldOre: struct {},
    IronOre: struct {},
    CoalOre: struct {},
    Log: struct { axis: LogAxis, variant: WoodType1 },
    Leaves: struct { variant: WoodType1, decayable: bool, check_decay: bool },
    Sponge: struct { wet: bool },
    Glass: struct {},
    LapisOre: struct {},
    LapisBlock: struct {},
    Dispenser: struct { facing: Facing, triggered: bool },
    Sandstone: struct { variant: SandstoneType },
    Noteblock: struct {},
    Bed: struct { facing: HorizontalFacing, part: BedHalf, occupied: bool },
    GoldenRail: struct { shape: StraightRailShape, powered: bool },
    DetectorRail: struct { shape: StraightRailShape, powered: bool },
    StickyPiston: struct { facing: Facing, extended: bool },
    Web: struct {},
    Tallgrass: struct { variant: TallgrassType },
    Deadbush: struct {},
    Piston: struct { facing: Facing, extended: bool },
    PistonHead: struct { facing: Facing, type: PistonType, short: bool },
    Wool: struct { color: Color },
    PistonExtension: struct { facing: Facing, type: PistonType },
    YellowFlower: struct {},
    RedFlower: struct {},
    BrownMushroom: struct {},
    RedMushroom: struct {},
    GoldBlock: struct {},
    IronBlock: struct {},
    DoubleStoneSlab: struct { variant: StoneSlabType, seamless: bool, half: SlabHalf },
    StoneSlab: struct { variant: StoneSlabType, half: SingleSlabHalf },
    BrickBlock: struct {},
    Tnt: struct { explode_on_break: bool },
    Bookshelf: struct {},
    MossyCobblestone: struct {},
    Obsidian: struct {},
    Torch: struct { facing: TorchFacing },
    Fire: struct { age: u4, flip: bool, alt: bool, north: bool, east: bool, south: bool, west: bool, upper: u2 }, // upper is 0...2
    MobSpawner: struct {},
    OakStairs: struct { facing: StairFacing, half: StairHalf, shape: StairShape },
    Chest: struct { facing: HorizontalFacing },
    RedstoneWire: struct { north: WireConnectionSide, east: WireConnectionSide, south: WireConnectionSide, west: WireConnectionSide, power: u4 },
    DiamondOre: struct {},
    DiamondBlock: struct {},
    CraftingTable: struct {},
    Wheat: struct { age: u3 },
    Farmland: struct { moisture: u3 },
    Furnace: struct { facing: HorizontalFacing },
    LitFurnace: struct { facing: HorizontalFacing },
    StandingSign: struct { rotation: u4 },
    WoodenDoor: struct { facing: HorizontalFacing, open: bool, hinge: DoorHinge, powered: bool, half: DoorHalf },
    Ladder: struct { facing: HorizontalFacing },
    Rail: struct { shape: RailShape },
    StoneStairs: struct { facing: StairFacing, half: StairHalf, shape: StairShape },
    WallSign: struct { facing: HorizontalFacing },
    Lever: struct { facing: LeverFacing, powered: bool },
    StonePressurePlate: struct { powered: bool },
    IronDoor: struct { facing: HorizontalFacing, open: bool, hinge: DoorHinge, powered: bool, half: DoorHalf },
    WoodenPressurePlate: struct { powered: bool },
    RedstoneOre: struct {},
    LitRedstoneOre: struct {},
    UnlitRedstoneTorch: struct { facing: TorchFacing },
    RedstoneTorch: struct { facing: TorchFacing },
    StoneButton: struct { facing: Facing, powered: bool },
    SnowLayer: struct { layers: u4 },
    Ice: struct {},
    Snow: struct {},
    Cactus: struct { age: u4 },
    Clay: struct {},
    Reeds: struct { age: u4 },
    Jukebox: struct { has_record: bool },
    Fence: struct { north: bool, east: bool, south: bool, west: bool },
    Pumpkin: struct { facing: HorizontalFacing },
    Netherrack: struct {},
    SoulSand: struct {},
    Glowstone: struct {},
    Portal: struct { axis: HorizontalAxis },
    LitPumpkin: struct { facing: HorizontalFacing },
    Cake: struct { bites: u3 },
    UnpoweredRepeater: struct { facing: HorizontalFacing, locked: bool, delay: u2 },
    PoweredRepeater: struct { facing: HorizontalFacing, locked: bool, delay: u2 },
    StainedGlass: struct { color: Color },
    Trapdoor: struct { facing: HorizontalFacing, open: bool, half: TrapdoorHalf },
    MonsterEgg: struct { variant: MonsterEggType },
    Stonebrick: struct { variant: StoneBrickType },
    BrownMushroomBlock: struct { sides: MushroomSides },
    RedMushroomBlock: struct { sides: MushroomSides },
    IronBars: struct { north: bool, east: bool, south: bool, west: bool },
    GlassPane: struct { north: bool, east: bool, south: bool, west: bool },
    MelonBlock: struct {},
    PumpkinStem: struct { age: u4, facing: StemFacing },
    MelonStem: struct { age: u4, facing: StemFacing },
    Vine: struct { up: bool, north: bool, east: bool, south: bool, west: bool },
    FenceGate: struct { facing: HorizontalFacing, open: bool, powered: bool, in_wall: bool },
    BrickStairs: struct { facing: StairFacing, half: StairHalf, shape: StairShape },
    StoneBrickStairs: struct { facing: StairFacing, half: StairHalf, shape: StairShape },
    Mycelium: struct {},
    Waterlily: struct {},
    NetherBrick: struct {},
    NetherBrickFence: struct { north: bool, east: bool, south: bool, west: bool },
    NetherBrickStairs: struct { facing: StairFacing, half: StairHalf, shape: StairShape },
    NetherWart: struct { age: u2 },
    EnchantingTable: struct {},
    BrewingStand: struct { has_bottle_0: bool, has_bottle_1: bool, has_bottle_2: bool },
    Cauldron: struct { level: u2 },
    EndPortal: struct {},
    EndPortalFrame: struct { facing: HorizontalFacing, eye: bool },
    EndStone: struct {},
    DragonEgg: struct {},
    RedstoneLamp: struct {},
    LitRedstoneLamp: struct {},
    DoubleWoodenSlab: struct { variant: WoodType, half: SlabHalf },
    WoodenSlab: struct { variant: WoodType, half: SlabHalf },
    Cocoa: struct { age: u2 },
    SandstoneStairs: struct { facing: StairFacing, half: StairHalf, shape: StairShape },
    EmeraldOre: struct {},
    EnderChest: struct { facing: HorizontalFacing },
    TripwireHook: struct { facing: HorizontalFacing, powered: bool, attached: bool, suspended: bool },
    Tripwire: struct { powered: bool, suspended: bool, attached: bool, disarmed: bool, north: bool, east: bool, south: bool, west: bool },
    EmeraldBlock: struct {},
    SpruceStairs: struct { facing: StairFacing, half: StairHalf, shape: StairShape },
    BirchStairs: struct { facing: StairFacing, half: StairHalf, shape: StairShape },
    JungleStairs: struct { facing: StairFacing, half: StairHalf, shape: StairShape },
    CommandBlock: struct { triggered: bool },
    Beacon: struct {},
    CobblestoneWall: struct { up: bool, north: bool, east: bool, south: bool, variant: CobblestoneWallVariant },
    FlowerPot: struct { legacy_data: u4, contents: FlowerPotContents },
    Carrots: struct { age: u4 },
    Potatoes: struct { age: u4 },
    WoodenButton: struct { facing: Facing, powered: bool },
    Skull: struct { facing: Facing, no_drop: bool },
    Anvil: struct { facing: HorizontalAxis, damage: u2 },
    TrappedChest: struct { facing: HorizontalFacing },
    LightWeightedPressurePlate: struct { power: u4 },
    HeavyWeightedPressurePlate: struct { power: u4 },
    UnpoweredComparator: struct { powered: bool, mode: ComparatorMode },
    PoweredComparator: struct { powered: bool, mode: ComparatorMode },
    DaylightDetector: struct { power: u4 },
    RedstoneBlock: struct {},
    QuartzOre: struct {},
    Hopper: struct { facing: HopperFacing, enabled: bool },
    QuartzBlock: struct {},
    QuartzStairs: struct { facing: StairFacing, half: StairHalf, shape: StairShape },
    ActivatorRail: struct { shape: StraightRailShape, powered: bool },
    Dropper: struct { facing: Facing, triggered: bool },
    StainedHardenedClay: struct { color: Color },
    StainedGlassPane: struct { north: bool, east: bool, south: bool, west: bool, color: Color },
    Leaves2: struct { variant: WoodType2, decayable: bool, check_decay: bool },
    Log2: struct { axis: LogAxis, variant: WoodType2 },
    AcaciaStairs: struct { facing: StairFacing, half: StairHalf, shape: StairShape },
    DarkOakStairs: struct { facing: StairFacing, half: StairHalf, shape: StairShape },
    Slime: struct {},
    Barrier: struct {},
    IronTrapdoor: struct { facing: HorizontalFacing, open: bool, half: TrapdoorHalf },
    Prismarine: struct { variant: PrismarineType },
    SeaLantern: struct {},
    HayBlock: struct {},
    Carpet: struct { color: Color },
    HardenedClay: struct {},
    CoalBlock: struct {},
    PackedIce: struct {},
    DoublePlant: struct { half: DoublePlantHalf, variant: DoublePlantType },
    StandingBanner: struct { rotation: u4 },
    WallBanner: struct { facing: HorizontalFacing },
    DaylightDetectorInverted: struct { power: u4 },
    RedSandstone: struct { variant: RedSandstoneType },
    RedSandstoneStairs: struct { facing: StairFacing, half: StairHalf, shape: StairShape },
    DoubleStoneSlab2: struct { half: SlabHalf },
    StoneSlab2: struct { half: SlabHalf },
    SpruceFenceGate: struct { facing: HorizontalAxis, open: bool, powered: bool, in_wall: bool },
    BirchFenceGate: struct { facing: HorizontalAxis, open: bool, powered: bool, in_wall: bool },
    JungleFenceGate: struct { facing: HorizontalAxis, open: bool, powered: bool, in_wall: bool },
    DarkOakFenceGate: struct { facing: HorizontalAxis, open: bool, powered: bool, in_wall: bool },
    AcaciaFenceGate: struct { facing: HorizontalAxis, open: bool, powered: bool, in_wall: bool },
    SpruceFence: struct { north: bool, east: bool, south: bool, west: bool },
    BirchFence: struct { north: bool, east: bool, south: bool, west: bool },
    JungleFence: struct { north: bool, east: bool, south: bool, west: bool },
    DarkOakFence: struct { north: bool, east: bool, south: bool, west: bool },
    AcaciaFence: struct { north: bool, east: bool, south: bool, west: bool },
    SpruceDoor: struct { facing: HorizontalFacing, open: bool, hinge: DoorHinge, powered: bool, half: DoorHalf },
    BirchDoor: struct { facing: HorizontalFacing, open: bool, hinge: DoorHinge, powered: bool, half: DoorHalf },
    JungleDoor: struct { facing: HorizontalFacing, open: bool, hinge: DoorHinge, powered: bool, half: DoorHalf },
    AcaciaDoor: struct { facing: HorizontalFacing, open: bool, hinge: DoorHinge, powered: bool, half: DoorHalf },
    DarkOakDoor: struct { facing: HorizontalFacing, open: bool, hinge: DoorHinge, powered: bool, half: DoorHalf },
};

pub const StoneBrickType = enum { Default, Mossy, Cracked, Chiseled };

pub const MonsterEggType = enum { Stone, Cobblestone, Stonebrick, MossyStonebrick, CrackedStonebrick, ChiseledStonebrick };

pub const StoneType = enum(u3) { Stone = 0, Granite = 1, SmoothGranite = 2, Diorite = 3, SmoothDiorite = 4, Andesite = 5, SmoothAndesite = 6 };

pub const WoodType = enum(u3) { Oak = 0, Spruce = 1, Birch = 2, Jungle = 3, Acacia = 4, DarkOak = 5 };
pub const WoodType1 = enum(u2) { Oak = 0, Spruce = 1, Birch = 2, Jungle = 3 };
pub const WoodType2 = enum(u2) { Acacia, DarkOak };

pub const StoneSlabType = enum(u3) { Stone = 0, Sand = 1, Wood = 2, Cobblestone = 3, Brick = 4, Smoothbrick = 5, Netherbrick = 6, Quartz = 7 };

pub const SandType = enum(u1) { Sand = 0, RedSand = 1 };

pub const LogAxis = enum(u2) { X = 1, Y = 0, Z = 2, None = 3 };

pub const Axis = enum { X, Y, Z };
pub const HorizontalAxis = enum { X, Z };
pub const Facing = enum(u3) { Down = 0, Up = 1, North = 2, South = 3, West = 4, East = 5 };
pub const HorizontalFacing = enum(u2) { South = 0, West = 1, North = 2, East = 3 };

pub const LeverFacing = enum(u3) { DownX = 0, East = 1, West = 2, South = 3, North = 4, UpX = 5, UpZ = 6, DownZ = 7 };

pub const TorchFacing = enum(u3) { East = 1, West = 2, South = 3, North = 4, Up = 5 };
pub const StemFacing = enum { Up, East, West, North, South };
pub const HopperFacing = enum { Down, East, West, North, South };

pub const RailShape = enum(u4) { NorthSouth = 0, EastWest = 1, AscendingEast = 2, AscendingWest = 3, AscendingNorth = 4, AscendingSouth = 5, SouthEast = 6, SouthWest = 7, NorthWest = 8, NorthEast = 9 };
pub const StraightRailShape = enum(u3) { NorthSouth = 0, EastWest = 1, AscendingEast = 2, AscendingWest = 3, AscendingNorth = 4, AscendingSouth = 5 };

pub const Color = enum(u4) { White = 0, Orange = 1, Magenta = 2, LightBlue = 3, Yellow = 4, Lime = 5, Pink = 6, Gray = 7, Silver = 8, Cyan = 9, Purple = 10, Blue = 11, Brown = 12, Green = 13, Red = 14, Black = 15 };

pub const PistonType = enum(u1) { Default = 0, Sticky = 1 };

pub const SlabHalf = enum { Top, Bottom, Both };
pub const SingleSlabHalf = enum(u1) { Bottom = 0, Top = 1 };

pub const StairHalf = enum(u1) { Bottom = 0, Top = 1 };
pub const StairShape = enum { Straight, InnerLeft, InnerRight, OuterLeft, OuterRigth };
pub const StairFacing = enum(u2) { East = 0, West = 1, South = 2, North = 3 };

pub const WireConnectionSide = enum { Up, Side, None };

// what the fuck mojang???
pub const MushroomSides = enum(u4) { NorthWest = 1, North = 2, NorthEast = 3, West = 4, Center = 5, East = 6, SouthWest = 7, South = 8, SouthEast = 9, Stem = 10, AllInside = 0, AllOutside = 14, AllStem = 15 };

pub const DoorHinge = enum(u1) { Left = 0, Right = 1 };
pub const DoorHalf = enum { Upper, Lower };
pub const TrapdoorHalf = enum(u1) { Bottom = 0, Top = 1 };

pub const CobblestoneWallVariant = enum { Normal, Mossy };

pub const FlowerPotContents = enum { Empty, Poppy, BlueOrchid, Allium, Houstonia, RedTulip, OrangeTulip, WhiteTulip, PinkTulip, OxeyeDaisy, Dandelion, OakSapling, SpruceSapling, BirchSapling, JungleSapling, AcaciaSapling, DarkOakSapling, MushroomRed, MushroomBrown, Deadbush, Fern, Cactus };

pub const ComparatorMode = enum { Compare, Subtract };

pub const PrismarineType = enum { Rough, Bricks, Dark };

pub const DoublePlantType = enum(u3) { Sunflower, Syringa, Grass, Fern, Rose, Paeonia };
pub const DoublePlantHalf = enum(u1) { Upper, Lower };

pub const SandstoneType = enum { Default, Chiseled, Smooth };
pub const RedSandstoneType = enum { Default, Chiseled, Smooth };

pub const BedHalf = enum(u1) { Foot = 0, Head = 1 };

pub const TallgrassType = enum(u2) { Deadbush = 0, Grass = 1, Fern = 2 };

test ConcreteBlockState {
    // for (0..197) |block_id| {
    //     const block: Block = @enumFromInt(block_id);
    //     std.debug.print("\n", .{});
    //     for (0..16) |metadata| {
    //         std.debug.print("{}", .{if (isValid(@intFromEnum(block), @intCast(metadata))) @as(usize, 1) else @as(usize, 0)});
    //     }
    // }
    const union_field = @typeInfo(FilteredStoredBlockState).Struct.fields[1].type;
    inline for (@typeInfo(union_field).Union.fields) |field| {
        std.debug.print("name: {s} | size: {}\n", .{ field.name, @bitSizeOf(field.type) });
    }
    std.debug.print("size: {}\n", .{@bitSizeOf(FilteredStoredBlockState)});
}

pub export fn isValid(block_id: u16, metadata: u8) bool {
    const block: Block = @enumFromInt(block_id);
    return valid_metadata_table.get(block).isSet(metadata);
}

/// A table of valid metadata values for each block
/// A zero represents an valid value and a one represents a valid value
/// For example, the only valid metadata value for .Air is 0
const valid_metadata_table = blk: {
    var table = std.EnumArray(Block, std.bit_set.IntegerBitSet(16)).initFill(std.bit_set.IntegerBitSet(16).initEmpty());
    table.set(.Air, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Stone, .{ .mask = @bitReverse(@as(u16, 0b1111111000000000)) });
    table.set(.Grass, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Dirt, .{ .mask = @bitReverse(@as(u16, 0b1110000000000000)) });
    table.set(.Cobblestone, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Planks, .{ .mask = @bitReverse(@as(u16, 0b1111110000000000)) });
    table.set(.Sapling, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.Bedrock, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.FlowingWater, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.Water, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.FlowingLava, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.Lava, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.Sand, .{ .mask = @bitReverse(@as(u16, 0b1100000000000000)) });
    table.set(.Gravel, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.GoldOre, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.IronOre, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.CoalOre, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Log, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.Leaves, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.Sponge, .{ .mask = @bitReverse(@as(u16, 0b1100000000000000)) });
    table.set(.Glass, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.LapisOre, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.LapisBlock, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Dispenser, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.Sandstone, .{ .mask = @bitReverse(@as(u16, 0b1110000000000000)) });
    table.set(.Noteblock, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Bed, .{ .mask = @bitReverse(@as(u16, 0b1111000011111111)) });
    table.set(.GoldenRail, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.DetectorRail, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.StickyPiston, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.Web, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Tallgrass, .{ .mask = @bitReverse(@as(u16, 0b1110000000000000)) });
    table.set(.Deadbush, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Piston, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.PistonHead, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.Wool, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.PistonExtension, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.YellowFlower, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.RedFlower, .{ .mask = @bitReverse(@as(u16, 0b1111111110000000)) });
    table.set(.BrownMushroom, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.RedMushroom, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.GoldBlock, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.IronBlock, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.DoubleStoneSlab, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.StoneSlab, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.BrickBlock, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Tnt, .{ .mask = @bitReverse(@as(u16, 0b1100000000000000)) });
    table.set(.Bookshelf, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.MossyCobblestone, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Obsidian, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Torch, .{ .mask = @bitReverse(@as(u16, 0b0111110000000000)) });
    table.set(.Fire, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.MobSpawner, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.OakStairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.Chest, .{ .mask = @bitReverse(@as(u16, 0b0011110000000000)) });
    table.set(.RedstoneWire, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.DiamondOre, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.DiamondBlock, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.CraftingTable, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Wheat, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.Farmland, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.Furnace, .{ .mask = @bitReverse(@as(u16, 0b0011110000000000)) });
    table.set(.LitFurnace, .{ .mask = @bitReverse(@as(u16, 0b0011110000000000)) });
    table.set(.StandingSign, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.WoodenDoor, .{ .mask = @bitReverse(@as(u16, 0b1111111111110000)) });
    table.set(.Ladder, .{ .mask = @bitReverse(@as(u16, 0b0011110000000000)) });
    table.set(.Rail, .{ .mask = @bitReverse(@as(u16, 0b1111111111000000)) });
    table.set(.StoneStairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.WallSign, .{ .mask = @bitReverse(@as(u16, 0b0011110000000000)) });
    table.set(.Lever, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.StonePressurePlate, .{ .mask = @bitReverse(@as(u16, 0b1100000000000000)) });
    table.set(.IronDoor, .{ .mask = @bitReverse(@as(u16, 0b1111111111110000)) });
    table.set(.WoodenPressurePlate, .{ .mask = @bitReverse(@as(u16, 0b1100000000000000)) });
    table.set(.RedstoneOre, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.LitRedstoneOre, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.UnlitRedstoneTorch, .{ .mask = @bitReverse(@as(u16, 0b0111110000000000)) });
    table.set(.RedstoneTorch, .{ .mask = @bitReverse(@as(u16, 0b0111110000000000)) });
    table.set(.StoneButton, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.SnowLayer, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.Ice, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Snow, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Cactus, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.Clay, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Reeds, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.Jukebox, .{ .mask = @bitReverse(@as(u16, 0b1100000000000000)) });
    table.set(.Fence, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Pumpkin, .{ .mask = @bitReverse(@as(u16, 0b1111000000000000)) });
    table.set(.Netherrack, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.SoulSand, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Glowstone, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Portal, .{ .mask = @bitReverse(@as(u16, 0b0110000000000000)) });
    table.set(.LitPumpkin, .{ .mask = @bitReverse(@as(u16, 0b1111000000000000)) });
    table.set(.Cake, .{ .mask = @bitReverse(@as(u16, 0b1111111000000000)) });
    table.set(.UnpoweredRepeater, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.PoweredRepeater, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.StainedGlass, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.Trapdoor, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.MonsterEgg, .{ .mask = @bitReverse(@as(u16, 0b1111110000000000)) });
    table.set(.Stonebrick, .{ .mask = @bitReverse(@as(u16, 0b1111000000000000)) });
    table.set(.BrownMushroomBlock, .{ .mask = @bitReverse(@as(u16, 0b1111111111100011)) });
    table.set(.RedMushroomBlock, .{ .mask = @bitReverse(@as(u16, 0b1111111111100011)) });
    table.set(.IronBars, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.GlassPane, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.MelonBlock, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.PumpkinStem, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.MelonStem, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.Vine, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.FenceGate, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.BrickStairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.StoneBrickStairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.Mycelium, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Waterlily, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.NetherBrick, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.NetherBrickFence, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.NetherBrickStairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.NetherWart, .{ .mask = @bitReverse(@as(u16, 0b1111000000000000)) });
    table.set(.EnchantingTable, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.BrewingStand, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.Cauldron, .{ .mask = @bitReverse(@as(u16, 0b1111000000000000)) });
    table.set(.EndPortal, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.EndPortalFrame, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.EndStone, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.DragonEgg, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.RedstoneLamp, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.LitRedstoneLamp, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.DoubleWoodenSlab, .{ .mask = @bitReverse(@as(u16, 0b1111110000000000)) });
    table.set(.WoodenSlab, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.Cocoa, .{ .mask = @bitReverse(@as(u16, 0b1111111111110000)) });
    table.set(.SandstoneStairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.EmeraldOre, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.EnderChest, .{ .mask = @bitReverse(@as(u16, 0b0011110000000000)) });
    table.set(.TripwireHook, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.Tripwire, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.EmeraldBlock, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.SpruceStairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.BirchStairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.JungleStairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.CommandBlock, .{ .mask = @bitReverse(@as(u16, 0b1100000000000000)) });
    table.set(.Beacon, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.CobblestoneWall, .{ .mask = @bitReverse(@as(u16, 0b1100000000000000)) });
    table.set(.FlowerPot, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.Carrots, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.Potatoes, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.WoodenButton, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.Skull, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.Anvil, .{ .mask = @bitReverse(@as(u16, 0b1111111111110000)) });
    table.set(.TrappedChest, .{ .mask = @bitReverse(@as(u16, 0b0011110000000000)) });
    table.set(.LightWeightedPressurePlate, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.HeavyWeightedPressurePlate, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.UnpoweredComparator, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.PoweredComparator, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.DaylightDetector, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.RedstoneBlock, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.QuartzOre, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Hopper, .{ .mask = @bitReverse(@as(u16, 0b1011110010111100)) });
    table.set(.QuartzBlock, .{ .mask = @bitReverse(@as(u16, 0b1111100000000000)) });
    table.set(.QuartzStairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.ActivatorRail, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.Dropper, .{ .mask = @bitReverse(@as(u16, 0b1111110011111100)) });
    table.set(.StainedHardenedClay, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.StainedGlassPane, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.Leaves2, .{ .mask = @bitReverse(@as(u16, 0b1100110011001100)) });
    table.set(.Log2, .{ .mask = @bitReverse(@as(u16, 0b1100110011001100)) });
    table.set(.AcaciaStairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.DarkOakStairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.Slime, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.Barrier, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.IronTrapdoor, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.Prismarine, .{ .mask = @bitReverse(@as(u16, 0b1110000000000000)) });
    table.set(.SeaLantern, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.HayBlock, .{ .mask = @bitReverse(@as(u16, 0b1000100010000000)) });
    table.set(.Carpet, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.HardenedClay, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.CoalBlock, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.PackedIce, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.DoublePlant, .{ .mask = @bitReverse(@as(u16, 0b1111110011110000)) });
    table.set(.StandingBanner, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.WallBanner, .{ .mask = @bitReverse(@as(u16, 0b0011110000000000)) });
    table.set(.DaylightDetectorInverted, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.RedSandstone, .{ .mask = @bitReverse(@as(u16, 0b1110000000000000)) });
    table.set(.RedSandstoneStairs, .{ .mask = @bitReverse(@as(u16, 0b1111111100000000)) });
    table.set(.DoubleStoneSlab2, .{ .mask = @bitReverse(@as(u16, 0b1000000010000000)) });
    table.set(.StoneSlab2, .{ .mask = @bitReverse(@as(u16, 0b1000000010000000)) });
    table.set(.SpruceFenceGate, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.BirchFenceGate, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.JungleFenceGate, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.DarkOakFenceGate, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.AcaciaFenceGate, .{ .mask = @bitReverse(@as(u16, 0b1111111111111111)) });
    table.set(.SpruceFence, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.BirchFence, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.JungleFence, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.DarkOakFence, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.AcaciaFence, .{ .mask = @bitReverse(@as(u16, 0b1000000000000000)) });
    table.set(.SpruceDoor, .{ .mask = @bitReverse(@as(u16, 0b1111111111110000)) });
    table.set(.BirchDoor, .{ .mask = @bitReverse(@as(u16, 0b1111111111110000)) });
    table.set(.JungleDoor, .{ .mask = @bitReverse(@as(u16, 0b1111111111110000)) });
    table.set(.AcaciaDoor, .{ .mask = @bitReverse(@as(u16, 0b1111111111110000)) });
    break :blk table;
};
