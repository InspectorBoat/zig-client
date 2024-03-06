const std = @import("std");

pub const Blocks = union(enum) {
    Air: struct {},
    Stone: struct { variant: enum { Stone, Granite, SmoothGranite, Diorite, SmoothDiorite, Andesite, SmoothAndesite } },
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
    Leaves: struct { variant: WoodType1, decayable: bool, check_bool: bool },
    Sponge: struct { wet: bool },
    Glass: struct {},
    LapisOre: struct {},
    LapisBlock: struct {},
    Dispenser: struct { facing: Facing, triggered: bool },
    Sandstone: struct { variant: enum { Default, Chiseled, Smooth } },
    Noteblock: struct {},
    Bed: struct { facing: HorizontalFacing, part: enum { Head, Foot }, occupied: bool },
    PoweredRail: struct { shape: StraightRailShape, powered: bool },
    DetectorRail: struct { shape: StraightRailShape, powered: bool },
    StickyPiston: struct { facing: Facing, extended: bool },
    Web: struct {},
    TallGrass: struct { type: enum { DeadBush, Grass, Fern } },
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
    StoneSlab: struct { variant: StoneSlabType, seamless: bool, half: SlabHalf },
    BrickBlock: struct {},
    Tnt: struct { explode_on_break: bool },
    Bookshelf: struct {},
    MossyCobblestone: struct {},
    Obsidian: struct {},
    Torch: struct { facing: TorchFacing },
    Fire: struct { age: u4, flip: bool, alt: bool, north: bool, east: bool, south: bool, west: bool, upper: u2 },
    MobSpawner: struct {},
    OakStairs: struct { facing: HorizontalFacing, half: StairHalf, shape: StairShape },
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
    StoneStairs: struct { facing: HorizontalFacing, half: StairHalf, shape: StairShape },
    WallSign: struct { facing: HorizontalFacing },
    Lever: struct { facing: enum { DownX, East, West, South, North, UpX, UpZ, DownZ }, powered: bool },
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
    UnpoweredRepeater: struct { locked: bool, delay: u3 },
    PoweredRepeater: struct { locked: bool, delay: u3 },
    StainedGlass: struct { color: Color },
    Trapdoor: struct { facing: HorizontalFacing, open: bool, half: TrapdoorHalf },
    MonsterEgg: struct { enum { Stone, Cobblestone, Stonebrick, MossyStonebrick, CrackedStonebrick, ChiseledStonebrick } },
    Stonebrick: struct { enum { Default, Mossy, Cracked, Chiseled } },
    BrownMushroomBlock: struct { sides: MushroomSides },
    RedMushroomBlock: struct { sides: MushroomSides },
    IronBars: struct { north: bool, east: bool, south: bool, west: bool },
    GlassPane: struct { north: bool, east: bool, south: bool, west: bool },
    MelonBlock: struct {},
    PumpkinStem: struct { age: u4, facing: StemFacing },
    MelonStem: struct { age: u4, facing: StemFacing },
    Vine: struct { up: bool, north: bool, east: bool, south: bool, west: bool },
    FenceGate: struct { facing: HorizontalAxis, open: bool, powered: bool, in_wall: bool },
    BrickStairs: struct { facing: HorizontalFacing, half: StairHalf, shape: StairShape },
    StoneBrickStairs: struct { facing: HorizontalFacing, half: StairHalf, shape: StairShape },
    Mycelium: struct {},
    Waterlily: struct {},
    NetherBrick: struct {},
    NetherBrickFence: struct { north: bool, east: bool, south: bool, west: bool },
    NetherBrickStairs: struct { facing: HorizontalFacing, half: StairHalf, shape: StairShape },
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
    SandstoneStairs: struct { facing: HorizontalFacing, half: StairHalf, shape: StairShape },
    EmeraldOre: struct {},
    EnderChest: struct { facing: HorizontalFacing },
    TripwireHook: struct { facing: HorizontalFacing, powered: bool, attached: bool, suspended: bool },
    Tripwire: struct { powered: bool, suspended: bool, attached: bool, disarmed: bool, north: bool, east: bool, south: bool, west: bool },
    EmeraldBlock: struct {},
    SpruceStairs: struct { facing: HorizontalFacing, half: StairHalf, shape: StairShape },
    BirchStairs: struct { facing: HorizontalFacing, half: StairHalf, shape: StairShape },
    JungleStairs: struct { facing: HorizontalFacing, half: StairHalf, shape: StairShape },
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
    QuartzStairs: struct { facing: HorizontalFacing, half: StairHalf, shape: StairShape },
    ActivatorRail: struct { shape: StraightRailShape, powered: bool },
    Dropper: struct { facing: Facing, triggered: bool },
    StainedHardenedClay: struct { color: Color },
    StainedGlassPane: struct { north: bool, east: bool, south: bool, west: bool, color: Color },
    Leaves2: struct { variant: WoodType2, decayable: bool, check_decay: bool },
    Log2: struct { axis: LogAxis, variant: WoodType2 },
    AcaciaStairs: struct { facing: HorizontalFacing, half: StairHalf, shape: StairShape },
    DarkOakStairs: struct { facing: HorizontalFacing, half: StairHalf, shape: StairShape },
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
    RedSandstoneStairs: struct { facing: HorizontalFacing, half: StairHalf, shape: StairShape },
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

    pub const WoodType = enum { Oak, Spruce, Birch, Jungle, Acacia, DarkOak };
    pub const WoodType1 = enum { Oak, Spruce, Birch, Jungle };
    pub const WoodType2 = enum { Acacia, DarkOak };

    pub const StoneSlabType = enum { Stone, Sand, Wood, Cobblestone, Brick, Smoothbrick, Netherbrick, Quartz };

    pub const SandType = enum { Sand, RedSand };

    pub const LogAxis = enum { X, Y, Z, None };

    pub const Axis = enum { X, Y, Z };
    pub const HorizontalAxis = enum { X, Y, Z };
    pub const Facing = enum { Up, Down, East, West, North, South };
    pub const HorizontalFacing = enum { East, West, North, South };
    pub const TorchFacing = enum { Up, East, West, North, South };
    pub const StemFacing = enum { Up, East, West, North, South };
    pub const HopperFacing = enum { Down, East, West, North, South };

    pub const RailShape = enum { NorthSouth, EastWest, AscendingEast, AscendingWest, AscendingNorth, AscendingSouth, SouthEast, SouthWest, NorthWest, NorthEast };
    pub const StraightRailShape = enum { NorthSouth, EastWest, AscendingEast, AscendingWest, AscendingNorth, AscendingSouth };

    pub const Color = enum { White, Orange, Magenta, LightBlue, Yellow, Lime, Pink, Gray, Silver, Cyan, Purple, Blue, Brown, Green, Red, Black };

    pub const PistonType = enum { Default, Sticky };

    pub const SlabHalf = enum { Top, Bottom, Both };

    pub const StairHalf = enum { Top, Bottom };
    pub const StairShape = enum { Straight, InnerLeft, InnerRight, OuterLeft, OuterRigth };

    pub const WireConnectionSide = enum { Up, Side, None };

    pub const MushroomSides = enum { NorthWest, North, NorthEast, West, Center, East, SouthWest, South, SouthEast, Stem, AllInside, AllOutside, AllStem };

    pub const DoorHinge = enum { Left, Right };
    pub const DoorHalf = enum { Upper, Lower };
    pub const TrapdoorHalf = enum { Upper, Lower };

    pub const CobblestoneWallVariant = enum { Normal, Mossy };

    pub const FlowerPotContents = enum { Empty, Poppy, BlueOrchid, Allium, Houstonia, RedTulip, OrangeTulip, WhiteTulip, PinkTulip, OxeyeDaisy, Dandelion, OakSapling, SpruceSapling, BirchSapling, JungleSapling, AcaciaSapling, DarkOakSapling, MushroomRed, MushroomBrown, DeadBush, Fern, Cactus };

    pub const ComparatorMode = enum { Compare, Subtract };

    pub const PrismarineType = enum { Rough, Bricks, Dark };

    pub const DoublePlantType = enum { Sunflower, Syringa, Grass, Fern, Rose, Paeonia };
    pub const DoublePlantHalf = enum { Upper, Lower };

    pub const RedSandstoneType = enum { Default, Chiseled, Smooth };
};
