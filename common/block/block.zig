const std = @import("std");

/// After getting a blockstate, need to know:
///
///     Model - based on blockstate
///     Hardness - based on block
///     Placement rules - based on block and pos
///     Use interaction - based on block
///     Step interaction - based on block
///     Hitbox - based on blockstate
///
/// Rationale for packing block states tightly:
/// Optimizing for rendering performance is most important - block model lookups, etc.
/// Other property lookups can be slower
pub const DeduplicatedBlocks = union(enum) {
    Air,
    Stone,
    Granite,
    SmoothGranite,
    Diorite,
    SmoothDiorite,
    Andesite,
    SmoothAndesite,
    Grass,
    Dirt,
    CoarseDirt,
    Podzol,
    CobbleStone,
    OakPlank,
    SprucePlank,
    BirchPlank,
    JunglePlank,
    AcaciaPlank,
    DarkOakPlank,
    OakSapling,
    SpruceSapling,
    BirchSapling,
    JungleSapling,
    AcaciaSapling,
    DarkOakSapling,
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
    OakLog,
    SpruceLog,
    BirchLog,
    JungleLog,
    AcaciaLog,
    DarkOakLog,
    OakLeaves,
    SpruceLeaves,
    BirchLeaves,
    JungleLeaves,
    AcaciaLeaves,
    DarkOakLeaves,
    Sponge,
    Glass,
    LapisOre,
    LapisBlock,
    Dispenser,
    SandStone,
    ChiseledSandStone,
    SmoothSandStone,
    NoteBlock,
    Bed,
    PoweredRail,
    DetectorRail,
    StickyPiston,
    Web,
    WeirdDeadBush,
    TallGrass,
    Fern,
    DeadBush,
    Piston,
    WhiteWool,
    OrangeWool,
    MagentaWool,
    LightBlueWool,
    YellowWool,
    LimeWool,
    PinkWool,
    GrayWool,
    SilverWool,
    CyanWool,
    PurpleWool,
    BlueWool,
    BrownWool,
    GreenWool,
    RedWool,
    BlackWool,
    PistonHead,
    YellowFlower,
    RedFlower,
    BrownMushroom,
    RedMushroom,
    GoldBlock,
    IronBlock,
    // left out slab weirdness
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
    RedstoneDust,
    DiamondOre,
    DiamondBlock,
    CraftingTable,
    Wheat,
    Farmland,
    Furnace,
    StandingSign,
    OakDoor,
    SpruceDoor,
    BirchDoor,
    JungleDoor,
    AcaciaDoor,
    DarkOakDoor,
    Ladder,
    Rail,
    CobblestoneStairs,
    WallSign,
    Lever,
    StonePressurePlate,
    IronDoor,
    WoodenPressurePlate,
    RedstoneOre,
    RedstoneTorch,
    StoneButton,
    SnowLayer,
    Ice,
    Snow,
    Cactus,
    Clay,
    Sugarcane,
    Jukebox,
    OakFence,
    SpruceFence,
    BirchFence,
    JungleFence,
    AcaciaFence,
    DarkOakFence,
    Pumpkin,
    Netherrack,
    SoulSand,
    Glowstone,
    NetherPortal,
    JackOLantern,
    Cake,
    Repeater,
    WhiteStainedGlass,
    OrangeStainedGlass,
    MagentaStainedGlass,
    LightBlueStainedGlass,
    YellowStainedGlass,
    LimeStainedGlass,
    PinkStainedGlass,
    GrayStainedGlass,
    SilverStainedGlass,
    CyanStainedGlass,
    PurpleStainedGlass,
    BlueStainedGlass,
    BrownStainedGlass,
    GreenStainedGlass,
    RedStainedGlass,
    BlackStainedGlass,
    WoodTrapdoor,
    InfestedStone,
    InfestedCobblestone,
    InfestedStoneBrick,
    InfestedMossyStoneBrick,
    InfestedCrackedStoneBrick,
    InfestedChiseledStoneBrick,
    StoneBrick,
    MossyStoneBrick,
    CrackedStoneBrick,
    ChiseledStoneBrick,
    BrownMushroomBlock,
    RedMushroomBlock,
    IronBars,
    GlassPane,
    MelonBlock,
    PumpkinStem,
    Vine,
    FenceGate,
    BrickStairs,
    StoneBrickStairs,
    Mycelium,
    LilyPad,
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
    // TODO: Removed slab weirdness
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
    Cobblestall,
    FlowerPot,
    Carrots,
    Potatoes,
    WoodenButton,
    Skull,
    Anvil,
    TrappedChest,
    IronPressurePlate,
    GoldPressurePlate,
    Comparator,
    DaylightDetector,
    RedstoneBlock,
    QuartzOre,
    Hopper,
    QuartzBlock,
    ChiseledQuartzBlock,
    ColumnQuartzBlock,
    QuartzStairs,
    ActivatorRail,
    Dropper,
    WhiteStainedClay,
    OrangeStainedClay,
    MagentaStainedClay,
    LightBlueStainedClay,
    YellowStainedClay,
    LimeStainedClay,
    PinkStainedClay,
    GrayStainedClay,
    SilverStainedClay,
    CyanStainedClay,
    PurpleStainedClay,
    BlueStainedClay,
    BrownStainedClay,
    GreenStainedClay,
    RedStainedClay,
    BlackStainedClay,
    WhiteStainedGlassPane,
    OrangeStainedGlassPane,
    MagentaStainedGlassPane,
    LightBlueStainedGlassPane,
    YellowStainedGlassPane,
    LimeStainedGlassPane,
    PinkStainedGlassPane,
    GrayStainedGlassPane,
    SilverStainedGlassPane,
    CyanStainedGlassPane,
    PurpleStainedGlassPane,
    BlueStainedGlassPane,
    BrownStainedGlassPane,
    GreenStainedGlassPane,
    RedStainedGlassPane,
    BlackStainedGlassPane,
};

