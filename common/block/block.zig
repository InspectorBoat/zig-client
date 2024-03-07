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

pub const Block = enum(u12) {
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
    PoweredRail,
    DetectorRail,
    StickyPiston,
    Web,
    TallGrass,
    DeadBush,
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

pub const StoredBlockState = packed struct {
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
            .PoweredRail => {
                const Metadata = packed struct {
                    shape: StraightRailShape,
                    powered: bool,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .PoweredRail = .{
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
            .TallGrass => return .{ .TallGrass = .{ .variant = enumFromIntDefault0(TallGrassType, self.metadata) } },
            .DeadBush => return .DeadBush,
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
                    .facing = metadata.layers,
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
            .LitPumpkin => return .LitPumpkin,
            .Cake => return .{ .Cake = .{ .bites = if (self.metadata <= 6) self.metadata else std.debug.panic("Cake had more than 6 slices eaten", .{}) } },
            .UnpoweredRepeater => {
                const Metadata = packed struct {
                    facing: HorizontalFacing,
                    delay: u2,
                };
                const metadata: Metadata = @bitCast(self.metadata);
                return .{ .UnpoweredRepeater = .{
                    .facing = metadata.facing,
                    .delay = metadata.delay,
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
            .PumpkinStem => return .{ .PumpkinStem = .{ .age = std.math.cast(u3, self.metadata) catch std.debug.panic("Pumpkin stem too old!", .{}) } },
            .MelonStem => return .{ .MelonStem = .{ .age = std.math.cast(u3, self.metadata) catch std.debug.panic("Melon stem too old!", .{}) } },
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
    PoweredRail: struct { shape: StraightRailShape, powered: bool },
    DetectorRail: struct { shape: StraightRailShape, powered: bool },
    StickyPiston: struct { facing: Facing, extended: bool },
    Web: struct {},
    TallGrass: struct { variant: TallGrassType },
    DeadBush: struct {},
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
    UnpoweredRepeater: struct { locked: bool, delay: u2 },
    PoweredRepeater: struct { locked: bool, delay: u2 },
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
    FenceGate: struct { facing: HorizontalAxis, open: bool, powered: bool, in_wall: bool },
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
    LightWeightedPressurePlate: struct { power: u4, powered: u4 },
    HeavyWeightedPressurePlate: struct { power: u4, powered: u4 },
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
    DoublePlant: struct { variant: DoublePlantType, half: DoublePlantHalf, facing: HorizontalAxis },
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
pub const WoodType2 = enum(u3) { Acacia = 4, DarkOak = 5 };

pub const StoneSlabType = enum(u3) { Stone = 0, Sand = 1, Wood = 2, Cobblestone = 3, Brick = 4, Smoothbrick = 5, Netherbrick = 6, Quartz = 7 };

pub const SandType = enum(u1) { Sand = 0, RedSand = 1 };

pub const LogAxis = enum(u2) { X = 1, Y = 0, Z = 2, None = 3 };

pub const Axis = enum { X, Y, Z };
pub const HorizontalAxis = enum { X, Y, Z };
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

pub const FlowerPotContents = enum { Empty, Poppy, BlueOrchid, Allium, Houstonia, RedTulip, OrangeTulip, WhiteTulip, PinkTulip, OxeyeDaisy, Dandelion, OakSapling, SpruceSapling, BirchSapling, JungleSapling, AcaciaSapling, DarkOakSapling, MushroomRed, MushroomBrown, DeadBush, Fern, Cactus };

pub const ComparatorMode = enum { Compare, Subtract };

pub const PrismarineType = enum { Rough, Bricks, Dark };

pub const DoublePlantType = enum { Sunflower, Syringa, Grass, Fern, Rose, Paeonia };
pub const DoublePlantHalf = enum { Upper, Lower };

pub const SandstoneType = enum { Default, Chiseled, Smooth };
pub const RedSandstoneType = enum { Default, Chiseled, Smooth };

pub const BedHalf = enum(u1) { Foot = 0, Head = 1 };

pub const TallGrassType = enum(u2) { DeadBush = 0, Grass = 1, Fern = 2 };

test ConcreteBlockState {
    const expectEqual = std.testing.expectEqual;
    const toConcreteBlockState = StoredBlockState.toConcreteBlockState;

    try expectEqual(toConcreteBlockState(.{ .block = .Air, .metadata = 0 }), .Air);
    try expectEqual(toConcreteBlockState(.{ .block = .Air, .metadata = 2 }), .Air);

    try expectEqual(toConcreteBlockState(StoredBlockState{ .block = .Stone, .metadata = 0 }), ConcreteBlockState{ .Stone = .{ .variant = StoneType.Stone } });
    try expectEqual(toConcreteBlockState(StoredBlockState{ .block = .Stone, .metadata = 0 }), ConcreteBlockState{ .Stone = .{ .variant = StoneType.Stone } });

    std.debug.print("{}\n", .{@sizeOf(ConcreteBlockState)});
}