const Hitbox = struct {};

pub const BlockInfo = struct {
    hitboxes: []Hitbox = &.{},
    breakable: bool = true,
    replaceable: bool = false,
    has_item_use_collision: bool = true,
    strength: f32 = 0.0,
};

pub fn register(comptime id: u8, comptime name: []const u8, comptime info: BlockInfo) !void {
    _ = info; // autofix
    _ = name; // autofix
    _ = id; // autofix
}

comptime {
    //     register(0, "air", .{ .replaceable = true, .has_item_use_collision = true });
    //     register(1, "stone", .{ .strength = 1.5 });
    //     register(2, "grass", GrassBlock().setStrength(0.6F));
    //     register(3, "dirt", DirtBlock().setStrength(0.5F));
    //     const cobblestone = Block().setStrength(2.0F);
    //     register(4, "cobblestone", cobblestone);
    //     const planks = PlanksBlock().setStrength(2.0F);
    //     register(5, "planks", planks);
    //     register(6, "sapling", SaplingBlock().setStrength(0.0F));
    //     register(7, "bedrock", Block().setUnbreakable());
    //     register(8, "flowing_water", FlowingLiquidBlock().setStrength(100.0F));
    //     register(9, "water", LiquidSourceBlock().setStrength(100.0F));
    //     register(10, "flowing_lava", FlowingLiquidBlock().setStrength(100.0F));
    //     register(11, "lava", LiquidSourceBlock().setStrength(100.0F));
    //     register(12, "sand", SandBlock().setStrength(0.5F));
    //     register(13, "gravel", GravelBlock().setStrength(0.6F));
    //     register(14, "gold_ore", OreBlock().setStrength(3.0F));
    //     register(15, "iron_ore", OreBlock().setStrength(3.0F));
    //     register(16, "coal_ore", OreBlock().setStrength(3.0F));
    //     register(17, "log", LogBlock());
    //     register(18, "leaves", LeavesBlock());
    //     register(19, "sponge", SpongeBlock().setStrength(0.6F));
    //     register(20, "glass", GlassBlock(false).setStrength(0.3F));
    //     register(21, "lapis_ore", OreBlock().setStrength(3.0F));
    //     register(22, "lapis_block", Block().setStrength(3.0F));
    //     register(23, "dispenser", DispenserBlock().setStrength(3.5F));
    //     const sandstone = SandstoneBlock().setStrength(0.8F);
    //     register(24, "sandstone", sandstone);
    //     register(25, "noteblock", NoteBlock().setStrength(0.8F));
    //     register(26, "bed", BedBlock().setStrength(0.2F));
    //     register(27, "golden_rail", PoweredRailBlock().setStrength(0.7F));
    //     register(28, "detector_rail", DetectorRailBlock().setStrength(0.7F));
    //     register(29, "sticky_piston", PistonBaseBlock(true));
    //     register(30, "web", CobwebBlock().setStrength(4.0F));
    //     register(31, "tallgrass", TallPlantBlock().setStrength(0.0F));
    //     register(32, "deadbush", DeadBushBlock().setStrength(0.0F));
    //     register(33, "piston", PistonBaseBlock(false));
    //     register(34, "piston_head", PistonHeadBlock());
    //     register(35, "wool", ColoredBlock().setStrength(0.8F));
    //     register(36, "piston_extension", MovingBlock());
    //     register(37, "yellow_flower", YellowFlowerBlock().setStrength(0.0F));
    //     register(38, "red_flower", RedFlowerBlock().setStrength(0.0F));
    //     const brownMushroom = MushroomPlantBlock().setStrength(0.0F);
    //     register(39, "brown_mushroom", brownMushroom);
    //     const redMushroom = MushroomPlantBlock().setStrength(0.0F);
    //     register(40, "red_mushroom", redMushroom);
    //     register(41, "gold_block", Block().setStrength(3.0F));
    //     register(42, "iron_block", Block().setStrength(5.0F));
    //     register(43, "double_stone_slab", DoubleStoneSlabBlock().setStrength(2.0F));
    //     register(44, "stone_slab", SingleStoneSlabBlock().setStrength(2.0F));
    //     const brickBlock = Block().setStrength(2.0F);
    //     register(45, "brick_block", brickBlock);
    //     register(46, "tnt", TntBlock().setStrength(0.0F));
    //     register(47, "bookshelf", BookshelfBlock().setStrength(1.5F));
    //     register(48, "mossy_cobblestone", Block().setStrength(2.0F));
    //     register(49, "obsidian", ObsidianBlock().setStrength(50.0F));
    //     register(50, "torch", TorchBlock().setStrength(0.0F));
    //     register(51, "fire", FireBlock().setStrength(0.0F));
    //     register(52, "mob_spawner", MobSpawnerBlock().setStrength(5.0F));
    //     register(53, "oak_stairs", StairsBlock(planks.defaultState().set(PlanksBlock.VARIANT, PlanksBlock.Variant.OAK)));
    //     register(54, "chest", ChestBlock(0).setStrength(2.5F));
    //     register(55, "redstone_wire", RedstireBlock().setStrength(0.0F));
    //     register(56, "diamond_ore", OreBlock().setStrength(3.0F));
    //     register(57, "diamond_block", Block().setStrength(5.0F));
    //     register(58, "crafting_table", CraftingTableBlock().setStrength(2.5F));
    //     register(59, "wheat", WheatBlock());
    //     const farmland = FarmlandBlock().setStrength(0.6F);
    //     register(60, "farmland", farmland);
    //     register(61, "furnace", FurnaceBlock(false).setStrength(3.5F));
    //     register(62, "lit_furnace", FurnaceBlock(true).setStrength(3.5F));
    //     register(63, "standing_sign", StandingSignBlock().setStrength(1.0F));
    //     register(64, "wooden_door", DoorBlock().setStrength(3.0F));
    //     register(65, "ladder", LadderBlock().setStrength(0.4F));
    //     register(66, "rail", RailBlock().setStrength(0.7F));
    //     register(67, "stone_stairs", StairsBlock(cobblestone.defaultState()));
    //     register(68, "wall_sign", WallSignBlock().setStrength(1.0F));
    //     register(69, "lever", LeverBlock().setStrength(0.5F));
    //     register(70, "stone_pressure_plate", PressurePlateBlock().setStrength(0.5F));
    //     register(71, "iron_door", DoorBlock().setStrength(5.0F));
    //     register(72, "wooden_pressure_plate", PressurePlateBlock().setStrength(0.5F));
    //     register(73, "redstone_ore", RedstoneOreBlock(false).setStrength(3.0F));
    //     register(74, "lit_redstone_ore", RedstoneOreBlock(true).setStrength(3.0F));
    //     register(75, "unlit_redstone_torch", RedstoneTorchBlock(false).setStrength(0.0F));
    //     register(76, "redstone_torch", RedstoneTorchBlock(true).setStrength(0.0F));
    //     register(77, "stone_button", StoneButtonBlock().setStrength(0.5F));
    //     register(78, "snow_layer", SnowLayerBlock().setStrength(0.1F));
    //     register(79, "ice", IceBlock().setStrength(0.5F));
    //     register(80, "snow", SnowBlock().setStrength(0.2F));
    //     register(81, "cactus", CactusBlock().setStrength(0.4F));
    //     register(82, "clay", ClayBlock().setStrength(0.6F));
    //     register(83, "reeds", SugarCaneBlock().setStrength(0.0F));
    //     register(84, "jukebox", JukeboxBlock().setStrength(2.0F));
    //     register(85, "fence", FenceBlock(PlanksBlock.Variant.OAK.getColor()).setStrength(2.0F));
    //     const pumpkin = PumpkinBlock().setStrength(1.0F);
    //     register(86, "pumpkin", pumpkin);
    //     register(87, "netherrack", NetherrackBlock().setStrength(0.4F));
    //     register(88, "soul_sand", SoulSandBlock().setStrength(0.5F));
    //     register(89, "glowstone", GlowstoneBlock().setStrength(0.3F));
    //     register(90, "portal", PortalBlock().setStrength(-1.0F));
    //     register(91, "lit_pumpkin", PumpkinBlock().setStrength(1.0F));
    //     register(92, "cake", CakeBlock().setStrength(0.5F));
    //     register(93, "unpowered_repeater", RepeaterBlock(false).setStrength(0.0F));
    //     register(94, "powered_repeater", RepeaterBlock(true).setStrength(0.0F));
    //     register(95, "stained_glass", StainedGlassBlock().setStrength(0.3F));
    //     register(96, "trapdoor", TrapdoorBlock().setStrength(3.0F));
    //     register(97, "monster_egg", InfestedBlock().setStrength(0.75F));
    //     const stoneBrick = StonebrickBlock().setStrength(1.5F);
    //     register(98, "stonebrick", stoneBrick);
    //     register(99, "brown_mushroom_block", MushroomBlock(brownMushroom).setStrength(0.2F));
    //     register(100, "red_mushroom_block", MushroomBlock(redMushroom).setStrength(0.2F));
    //     register(101, "iron_bars", PaneBlock(true).setStrength(5.0F));
    //     register(102, "glass_pane", PaneBlock(false).setStrength(0.3F));
    //     const melon = MelonBlock().setStrength(1.0F);
    //     register(103, "melon_block", melon);
    //     register(104, "pumpkin_stem", StemBlock(pumpkin).setStrength(0.0F));
    //     register(105, "melon_stem", StemBlock(melon).setStrength(0.0F));
    //     register(106, "vine", VineBlock().setStrength(0.2F));
    //     register(107, "fence_gate", FenceGateBlock(PlanksBlock.Variant.OAK).setStrength(2.0F));
    //     register(108, "brick_stairs", StairsBlock(brickBlock.defaultState()));
    //     register(109, "stone_brick_stairs", StairsBlock(stoneBrick.defaultState().set(StonebrickBlock.VARIANT, StonebrickBlock.Variant.DEFAULT)));
    //     register(110, "mycelium", MyceliumBlock().setStrength(0.6F));
    //     register(111, "waterlily", LilyPadBlock().setStrength(0.0F));
    //     const netherBrick = NetherBrickBlock().setStrength(2.0F);
    //     register(112, "nether_brick", netherBrick);
    //     register(113, "nether_brick_fence", FenceBlock().setStrength(2.0F));
    //     register(114, "nether_brick_stairs", StairsBlock(netherBrick.defaultState()));
    //     register(115, "nether_wart", NetherWartBlock());
    //     register(116, "enchanting_table", EnchantingTableBlock().setStrength(5.0F));
    //     register(117, "brewing_stand", BrewingStandBlock().setStrength(0.5F));
    //     register(118, "cauldron", CauldronBlock().setStrength(2.0F));
    //     register(119, "end_portal", EndPortalBlock().setStrength(-1.0F));
    //     register(120, "end_portal_frame", EndPortalFrameBlock().setStrength(-1.0F));
    //     register(121, "end_stone", Block().setStrength(3.0F));
    //     register(122, "dragon_egg", DragonEggBlock().setStrength(3.0F));
    //     register(123, "redstone_lamp", RedstoneLampBlock(false).setStrength(0.3F));
    //     register(124, "lit_redstone_lamp", RedstoneLampBlock(true).setStrength(0.3F));
    //     register(125, "double_wooden_slab", DoubleWoodenSlabBlock().setStrength(2.0F));
    //     register(126, "wooden_slab", SingleWoodenSlabBlock().setStrength(2.0F));
    //     register(127, "cocoa", CocoaBlock().setStrength(0.2F));
    //     register(128, "sandstone_stairs", StairsBlock(sandstone.defaultState().set(SandstoneBlock.TYPE, SandstoneBlock.Type.SMOOTH)));
    //     register(129, "emerald_ore", OreBlock().setStrength(3.0F));
    //     register(130, "ender_chest", EnderChestBlock().setStrength(22.5F));
    //     register(131, "tripwire_hook", TripwireHookBlock());
    //     register(132, "tripwire", TripwireBlock());
    //     register(133, "emerald_block", Block().setStrength(5.0F));
    //     register(134, "spruce_stairs", StairsBlock(planks.defaultState().set(PlanksBlock.VARIANT, PlanksBlock.Variant.SPRUCE)));
    //     register(135, "birch_stairs", StairsBlock(planks.defaultState().set(PlanksBlock.VARIANT, PlanksBlock.Variant.BIRCH)));
    //     register(136, "jungle_stairs", StairsBlock(planks.defaultState().set(PlanksBlock.VARIANT, PlanksBlock.Variant.JUNGLE)));
    //     register(137, "command_block", CommandBlock().setUnbreakable());
    //     register(138, "beacon", BeaconBlock());
    //     register(139, "cobblestone_wall", WallBlock(cobblestone));
    //     register(140, "flower_pot", FlowerPotBlock().setStrength(0.0F));
    //     register(141, "carrots", CarrotsBlock());
    //     register(142, "potatoes", PotatoesBlock());
    //     register(143, "wooden_button", WoodenButtonBlock().setStrength(0.5F));
    //     register(144, "skull", SkullBlock().setStrength(1.0F));
    //     register(145, "anvil", AnvilBlock().setStrength(5.0F));
    //     register(146, "trapped_chest", ChestBlock(1).setStrength(2.5F));
    //     register(147, "light_weighted_pressure_plate", WeightedPressurePlateBlock(15).setStrength(0.5F));
    //     register(148, "heavy_weighted_pressure_plate", WeightedPressurePlateBlock(150).setStrength(0.5F));
    //     register(149, "unpowered_comparator", ComparatorBlock(false).setStrength(0.0F));
    //     register(150, "powered_comparator", ComparatorBlock(true).setStrength(0.0F));
    //     register(151, "daylight_detector", DaylightDetectorBlock(false));
    //     register(152, "redstone_block", RedstoneBlock().setStrength(5.0F));
    //     register(153, "quartz_ore", OreBlock().setStrength(3.0F));
    //     register(154, "hopper", HopperBlock().setStrength(3.0F));
    //     const quartzBlock = QuartzBlock().setStrength(0.8F);
    //     register(155, "quartz_block", quartzBlock);
    //     register(156, "quartz_stairs", StairsBlock(quartzBlock.defaultState().set(QuartzBlock.VARIANT, QuartzBlock.Variant.DEFAULT)));
    //     register(157, "activator_rail", PoweredRailBlock().setStrength(0.7F));
    //     register(158, "dropper", DropperBlock().setStrength(3.5F));
    //     register(159, "stained_hardened_clay", ColoredBlock().setStrength(1.25F));
    //     register(160, "stained_glass_pane", StainedGlassPaneBlock().setStrength(0.3F));
    //     register(161, "leaves2", Leaves2Block());
    //     register(162, "log2", Log2Block());
    //     register(163, "acacia_stairs", StairsBlock(planks.defaultState().set(PlanksBlock.VARIANT, PlanksBlock.Variant.ACACIA)));
    //     register(164, "dark_oak_stairs", StairsBlock(planks.defaultState().set(PlanksBlock.VARIANT, PlanksBlock.Variant.DARK_OAK)));
    //     register(165, "slime", SlimeBlock());
    //     register(166, "barrier", BarrierBlock());
    //     register(167, "iron_trapdoor", TrapdoorBlock().setStrength(5.0F));
    //     register(168, "prismarine", PrismarineBlock().setStrength(1.5F));
    //     register(169, "sea_lantern", SeaLanternBlock().setStrength(0.3F));
    //     register(170, "hay_block", HayBlock().setStrength(0.5F));
    //     register(171, "carpet", CarpetBlock().setStrength(0.1F));
    //     register(172, "hardened_clay", HardenedClayBlock().setStrength(1.25F));
    //     register(173, "coal_block", Block().setStrength(5.0F));
    //     register(174, "packed_ice", PackedIceBlock().setStrength(0.5F));
    //     register(175, "double_plant", DoublePlantBlock());
    //     register(176, "standing_banner", BannerBlock.Standing().setStrength(1.0F));
    //     register(177, "wall_banner", BannerBlock.Wall().setStrength(1.0F));
    //     register(178, "daylight_detector_inverted", DaylightDetectorBlock(true));
    //     const redSandstone = RedSandstoneBlock().setStrength(0.8F);
    //     register(179, "red_sandstone", redSandstone);
    //     register(180, "red_sandstone_stairs", StairsBlock(redSandstone.defaultState().set(RedSandstoneBlock.TYPE, RedSandstoneBlock.Type.SMOOTH)));
    //     register(181, "double_stone_slab2", DoubleRedSandstoneSlabBlock().setStrength(2.0F));
    //     register(182, "stone_slab2", SingleRedSandstoneSlabBlock().setStrength(2.0F));
    //     register(183, "spruce_fence_gate", FenceGateBlock(PlanksBlock.Variant.SPRUCE).setStrength(2.0F));
    //     register(184, "birch_fence_gate", FenceGateBlock(PlanksBlock.Variant.BIRCH).setStrength(2.0F));
    //     register(185, "jungle_fence_gate", FenceGateBlock(PlanksBlock.Variant.JUNGLE).setStrength(2.0F));
    //     register(186, "dark_oak_fence_gate", FenceGateBlock(PlanksBlock.Variant.DARK_OAK).setStrength(2.0F));
    //     register(187, "acacia_fence_gate", FenceGateBlock(PlanksBlock.Variant.ACACIA).setStrength(2.0F));
    //     register(188, "spruce_fence", FenceBlock(PlanksBlock.Variant.SPRUCE.getColor()).setStrength(2.0F));
    //     register(189, "birch_fence", FenceBlock(PlanksBlock.Variant.BIRCH.getColor()).setStrength(2.0F));
    //     register(190, "jungle_fence", FenceBlock(PlanksBlock.Variant.JUNGLE.getColor()).setStrength(2.0F));
    //     register(191, "dark_oak_fence", FenceBlock(PlanksBlock.Variant.DARK_OAK.getColor()).setStrength(2.0F));
    //     register(192, "acacia_fence", FenceBlock(PlanksBlock.Variant.ACACIA.getColor()).setStrength(2.0F));
    //     register(193, "spruce_door", DoorBlock().setStrength(3.0F));
    //     register(194, "birch_door", DoorBlock().setStrength(3.0F));
    //     register(195, "jungle_door", DoorBlock().setStrength(3.0F));
    //     register(196, "acacia_door", DoorBlock().setStrength(3.0F));
    //     register(197, "dark_oak_door", DoorBlock().setStrength(3.0F));
}

test "BlockState" {}
