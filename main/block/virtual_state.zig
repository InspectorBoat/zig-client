pub const VirtualState = packed struct(u20) {
    block: Block,
    properties: Properties,

    pub const Properties = packed union(u12) {
        air: packed struct(u12) { _: u12 = 0 },
        stone: packed struct(u12) { variant: PhysicalState.StoneVariant, _: u9 = 0 },
        grass: packed struct(u12) { snowy: bool, _: u11 = 0 },
        dirt: packed struct(u12) { variant: PhysicalState.DirtVariant, snowy: bool, _: u9 = 0 },
        cobblestone: packed struct(u12) { _: u12 = 0 },
        planks: packed struct(u12) { variant: PhysicalState.WoodVariant, _: u9 = 0 },
        sapling: packed struct(u12) { variant: PhysicalState.WoodVariant, stage: u1, _: u8 = 0 },
        bedrock: packed struct(u12) { _: u12 = 0 },
        flowing_water: packed struct(u12) { level: u4, _: u8 = 0 },
        water: packed struct(u12) { level: u4, _: u8 = 0 },
        flowing_lava: packed struct(u12) { level: u4, _: u8 = 0 },
        lava: packed struct(u12) { level: u4, _: u8 = 0 },
        sand: packed struct(u12) { variant: PhysicalState.SandVariant, _: u11 = 0 },
        gravel: packed struct(u12) { _: u12 = 0 },
        gold_ore: packed struct(u12) { _: u12 = 0 },
        iron_ore: packed struct(u12) { _: u12 = 0 },
        coal_ore: packed struct(u12) { _: u12 = 0 },
        log: packed struct(u12) { variant: PhysicalState.WoodVariant1, axis: PhysicalState.LogAxis, _: u8 = 0 },
        leaves: packed struct(u12) { variant: PhysicalState.WoodVariant1, not_decayable: bool, check_decay: bool, _: u8 = 0 },
        sponge: packed struct(u12) { wet: bool, _: u11 = 0 },
        glass: packed struct(u12) { _: u12 = 0 },
        lapis_ore: packed struct(u12) { _: u12 = 0 },
        lapis_block: packed struct(u12) { _: u12 = 0 },
        dispenser: packed struct(u12) { facing: PhysicalState.Facing, triggered: bool, _: u8 = 0 },
        sandstone: packed struct(u12) { variant: PhysicalState.SandstoneVariant, _: u10 = 0 },
        noteblock: packed struct(u12) { _: u12 = 0 },
        bed: packed struct(u12) { facing: PhysicalState.PackedHorizontalFacing, occupied: bool, part: PhysicalState.BedPart, _: u8 = 0 },
        golden_rail: packed struct(u12) { shape: PhysicalState.StraightRailShape, powered: bool, _: u8 = 0 },
        detector_rail: packed struct(u12) { shape: PhysicalState.StraightRailShape, powered: bool, _: u8 = 0 },
        sticky_piston: packed struct(u12) { facing: PhysicalState.Facing, extended: bool, _: u8 = 0 },
        web: packed struct(u12) { _: u12 = 0 },
        tallgrass: packed struct(u12) { variant: PhysicalState.TallGrassVariant, _: u10 = 0 },
        deadbush: packed struct(u12) { _: u12 = 0 },
        piston: packed struct(u12) { facing: PhysicalState.Facing, extended: bool, _: u8 = 0 },
        piston_head: packed struct(u12) { facing: PhysicalState.Facing, type: PhysicalState.PistonType, short: bool, _: u7 = 0 },
        wool: packed struct(u12) { color: PhysicalState.Color, _: u8 = 0 },
        piston_extension: packed struct(u12) { facing: PhysicalState.Facing, sticky: bool, _: u8 = 0 },
        yellow_flower: packed struct(u12) { _: u12 = 0 },
        red_flower: packed struct(u12) { variant: PhysicalState.RedFlowerVariant, _: u8 = 0 },
        brown_mushroom: packed struct(u12) { _: u12 = 0 },
        red_mushroom: packed struct(u12) { _: u12 = 0 },
        gold_block: packed struct(u12) { _: u12 = 0 },
        iron_block: packed struct(u12) { _: u12 = 0 },
        double_stone_slab: packed struct(u12) { variant: PhysicalState.StoneSlabVariant, seamless: bool, _: u8 = 0 },
        stone_slab: packed struct(u12) { variant: PhysicalState.StoneSlabVariant, half: PhysicalState.Half, _: u8 = 0 },
        brick_block: packed struct(u12) { _: u12 = 0 },
        tnt: packed struct(u12) { explode: bool, _: u11 = 0 },
        bookshelf: packed struct(u12) { _: u12 = 0 },
        mossy_cobblestone: packed struct(u12) { _: u12 = 0 },
        obsidian: packed struct(u12) { _: u12 = 0 },
        torch: packed struct(u12) { facing: PhysicalState.TorchFacing, _: u9 = 0 },
        fire: packed struct(u12) { age: u4, flip: bool, alt: bool, north: bool, east: bool, south: bool, west: bool, upper: enum(u2) { @"0", @"1", @"2" }, _: u0 = 0 },
        mob_spawner: packed struct(u12) { _: u12 = 0 },
        oak_stairs: packed struct(u12) { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape, _: u6 = 0 },
        chest: packed struct(u12) { facing: PhysicalState.HorizontalFacing, _: u9 = 0 },
        redstone_wire: packed struct(u12) { power: u4, north: RedstoneWireConnection, east: RedstoneWireConnection, south: RedstoneWireConnection, west: RedstoneWireConnection, _: u0 = 0 },
        diamond_ore: packed struct(u12) { _: u12 = 0 },
        diamond_block: packed struct(u12) { _: u12 = 0 },
        crafting_table: packed struct(u12) { _: u12 = 0 },
        wheat: packed struct(u12) { age: u3, _: u9 = 0 },
        farmland: packed struct(u12) { moisture: u3, _: u9 = 0 },
        furnace: packed struct(u12) { facing: PhysicalState.HorizontalFacing, _: u9 = 0 },
        lit_furnace: packed struct(u12) { facing: PhysicalState.HorizontalFacing, _: u9 = 0 },
        standing_sign: packed struct(u12) { rotation: u4, _: u8 = 0 },
        wooden_door: packed struct(u12) { half: PhysicalState.DoorHalf, hinge: PhysicalState.DoorHinge, powered: bool, open: bool, facing: PhysicalState.DoorFacing, _: u6 = 0 },
        ladder: packed struct(u12) { facing: PhysicalState.HorizontalFacing, _: u9 = 0 },
        rail: packed struct(u12) { shape: PhysicalState.CurveableRailShape, _: u8 = 0 },
        stone_stairs: packed struct(u12) { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape, _: u6 = 0 },
        wall_sign: packed struct(u12) { facing: PhysicalState.HorizontalFacing, _: u9 = 0 },
        lever: packed struct(u12) { facing: PhysicalState.LeverFacing, powered: bool, _: u8 = 0 },
        stone_pressure_plate: packed struct(u12) { powered: bool, _: u11 = 0 },
        iron_door: packed struct(u12) { half: PhysicalState.DoorHalf, hinge: PhysicalState.DoorHinge, powered: bool, open: bool, facing: PhysicalState.DoorFacing, _: u6 = 0 },
        wooden_pressure_plate: packed struct(u12) { powered: bool, _: u11 = 0 },
        redstone_ore: packed struct(u12) { _: u12 = 0 },
        lit_redstone_ore: packed struct(u12) { _: u12 = 0 },
        unlit_redstone_torch: packed struct(u12) { facing: PhysicalState.TorchFacing, _: u9 = 0 },
        redstone_torch: packed struct(u12) { facing: PhysicalState.TorchFacing, _: u9 = 0 },
        stone_button: packed struct(u12) { facing: PhysicalState.ButtonFacing, powered: bool, _: u8 = 0 },
        snow_layer: packed struct(u12) { layers: PhysicalState.SnowLayers, _: u9 = 0 },
        ice: packed struct(u12) { _: u12 = 0 },
        snow: packed struct(u12) { _: u12 = 0 },
        cactus: packed struct(u12) { age: u4, _: u8 = 0 },
        clay: packed struct(u12) { _: u12 = 0 },
        reeds: packed struct(u12) { age: u4, _: u8 = 0 },
        jukebox: packed struct(u12) { has_record: bool, _: u11 = 0 },
        fence: packed struct(u12) { north: bool, east: bool, south: bool, west: bool, _: u8 = 0 },
        pumpkin: packed struct(u12) { facing: PhysicalState.PackedHorizontalFacing, _: u10 = 0 },
        netherrack: packed struct(u12) { _: u12 = 0 },
        soul_sand: packed struct(u12) { _: u12 = 0 },
        glowstone: packed struct(u12) { _: u12 = 0 },
        portal: packed struct(u12) { axis: PhysicalState.PortalAxis, _: u10 = 0 },
        lit_pumpkin: packed struct(u12) { facing: PhysicalState.PackedHorizontalFacing, _: u10 = 0 },
        cake: packed struct(u12) { bites: PhysicalState.CakeBites, _: u9 = 0 },
        unpowered_repeater: packed struct(u12) { facing: PhysicalState.PackedHorizontalFacing, delay: PhysicalState.RepeaterDelay, locked: bool, _: u7 = 0 },
        powered_repeater: packed struct(u12) { facing: PhysicalState.PackedHorizontalFacing, delay: PhysicalState.RepeaterDelay, locked: bool, _: u7 = 0 },
        stained_glass: packed struct(u12) { color: PhysicalState.Color, _: u8 = 0 },
        trapdoor: packed struct(u12) { facing: PhysicalState.TrapdoorFacing, open: bool, half: PhysicalState.Half, _: u8 = 0 },
        monster_egg: packed struct(u12) { variant: PhysicalState.MonsterEggVariant, _: u9 = 0 },
        stonebrick: packed struct(u12) { variant: PhysicalState.StoneBrickVariant, _: u10 = 0 },
        brown_mushroom_block: packed struct(u12) { variant: PhysicalState.MushroomBlockVariant, _: u8 = 0 },
        red_mushroom_block: packed struct(u12) { variant: PhysicalState.MushroomBlockVariant, _: u8 = 0 },
        iron_bars: packed struct(u12) { north: bool, east: bool, south: bool, west: bool, _: u8 = 0 },
        glass_pane: packed struct(u12) { north: bool, east: bool, south: bool, west: bool, _: u8 = 0 },
        melon_block: packed struct(u12) { _: u12 = 0 },
        pumpkin_stem: packed struct(u12) { age: u3, facing: StemFacing, _: u6 = 0 },
        melon_stem: packed struct(u12) { age: u3, facing: StemFacing, _: u6 = 0 },
        vine: packed struct(u12) { south: bool, west: bool, north: bool, east: bool, up: bool, _: u7 = 0 },
        fence_gate: packed struct(u12) { facing: PhysicalState.PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool, _: u7 = 0 },
        brick_stairs: packed struct(u12) { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape, _: u6 = 0 },
        stone_brick_stairs: packed struct(u12) { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape, _: u6 = 0 },
        mycelium: packed struct(u12) { snowy: bool, _: u11 = 0 },
        waterlily: packed struct(u12) { _: u12 = 0 },
        nether_brick: packed struct(u12) { _: u12 = 0 },
        nether_brick_fence: packed struct(u12) { north: bool, east: bool, south: bool, west: bool, _: u8 = 0 },
        nether_brick_stairs: packed struct(u12) { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape, _: u6 = 0 },
        nether_wart: packed struct(u12) { age: u2, _: u10 = 0 },
        enchanting_table: packed struct(u12) { _: u12 = 0 },
        brewing_stand: packed struct(u12) { has_bottle_0: bool, has_bottle_1: bool, has_bottle_2: bool, _: u9 = 0 },
        cauldron: packed struct(u12) { level: u2, _: u10 = 0 },
        end_portal: packed struct(u12) { _: u12 = 0 },
        end_portal_frame: packed struct(u12) { facing: PhysicalState.PackedHorizontalFacing, eye: bool, _: u9 = 0 },
        end_stone: packed struct(u12) { _: u12 = 0 },
        dragon_egg: packed struct(u12) { _: u12 = 0 },
        redstone_lamp: packed struct(u12) { _: u12 = 0 },
        lit_redstone_lamp: packed struct(u12) { _: u12 = 0 },
        double_wooden_slab: packed struct(u12) { variant: PhysicalState.WoodVariant, _: u9 = 0 },
        wooden_slab: packed struct(u12) { variant: PhysicalState.WoodVariant, half: PhysicalState.Half, _: u8 = 0 },
        cocoa: packed struct(u12) { facing: PhysicalState.PackedHorizontalFacing, age: PhysicalState.Age02, _: u8 = 0 },
        sandstone_stairs: packed struct(u12) { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape, _: u6 = 0 },
        emerald_ore: packed struct(u12) { _: u12 = 0 },
        ender_chest: packed struct(u12) { facing: PhysicalState.HorizontalFacing, _: u9 = 0 },
        tripwire_hook: packed struct(u12) { facing: PhysicalState.PackedHorizontalFacing, attached: bool, powered: bool, suspended: bool, _: u7 = 0 },
        tripwire: packed struct(u12) { powered: bool, suspended: bool, attached: bool, disarmed: bool, north: bool, east: bool, south: bool, west: bool, _: u4 = 0 },
        emerald_block: packed struct(u12) { _: u12 = 0 },
        spruce_stairs: packed struct(u12) { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape, _: u6 = 0 },
        birch_stairs: packed struct(u12) { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape, _: u6 = 0 },
        jungle_stairs: packed struct(u12) { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape, _: u6 = 0 },
        command_block: packed struct(u12) { triggered: bool, _: u11 = 0 },
        beacon: packed struct(u12) { _: u12 = 0 },
        cobblestone_wall: packed struct(u12) { variant: PhysicalState.CobblestoneWallVariant, up: bool, north: bool, east: bool, south: bool, west: bool, _: u6 = 0 },
        flower_pot: packed struct(u12) { legacy_data: u4, _: u8 = 0 },
        carrots: packed struct(u12) { age: u3, _: u9 = 0 },
        potatoes: packed struct(u12) { age: u3, _: u9 = 0 },
        wooden_button: packed struct(u12) { facing: PhysicalState.ButtonFacing, powered: bool, _: u8 = 0 },
        skull: packed struct(u12) { facing: PhysicalState.Facing, nodrop: bool, _: u8 = 0 },
        anvil: packed struct(u12) { facing: PhysicalState.PackedHorizontalFacing, damage: PhysicalState.Age02, _: u8 = 0 },
        trapped_chest: packed struct(u12) { facing: PhysicalState.HorizontalFacing, _: u9 = 0 },
        light_weighted_pressure_plate: packed struct(u12) { power: u4, _: u8 = 0 },
        heavy_weighted_pressure_plate: packed struct(u12) { power: u4, _: u8 = 0 },
        unpowered_comparator: packed struct(u12) { facing: PhysicalState.PackedHorizontalFacing, mode: PhysicalState.ComparatorMode, powered: bool, _: u8 = 0 },
        powered_comparator: packed struct(u12) { facing: PhysicalState.PackedHorizontalFacing, mode: PhysicalState.ComparatorMode, powered: bool, _: u8 = 0 },
        daylight_detector: packed struct(u12) { power: u4, _: u8 = 0 },
        redstone_block: packed struct(u12) { _: u12 = 0 },
        quartz_ore: packed struct(u12) { _: u12 = 0 },
        hopper: packed struct(u12) { facing: PhysicalState.HopperFacing, enabled: bool, _: u8 = 0 },
        quartz_block: packed struct(u12) { variant: PhysicalState.QuartzBlockVariant, _: u9 = 0 },
        quartz_stairs: packed struct(u12) { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape, _: u6 = 0 },
        activator_rail: packed struct(u12) { shape: PhysicalState.StraightRailShape, powered: bool, _: u8 = 0 },
        dropper: packed struct(u12) { facing: PhysicalState.Facing, triggered: bool, _: u8 = 0 },
        stained_hardened_clay: packed struct(u12) { color: PhysicalState.Color, _: u8 = 0 },
        stained_glass_pane: packed struct(u12) { color: PhysicalState.Color, north: bool, east: bool, south: bool, west: bool, _: u4 = 0 },
        leaves2: packed struct(u12) { variant: PhysicalState.WoodVariant2, not_decayable: bool, check_decay: bool, _: u9 = 0 },
        log2: packed struct(u12) { variant: PhysicalState.WoodVariant2, axis: PhysicalState.LogAxis, _: u9 = 0 },
        acacia_stairs: packed struct(u12) { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape, _: u6 = 0 },
        dark_oak_stairs: packed struct(u12) { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape, _: u6 = 0 },
        slime: packed struct(u12) { _: u12 = 0 },
        barrier: packed struct(u12) { _: u12 = 0 },
        iron_trapdoor: packed struct(u12) { facing: PhysicalState.TrapdoorFacing, open: bool, half: PhysicalState.Half, _: u8 = 0 },
        prismarine: packed struct(u12) { variant: PhysicalState.PrismarineVariant, _: u10 = 0 },
        sea_lantern: packed struct(u12) { _: u12 = 0 },
        hay_block: packed struct(u12) { axis: PhysicalState.HayBlockAxis, _: u10 = 0 },
        carpet: packed struct(u12) { color: PhysicalState.Color, _: u8 = 0 },
        hardened_clay: packed struct(u12) { _: u12 = 0 },
        coal_block: packed struct(u12) { _: u12 = 0 },
        packed_ice: packed struct(u12) { _: u12 = 0 },
        double_plant: packed struct(u12) { variant: PhysicalState.DoublePlantVariant, half: PhysicalState.DoublePlantHalf, _: u8 = 0 },
        standing_banner: packed struct(u12) { rotation: u4, _: u8 = 0 },
        wall_banner: packed struct(u12) { facing: PhysicalState.HorizontalFacing, _: u9 = 0 },
        daylight_detector_inverted: packed struct(u12) { power: u4, _: u8 = 0 },
        red_sandstone: packed struct(u12) { variant: PhysicalState.RedSandstoneVariant, _: u10 = 0 },
        red_sandstone_stairs: packed struct(u12) { facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: StairShape, _: u6 = 0 },
        double_stone_slab2: packed struct(u12) { seamless: bool, _: u11 = 0 },
        stone_slab2: packed struct(u12) { half: PhysicalState.Half, _: u11 = 0 },
        spruce_fence_gate: packed struct(u12) { facing: PhysicalState.PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool, _: u7 = 0 },
        birch_fence_gate: packed struct(u12) { facing: PhysicalState.PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool, _: u7 = 0 },
        jungle_fence_gate: packed struct(u12) { facing: PhysicalState.PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool, _: u7 = 0 },
        dark_oak_fence_gate: packed struct(u12) { facing: PhysicalState.PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool, _: u7 = 0 },
        acacia_fence_gate: packed struct(u12) { facing: PhysicalState.PackedHorizontalFacing, open: bool, powered: bool, in_wall: bool, _: u7 = 0 },
        spruce_fence: packed struct(u12) { north: bool, east: bool, south: bool, west: bool, _: u8 = 0 },
        birch_fence: packed struct(u12) { north: bool, east: bool, south: bool, west: bool, _: u8 = 0 },
        jungle_fence: packed struct(u12) { north: bool, east: bool, south: bool, west: bool, _: u8 = 0 },
        dark_oak_fence: packed struct(u12) { north: bool, east: bool, south: bool, west: bool, _: u8 = 0 },
        acacia_fence: packed struct(u12) { north: bool, east: bool, south: bool, west: bool, _: u8 = 0 },
        spruce_door: packed struct(u12) { half: PhysicalState.DoorHalf, hinge: PhysicalState.DoorHinge, powered: bool, open: bool, facing: PhysicalState.DoorFacing, _: u6 = 0 },
        birch_door: packed struct(u12) { half: PhysicalState.DoorHalf, hinge: PhysicalState.DoorHinge, powered: bool, open: bool, facing: PhysicalState.DoorFacing, _: u6 = 0 },
        jungle_door: packed struct(u12) { half: PhysicalState.DoorHalf, hinge: PhysicalState.DoorHinge, powered: bool, open: bool, facing: PhysicalState.DoorFacing, _: u6 = 0 },
        acacia_door: packed struct(u12) { half: PhysicalState.DoorHalf, hinge: PhysicalState.DoorHinge, powered: bool, open: bool, facing: PhysicalState.DoorFacing, _: u6 = 0 },
        dark_oak_door: packed struct(u12) { half: PhysicalState.DoorHalf, hinge: PhysicalState.DoorHinge, powered: bool, open: bool, facing: PhysicalState.DoorFacing, _: u6 = 0 },
    };

    pub fn resolve(physical: PhysicalState, world: *const World, block_pos: Vector3(i32)) @This() {
        const properties: Properties = switch (physical.block) {
            .grass => .{ .grass = .{
                .snowy = blk: {
                    const up = world.getBlock(block_pos.up());
                    break :blk up == .snow or up == .snow_layer;
                },
            } },
            .mycelium => .{ .mycelium = .{
                .snowy = blk: {
                    const up = world.getBlock(block_pos.up());
                    break :blk up == .snow or up == .snow_layer;
                },
            } },
            .dirt => .{ .dirt = .{
                .variant = physical.payload(.dirt).variant,
                .snowy = physical.payload(.dirt).variant == .podzol and blk: {
                    const up = world.getBlock(block_pos.up());
                    break :blk up == .snow or up == .snow_layer;
                },
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
            .tripwire => blk: {
                const suspended = physical.payload(.tripwire).suspended;
                break :blk .{ .tripwire = .{
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
            inline .powered_repeater, .unpowered_repeater => |block| @unionInit(Properties, @tagName(block), .{
                .facing = physical.payload(block).facing,
                .delay = physical.payload(block).delay,
                .locked = false,
            }),
            inline .fence_gate, .spruce_fence_gate, .birch_fence_gate, .jungle_fence_gate, .dark_oak_fence_gate, .acacia_fence_gate => |block| @unionInit(Properties, @tagName(block), .{
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
            inline .wooden_door, .iron_door, .spruce_door, .birch_door, .jungle_door, .acacia_door, .dark_oak_door => |block| blk: {
                const maybe_neighbor = world.getBlockState(if (physical.payload(block).half == .lower) block_pos.up() else block_pos.down()).maybePayload(block);
                break :blk @unionInit(
                    Properties,
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
            inline .fence, .nether_brick_fence, .spruce_fence, .birch_fence, .jungle_fence, .dark_oak_fence, .acacia_fence => |block| @unionInit(Properties, @tagName(block), .{
                .north = fenceShouldConnectTo(block, world.getBlock(block_pos.north())),
                .east = fenceShouldConnectTo(block, world.getBlock(block_pos.east())),
                .south = fenceShouldConnectTo(block, world.getBlock(block_pos.south())),
                .west = fenceShouldConnectTo(block, world.getBlock(block_pos.west())),
            }),
            inline .oak_stairs, .stone_stairs, .brick_stairs, .stone_brick_stairs, .nether_brick_stairs, .sandstone_stairs, .spruce_stairs, .birch_stairs, .jungle_stairs, .quartz_stairs, .acacia_stairs, .dark_oak_stairs, .red_sandstone_stairs => |block| @unionInit(Properties, @tagName(block), .{
                .facing = physical.payload(block).facing,
                .half = physical.payload(block).half,
                .shape = resolveStairShape(world, block_pos),
            }),
            .piston_head => .{ .piston_head = .{
                .facing = physical.payload(.piston_head).facing,
                .type = physical.payload(.piston_head).type,
                .short = false,
            } },
            inline else => |block| blk: {
                @setEvalBranchQuota(1000000);

                const VirtualProperty = @FieldType(VirtualState.Properties, @tagName(block));
                const PhysicalProperty = @FieldType(PhysicalState.Properties, @tagName(block));

                var properties: VirtualProperty = @fromBackingInt(0);

                // Make sure all properties that exist on VirtualProperty exist on PhysicalProperty
                inline for (@typeInfo(VirtualProperty).@"struct".field_names) |field_name| {
                    if (comptime std.mem.eql(u8, field_name, "_")) continue;
                    comptime std.debug.assert(@hasField(PhysicalProperty, field_name));
                }

                // Copy every field in PhysicalProperty into VirtualProperty (except for _)
                inline for (@typeInfo(PhysicalProperty).@"struct".field_names) |field_name| {
                    if (comptime std.mem.eql(u8, field_name, "_")) continue;
                    @field(properties, field_name) = @field(physical.payload(block), field_name);
                }
                break :blk @unionInit(Properties, @tagName(block), properties);
            },
        };
        return .{ .block = physical.block, .properties = properties };
    }

    pub fn canBeReplaced(self: @This()) bool {
        return switch (self.block) {
            .air, .deadbush, .tallgrass, .vine => true,
            .snow_layer => self.properties.snow_layer.layers == .@"1",
            .double_plant => self.properties.double_plant.variant == .double_fern or self.properties.double_plant.variant == .double_grass,
            else => false,
        };
    }

    // TODO: ALl the code below this line is abysmal dogshit and I have not verified all of it

    pub fn getCollisionHitboxes(self: @This(), hitboxes: *std.ArrayList(Box(f64))) void {
        const properties = self.properties;
        switch (self.block) {
            .air, .sapling, .flowing_water, .water, .flowing_lava, .lava, .tallgrass, .deadbush, .web, .yellow_flower, .red_flower, .brown_mushroom, .red_mushroom, .fire, .golden_rail, .detector_rail, .rail, .activator_rail, .redstone_wire, .torch, .unlit_redstone_torch, .redstone_torch, .standing_sign, .wall_sign, .lever, .stone_pressure_plate, .wooden_pressure_plate, .light_weighted_pressure_plate, .heavy_weighted_pressure_plate, .stone_button, .wooden_button, .reeds, .wheat, .carrots, .potatoes, .nether_wart, .pumpkin_stem, .melon_stem, .double_plant, .vine, .tripwire, .tripwire_hook, .standing_banner, .wall_banner, .end_portal, .piston_extension, .portal => {},

            .stone, .grass, .dirt, .cobblestone, .planks, .bedrock, .sand, .gravel, .gold_ore, .iron_ore, .coal_ore, .log, .leaves, .sponge, .glass, .lapis_ore, .lapis_block, .dispenser, .sandstone, .noteblock, .wool, .gold_block, .iron_block, .double_stone_slab, .brick_block, .tnt, .bookshelf, .mossy_cobblestone, .obsidian, .mob_spawner, .diamond_ore, .diamond_block, .crafting_table, .furnace, .lit_furnace, .redstone_ore, .lit_redstone_ore, .ice, .snow, .clay, .jukebox, .pumpkin, .netherrack, .glowstone, .lit_pumpkin, .stained_glass, .monster_egg, .stonebrick, .brown_mushroom_block, .red_mushroom_block, .melon_block, .mycelium, .nether_brick, .end_stone, .redstone_lamp, .lit_redstone_lamp, .double_wooden_slab, .emerald_ore, .emerald_block, .command_block, .beacon, .anvil, .unpowered_comparator, .powered_comparator, .redstone_block, .quartz_ore, .quartz_block, .dropper, .stained_hardened_clay, .leaves2, .log2, .slime, .barrier, .prismarine, .sea_lantern, .hay_block, .hardened_clay, .coal_block, .packed_ice, .red_sandstone, .double_stone_slab2 => {
                hitboxes.appendAssumeCapacity(.unit_cube);
            },

            .farmland => hitboxes.appendAssumeCapacity(.unit_cube),

            .bed => hitboxes.appendAssumeCapacity(.centeredPost(0, 0.5625)),

            .cactus => hitboxes.appendAssumeCapacity(.centeredPost(0.0625, 0.9375)),
            .soul_sand => hitboxes.appendAssumeCapacity(.centeredPost(0, 0.875)),

            .waterlily => hitboxes.appendAssumeCapacity(.centeredPost(0, 0.015625)),
            .enchanting_table => hitboxes.appendAssumeCapacity(.centeredPost(0, 0.75)),
            .dragon_egg => hitboxes.appendAssumeCapacity(.centeredPost(0.0625, 1)),
            .flower_pot => hitboxes.appendAssumeCapacity(.centeredPost(0.3125, 0.375)),
            .carpet => hitboxes.appendAssumeCapacity(.centeredPost(0, 0.0625)),
            .chest, .trapped_chest, .ender_chest => hitboxes.appendAssumeCapacity(.centeredPost(0.0625, 0.875)),
            .unpowered_repeater, .powered_repeater => hitboxes.appendAssumeCapacity(.centeredPost(0, 0.125)),
            .daylight_detector, .daylight_detector_inverted => hitboxes.appendAssumeCapacity(.centeredPost(0, 0.375)),
            .brewing_stand => {
                hitboxes.appendAssumeCapacity(.centeredPost(0.4375, 0.875));
                hitboxes.appendAssumeCapacity(.centeredPost(0, 0.125));
            },
            .cake => hitboxes.appendAssumeCapacity(.new((@as(f64, @backingInt(properties.cake.bites)) * 2.0 + 1.0) / 16.0, 0, 0.0625, 0.9375, 0.5, 0.9375)),
            .snow_layer => hitboxes.appendAssumeCapacity(.centeredPost(0, @as(f64, @backingInt(properties.snow_layer.layers)) / 8.0)),

            .ladder => hitboxes.appendAssumeCapacity(switch (properties.ladder.facing) {
                .north => .new(0, 0, 1 - 0.125, 1, 1, 1),
                .south => .new(0, 0, 0, 1, 1, 0.125),
                .west => .new(1 - 0.125, 0, 0, 1, 1, 1),
                .east => .new(0, 0, 0, 0.125, 1, 1),
            }),
            .skull => hitboxes.appendAssumeCapacity(switch (properties.skull.facing) {
                .north => .new(0.25, 0.25, 0.5, 0.75, 0.75, 1),
                .south => .new(0.25, 0.25, 0, 0.75, 0.75, 0.5),
                .west => .new(0.5, 0.25, 0.25, 1, 0.75, 0.75),
                .east => .new(0, 0.25, 0.25, 0.5, 0.75, 0.75),

                .up, .down => .new(0.25, 0, 0.25, 0.75, 0.5, 0.75),
            }),
            .cocoa => hitboxes.appendAssumeCapacity(collision.cocoa(properties.cocoa.facing, properties.cocoa.age)),
            .piston_head => collision.piston_head(hitboxes, properties.piston_head.facing),
            .cobblestone_wall => hitboxes.appendAssumeCapacity(collision.wall(properties.cobblestone_wall.north, properties.cobblestone_wall.south, properties.cobblestone_wall.west, properties.cobblestone_wall.east)),

            .stone_slab => hitboxes.appendAssumeCapacity(collision.slab(properties.stone_slab.half)),
            .wooden_slab => hitboxes.appendAssumeCapacity(collision.slab(properties.wooden_slab.half)),
            .stone_slab2 => hitboxes.appendAssumeCapacity(collision.slab(properties.stone_slab2.half)),

            inline .trapdoor, .iron_trapdoor => hitboxes.appendAssumeCapacity(collision.trapdoor(properties.trapdoor.half, properties.trapdoor.open, properties.trapdoor.facing)),
            inline .sticky_piston, .piston => hitboxes.appendAssumeCapacity(collision.piston(properties.piston.facing, properties.piston.extended)),
            inline .wooden_door, .iron_door, .spruce_door, .birch_door, .jungle_door, .acacia_door, .dark_oak_door => hitboxes.appendAssumeCapacity(collision.door(properties.wooden_door.facing, properties.wooden_door.open, properties.wooden_door.hinge)),
            inline .fence_gate, .spruce_fence_gate, .birch_fence_gate, .jungle_fence_gate, .dark_oak_fence_gate, .acacia_fence_gate => if (collision.fence_gate(properties.fence_gate.open, properties.fence_gate.facing)) |b| hitboxes.appendAssumeCapacity(b),
            inline .fence, .nether_brick_fence, .spruce_fence, .birch_fence, .jungle_fence, .dark_oak_fence, .acacia_fence => collision.fence(hitboxes, properties.fence.north, properties.fence.south, properties.fence.west, properties.fence.east),

            .iron_bars => collision.pane(hitboxes, properties.iron_bars.north, properties.iron_bars.south, properties.iron_bars.west, properties.iron_bars.east),
            .glass_pane => collision.pane(hitboxes, properties.glass_pane.north, properties.glass_pane.south, properties.glass_pane.west, properties.glass_pane.east),
            .stained_glass_pane => collision.pane(hitboxes, properties.stained_glass_pane.north, properties.stained_glass_pane.south, properties.stained_glass_pane.west, properties.stained_glass_pane.east),

            .end_portal_frame => {
                hitboxes.appendAssumeCapacity(.centeredPost(0, 0.8125));
                if (properties.end_portal_frame.eye) hitboxes.appendAssumeCapacity(.new(0.3125, 0.8125, 0.3125, 0.6875, 1, 0.6875));
            },

            .cauldron => collision.funnel(hitboxes, 0.3125),
            .hopper => collision.funnel(hitboxes, 0.625),

            inline .oak_stairs, .stone_stairs, .brick_stairs, .stone_brick_stairs, .nether_brick_stairs, .sandstone_stairs, .spruce_stairs, .birch_stairs, .jungle_stairs, .quartz_stairs, .acacia_stairs, .dark_oak_stairs, .red_sandstone_stairs => {
                collision.stair(hitboxes, properties.oak_stairs.facing, properties.oak_stairs.half, properties.oak_stairs.shape);
            },
        }
    }

    pub fn getRaytraceHitboxes(self: @This(), hitboxes: *std.ArrayList(Box(f64))) void {
        const properties = self.properties;
        switch (self.block) {
            .piston_extension, .air => return,

            .cactus, .soul_sand, .glass_pane, .stained_glass_pane, .iron_bars => hitboxes.appendAssumeCapacity(.unit_cube),
            .fire, .flowing_water, .water, .flowing_lava, .lava => hitboxes.appendAssumeCapacity(.unit_cube),
            .web, .double_plant => hitboxes.appendAssumeCapacity(.unit_cube),
            .cauldron, .hopper => hitboxes.appendAssumeCapacity(.unit_cube),
            .brewing_stand => hitboxes.appendAssumeCapacity(.new(0, 0, 0, 1, 0.125, 1)),

            .sapling, .tallgrass, .deadbush => hitboxes.appendAssumeCapacity(.new(0.1, 0, 0.1, 0.9, 0.8, 0.9)),
            .brown_mushroom, .red_mushroom => hitboxes.appendAssumeCapacity(.new(0.3, 0, 0.3, 0.7, 0.4, 0.7)),
            .yellow_flower, .red_flower => hitboxes.appendAssumeCapacity(.new(0.3, 0, 0.3, 0.7, 0.6, 0.7)),
            .wheat, .carrots, .potatoes, .nether_wart => hitboxes.appendAssumeCapacity(.new(0, 0, 0, 1, 0.25, 1)),
            .reeds => hitboxes.appendAssumeCapacity(.new(0.125, 0, 0.125, 0.875, 1, 0.875)),
            .redstone_wire => hitboxes.appendAssumeCapacity(.new(0, 0, 0, 1, 0.0625, 1)),
            .standing_sign, .standing_banner => hitboxes.appendAssumeCapacity(.new(0.25, 0, 0.25, 0.75, 1, 0.75)),
            .end_portal => hitboxes.appendAssumeCapacity(.new(0, 0, 0, 1, 0.0625, 1)),
            .end_portal_frame => hitboxes.appendAssumeCapacity(.new(0, 0, 0, 1, 0.8125, 1)),
            .farmland => hitboxes.appendAssumeCapacity(.new(0, 0, 0, 1, 0.9375, 1)),

            .snow_layer => hitboxes.appendAssumeCapacity(.new(0, 0, 0, 1, (@as(f64, @backingInt(properties.snow_layer.layers)) + 1) / 8.0, 1)),
            .pumpkin_stem, .melon_stem => hitboxes.appendAssumeCapacity(ray.stem(properties.melon_stem.age)),

            .piston, .sticky_piston => hitboxes.appendAssumeCapacity(collision.piston(properties.piston.facing, properties.piston.extended)),
            .piston_head => hitboxes.appendAssumeCapacity(ray.piston_head(properties.piston_head.facing)),

            .fence_gate, .spruce_fence_gate, .birch_fence_gate, .jungle_fence_gate, .dark_oak_fence_gate, .acacia_fence_gate => {
                hitboxes.appendAssumeCapacity(ray.fence_gate(properties.fence_gate.facing));
            },

            .fence, .nether_brick_fence, .spruce_fence, .birch_fence, .jungle_fence, .dark_oak_fence, .acacia_fence => {
                hitboxes.appendAssumeCapacity(ray.fence(properties.fence.north, properties.fence.south, properties.fence.west, properties.fence.east));
            },

            .cobblestone_wall => hitboxes.appendAssumeCapacity(ray.wall(properties.cobblestone_wall.north, properties.cobblestone_wall.south, properties.cobblestone_wall.west, properties.cobblestone_wall.east)),

            .golden_rail => hitboxes.appendAssumeCapacity(ray.rail(properties.golden_rail.shape)),
            .detector_rail => hitboxes.appendAssumeCapacity(ray.rail(properties.detector_rail.shape)),
            .activator_rail => hitboxes.appendAssumeCapacity(ray.rail(properties.activator_rail.shape)),
            .rail => hitboxes.appendAssumeCapacity(ray.rail(properties.rail.shape)),

            .torch => hitboxes.appendAssumeCapacity(ray.torch(properties.torch.facing)),
            .redstone_torch => hitboxes.appendAssumeCapacity(ray.torch(properties.redstone_torch.facing)),
            .unlit_redstone_torch => hitboxes.appendAssumeCapacity(ray.torch(properties.unlit_redstone_torch.facing)),
            .lever => hitboxes.appendAssumeCapacity(ray.lever(properties.lever.facing)),
            .stone_button => hitboxes.appendAssumeCapacity(ray.button(properties.stone_button.facing, properties.stone_button.powered)),
            .wooden_button => hitboxes.appendAssumeCapacity(ray.button(properties.wooden_button.facing, properties.wooden_button.powered)),

            .stone_pressure_plate => hitboxes.appendAssumeCapacity(ray.pressure_plate(properties.stone_pressure_plate.powered)),
            .wooden_pressure_plate => hitboxes.appendAssumeCapacity(ray.pressure_plate(properties.wooden_pressure_plate.powered)),
            .light_weighted_pressure_plate => hitboxes.appendAssumeCapacity(ray.pressure_plate(properties.light_weighted_pressure_plate.power != 0)),
            .heavy_weighted_pressure_plate => hitboxes.appendAssumeCapacity(ray.pressure_plate(properties.heavy_weighted_pressure_plate.power != 0)),

            .tripwire_hook => hitboxes.appendAssumeCapacity(ray.tripwire_hook(properties.tripwire_hook.facing)),
            .portal => hitboxes.appendAssumeCapacity(ray.portal(properties.portal.axis)),

            .wall_sign => hitboxes.appendAssumeCapacity(ray.wall_sign(properties.wall_sign.facing)),
            .wall_banner => hitboxes.appendAssumeCapacity(ray.wall_sign(properties.wall_banner.facing)),
            .tripwire => hitboxes.appendAssumeCapacity(ray.tripwire(properties.tripwire.suspended, properties.tripwire.attached)),
            .vine => hitboxes.appendAssumeCapacity(ray.vine(properties.vine.north, properties.vine.east, properties.vine.south, properties.vine.west, false)),

            .nether_brick_stairs,
            .oak_stairs,
            .stone_stairs,
            .brick_stairs,
            .stone_brick_stairs,
            .sandstone_stairs,
            .spruce_stairs,
            .birch_stairs,
            .jungle_stairs,
            .quartz_stairs,
            .acacia_stairs,
            .dark_oak_stairs,
            .red_sandstone_stairs,
            => return self.getCollisionHitboxes(hitboxes),

            else => return self.getCollisionHitboxes(hitboxes),
        }
    }

    pub fn isFullCube(self: @This()) bool {
        const first = self.getCollisionHitboxes()[0] orelse return false;
        const dx = first.max.x - first.min.x;
        const dy = first.max.y - first.min.y;
        const dz = first.max.z - first.min.z;
        return (dx + dy + dz) / 3.0 >= 1.0;
    }

    pub const StairShape = enum(u3) { straight, inner_left, inner_right, outer_left, outer_right };
    pub const StemFacing = enum(u3) { up = 0, north = 1, south = 2, west = 3, east = 4 };
    pub const DoorFacing = enum(u2) { north = 0, south = 1, west = 2, east = 3 };
    pub const RedstoneWireConnection = enum(u2) { up, side, none };
};

fn stemFacingFor(world: *const World, block_pos: Vector3(i32), stem: Block) VirtualState.StemFacing {
    const plant: Block = if (stem == .pumpkin_stem) .melon_block else .pumpkin;
    if (world.getBlock(block_pos.north()) == plant) return .north;
    if (world.getBlock(block_pos.east()) == plant) return .east;
    if (world.getBlock(block_pos.south()) == plant) return .south;
    if (world.getBlock(block_pos.west()) == plant) return .west;
    return .up;
}

fn fenceShouldConnectTo(fence: Block, neighbour: Block) bool {
    return neighbour.isFenceGate() or
        neighbour.isFence() and neighbour.getMaterial() == fence.getMaterial() or
        neighbour.getMaterial().blocksMovementAndNotTranslucent() and neighbour.isCube() and neighbour.getMaterial() != .pumpkin and neighbour != .barrier;
}

fn paneShouldConnectTo(neighbour: Block) bool {
    return switch (neighbour) {
        .iron_bars, .glass_pane, .stained_glass_pane, .glass, .stained_glass => true,
        else => neighbour.isSolid(),
    };
}

fn wallShouldConnectTo(neighbor: Block) bool {
    return neighbor == .cobblestone_wall or
        neighbor.isFenceGate() or
        neighbor.getMaterial().blocksMovementAndNotTranslucent() and neighbor.isCube() and neighbor.getMaterial() != .pumpkin and neighbor != .barrier;
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
    if (!other.block.isStair()) return false;
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
    if (!neighbour.block.isStair() or neighbour.properties.oak_stairs.half != self_props.half) return true;
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
    if (!neighbour.block.isStair() or neighbour.properties.oak_stairs.half != self_props.half) return 0;
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

const ray = opaque {
    fn stem(age: u3) Box(f64) {
        return .centeredPost(
            0.375,
            (@as(f64, age) * 2.0 + 2.0) / 16.0,
        );
    }
    fn fence(north: bool, south: bool, west: bool, east: bool) Box(f64) {
        return .new(
            if (west) 0 else 0.375,
            0,
            if (north) 0 else 0.375,
            if (east) 1 else 0.625,
            1,
            if (south) 1 else 0.625,
        );
    }
    fn wall(north: bool, south: bool, west: bool, east: bool) Box(f64) {
        const x0: f64 = if (west) 0 else 0.25;
        const x1: f64 = if (east) 1 else 0.75;
        const z0: f64 = if (north) 0 else 0.25;
        const z1: f64 = if (south) 1 else 0.75;

        return if (north and south and !(west or east))
            .new(0.3125, 0, z0, 0.6875, 0.8125, z1)
        else if (west and east and !(north or south))
            .new(x0, 0, 0.3125, x1, 0.8125, 0.6875)
        else
            .new(x0, 0, z0, x1, 1, z1);
    }
    fn fence_gate(facing: PhysicalState.PackedHorizontalFacing) Box(f64) {
        return switch (facing) {
            .north, .south => .new(0, 0, 0.375, 1, 1, 0.625),
            .west, .east => .new(0.375, 0, 0, 0.625, 1, 1),
        };
    }
    fn rail(shape: anytype) Box(f64) {
        const ascending = switch (shape) {
            .ascending_east, .ascending_west, .ascending_north, .ascending_south => true,
            else => false,
        };
        return .new(0, 0, 0, 1, if (ascending) 0.625 else 0.125, 1);
    }
    fn torch(facing: PhysicalState.TorchFacing) Box(f64) {
        const t: f64 = 0.15;
        return switch (facing) {
            // zig fmt: off
            .east =>  .new(0        , 0.2, 0.5 - t   , t * 2  , 0.8, 0.5 + t),
            .west =>  .new(1 - t * 2, 0.2, 0.5 - t   , 1, 0.8 , 0.5 + t     ),
            .south => .new(0.5 - t  , 0.2, 0, 0.5 + t, 0.8    , t * 2       ),
            .north => .new(0.5 - t  , 0.2, 1 - t * 2 , 0.5 + t, 0.8, 1      ),

            .up =>    .new(0.4      , 0  , 0.4       , 0.6    , 0.6, 0.6    ),
            // zig fmt: on
        };
    }
    fn lever(facing: PhysicalState.LeverFacing) Box(f64) {
        const t: f64 = 0.1875;
        // zig fmt: off
        return switch (facing) {
            .east =>  .new(0        , 0.2, 0.5 - t  , t * 2  , 0.8, 0.5 + t),
            .west =>  .new(1 - t * 2, 0.2, 0.5 - t  , 1      , 0.8, 0.5 + t),
            .south => .new(0.5 - t  , 0.2, 0        , 0.5 + t, 0.8, t * 2  ),
            .north => .new(0.5 - t  , 0.2, 1 - t * 2, 0.5 + t, 0.8, 1      ),

            .up_z, .up_x =>     .new(0.25, 0  , 0.25, 0.75, 0.6, 0.75),
            .down_x, .down_z => .new(0.25, 0.4, 0.25, 0.75, 1.0, 0.75),
        };
        // zig fmt: on
    }
    fn button(facing: PhysicalState.ButtonFacing, powered: bool) Box(f64) {
        const h: f64 = if (powered) 1.0 / 16.0 else 2.0 / 16.0;
        // zig fmt: off
        return switch (facing) {
            .east =>  .new(0     , 0.375, 0.3125, h     , 0.625, 0.6875),
            .west =>  .new(1 - h , 0.375, 0.3125, 1     , 0.625, 0.6875),
            .south => .new(0.3125, 0.375, 0     , 0.6875, 0.625, h     ),
            .north => .new(0.3125, 0.375, 1 - h , 0.6875, 0.625, 1     ),

            .up =>    .new(0.3125, 0    , 0.375 , 0.6875, h    , 0.625),
            .down =>  .new(0.3125, 1 - h, 0.375 , 0.6875, 1    , 0.625),
        };
        // zig fmt: on
    }
    fn pressure_plate(powered: bool) Box(f64) {
        return .centeredPost(0.0625, if (powered) 0.03125 else 0.0625);
    }
    fn wall_sign(facing: PhysicalState.HorizontalFacing) Box(f64) {
        const f: f64 = 0.28125;
        const g: f64 = 0.78125;
        const j: f64 = 0.125;
        // zig fmt: off
        return switch (facing) {
            .north => .new(0    , f, 1 - j, 1, g, 1),
            .south => .new(0    , f, 0    , 1, g, j),
            .west =>  .new(1 - j, f, 0    , 1, g, 1),
            .east =>  .new(0    , f, 0    , j, g, 1),
        };
        // zig fmt: on
    }
    fn tripwire_hook(facing: PhysicalState.PackedHorizontalFacing) Box(f64) {
        const f: f64 = 0.1875;
        // zig fmt: off
        return switch (facing) {
            .east =>  .new(0        , 0.2, 0.5 - f  , f * 2  , 0.8, 0.5 + f),
            .west =>  .new(1 - f * 2, 0.2, 0.5 - f  , 1      , 0.8, 0.5 + f),
            .south => .new(0.5 - f  , 0.2, 0        , 0.5 + f, 0.8, f * 2  ),
            .north => .new(0.5 - f  , 0.2, 1 - f * 2, 0.5 + f, 0.8, 1      ),
        };
        // zig fmt: on
    }
    fn tripwire(suspended: bool, attached: bool) Box(f64) {
        if (!suspended) return .new(0, 0, 0, 1, 0.09375, 1);
        if (!attached) return .new(0, 0, 0, 1, 0.5, 1);
        return .new(0, 0.0625, 0, 1, 0.15625, 1);
    }
    fn portal(axis: PhysicalState.PortalAxis) Box(f64) {
        const f: f64 = if (axis == .x) 0.5 else 0.125;
        const g: f64 = if (axis == .z) 0.5 else 0.125;
        return .new(0.5 - f, 0, 0.5 - g, 0.5 + f, 1, 0.5 + g);
    }
    fn piston_head(facing: PhysicalState.Facing) Box(f64) {
        return switch (facing) {
            .down => .new(0, 0, 0, 1, 0.25, 1),
            .up => .new(0, 0.75, 0, 1, 1, 1),
            .north => .new(0, 0, 0, 1, 1, 0.25),
            .south => .new(0, 0, 0.75, 1, 1, 1),
            .west => .new(0, 0, 0, 0.25, 1, 1),
            .east => .new(0.75, 0, 0, 1, 1, 1),
        };
    }
    fn vine(north: bool, east: bool, south: bool, west: bool, up: bool) Box(f64) {
        var min: Vector3(f64) = .splat(1);
        var max: Vector3(f64) = .splat(0);
        var any_horizontal = false;

        if (west) {
            min = .{ .x = 0, .y = 0, .z = 0 };
            max = .{ .x = @max(max.x, 0.0625), .y = 1, .z = 1 };
            any_horizontal = true;
        }
        if (east) {
            min = .{ .x = @min(min.x, 0.9375), .y = 0, .z = 0 };
            max = .{ .x = 1, .y = 1, .z = 1 };
            any_horizontal = true;
        }
        if (north) {
            min = .{ .x = 0, .y = 0, .z = 0 };
            max = .{ .x = 1, .y = 1, .z = @max(max.z, 0.0625) };
            any_horizontal = true;
        }
        if (south) {
            min = .{ .x = 0, .y = 0, .z = @min(min.z, 0.9375) };
            max = .{ .x = 0, .y = 1, .z = 1 };
            any_horizontal = true;
        }
        if (!any_horizontal and up) {
            min = .{ .x = 0, .y = @min(min.y, 0.9375), .z = 0 };
            max = .{ .x = 1, .y = 1, .z = 1 };
        }
        return .{ .min = min, .max = max };
    }
};

const collision = opaque {
    fn slab(half: PhysicalState.Half) Box(f64) {
        return if (half == .top)
            .new(0, 0.5, 0, 1, 1, 1)
        else
            .new(0, 0, 0, 1, 0.5, 1);
    }
    fn trapdoor(half: PhysicalState.Half, open: bool, facing: PhysicalState.TrapdoorFacing) Box(f64) {
        const t: f64 = 0.1875;
        if (!open) return if (half == .top)
            .new(0, 0.8125, 0, 1, 1, 1)
        else
            .new(0, 0, 0, 1, t, 1);
        return switch (facing) {
            .north => .new(0, 0, 1 - t, 1, 1, 1),
            .south => .new(0, 0, 0, 1, 1, t),
            .west => .new(1 - t, 0, 0, 1, 1, 1),
            .east => .new(0, 0, 0, t, 1, 1),
        };
    }
    fn cocoa(facing: PhysicalState.PackedHorizontalFacing, age: PhysicalState.Age02) Box(f64) {
        const j = 4.0 + @as(f64, @backingInt(age)) * 2.0;
        const k = 5.0 + @as(f64, @backingInt(age)) * 2.0;
        const w = j / 2.0;
        const y0 = (12.0 - k) / 16.0;
        return switch (facing) {
            .south => .new((8.0 - w) / 16.0, y0, (15.0 - j) / 16.0, (8.0 + w) / 16.0, 0.75, 0.9375),
            .north => .new((8.0 - w) / 16.0, y0, 0.0625, (8.0 + w) / 16.0, 0.75, (1.0 + j) / 16.0),
            .west => .new(0.0625, y0, (8.0 - w) / 16.0, (1.0 + j) / 16.0, 0.75, (8.0 + w) / 16.0),
            .east => .new((15.0 - j) / 16.0, y0, (8.0 - w) / 16.0, 0.9375, 0.75, (8.0 + w) / 16.0),
        };
    }
    fn piston(facing: PhysicalState.Facing, extended: bool) Box(f64) {
        if (!extended) return .unit_cube;
        const t: f64 = 0.25;
        return switch (facing) {
            .down => .new(0, t, 0, 1, 1, 1),
            .up => .new(0, 0, 0, 1, 1 - t, 1),
            .north => .new(0, 0, t, 1, 1, 1),
            .south => .new(0, 0, 0, 1, 1, 1 - t),
            .west => .new(t, 0, 0, 1, 1, 1),
            .east => .new(0, 0, 0, 1 - t, 1, 1),
        };
    }
    fn piston_head(collisions: *std.ArrayList(Box(f64)), facing: PhysicalState.Facing) void {
        collisions.appendAssumeCapacity(switch (facing) {
            .down => .new(0, 0, 0, 1, 0.25, 1),
            .up => .new(0, 0.75, 0, 1, 1, 1),
            .north => .new(0, 0, 0, 1, 1, 0.25),
            .south => .new(0, 0, 0.75, 1, 1, 1),
            .west => .new(0, 0, 0, 0.25, 1, 1),
            .east => .new(0.75, 0, 0, 1, 1, 1),
        });
        collisions.appendAssumeCapacity(switch (facing) {
            .down => .new(0.375, 0.25, 0.375, 0.625, 1, 0.625),
            .up => .new(0.375, 0, 0.375, 0.625, 0.75, 0.625),
            .north => .new(0.25, 0.375, 0.25, 0.75, 0.625, 1),
            .south => .new(0.25, 0.375, 0, 0.75, 0.625, 0.75),
            .west => .new(0.375, 0.25, 0.25, 0.625, 0.75, 1),
            .east => .new(0, 0.375, 0.25, 0.75, 0.625, 0.75),
        });
    }
    fn door(facing: PhysicalState.DoorFacing, open: bool, hinge: PhysicalState.DoorHinge) Box(f64) {
        const t: f64 = 0.1875;
        if (open) return switch (facing) {
            .east => if (hinge == .right) .new(0, 0, 1 - t, 1, 1, 1) else .new(0, 0, 0, 1, 1, t),
            .south => if (hinge == .right) .new(0, 0, 0, t, 1, 1) else .new(1 - t, 0, 0, 1, 1, 1),
            .west => if (hinge == .right) .new(0, 0, 0, 1, 1, t) else .new(0, 0, 1 - t, 1, 1, 1),
            .north => if (hinge == .right) .new(1 - t, 0, 0, 1, 1, 1) else .new(0, 0, 0, t, 1, 1),
        };
        return switch (facing) {
            .east => .new(0, 0, 0, t, 1, 1),
            .south => .new(0, 0, 0, 1, 1, t),
            .west => .new(1 - t, 0, 0, 1, 1, 1),
            .north => .new(0, 0, 1 - t, 1, 1, 1),
        };
    }
    fn fence_gate(open: bool, facing: PhysicalState.PackedHorizontalFacing) ?Box(f64) {
        if (open) return null;
        return switch (facing) {
            .north, .south => .new(0, 0, 0.375, 1, 1.5, 0.625),
            .west, .east => .new(0.375, 0, 0, 0.625, 1.5, 1),
        };
    }
    fn fence(collisions: *std.ArrayList(Box(f64)), north: bool, south: bool, west: bool, east: bool) void {
        const width: f64 = 0.375;

        const z0: f64 = if (north) 0 else width;
        const z1: f64 = if (south) 1 else 1 - width;
        if (north or south) collisions.appendAssumeCapacity(.new(width, 0, z0, 1 - width, 1.5, z1));

        const x0: f64 = if (west) 0 else width;
        const x1: f64 = if (east) 1 else 1 - width;
        if (west or east or (!north and !south)) collisions.appendAssumeCapacity(.new(x0, 0, width, x1, 1.5, 1 - width));
    }
    fn pane(collisions: *std.ArrayList(Box(f64)), north: bool, south: bool, west: bool, east: bool) void {
        const a: f64 = 0.4375;
        const b: f64 = 1 - a;
        const any = north or south or west or east;

        if (west and east) {
            collisions.appendAssumeCapacity(.new(0, 0, a, 1, 1, b));
        } else if (west) {
            collisions.appendAssumeCapacity(.new(0, 0, a, 0.5, 1, b));
        } else if (east) {
            collisions.appendAssumeCapacity(.new(0.5, 0, a, 1, 1, b));
        } else if (!any) {
            collisions.appendAssumeCapacity(.new(0, 0, a, 1, 1, b));
        }

        if (north and south) {
            collisions.appendAssumeCapacity(.new(a, 0, 0, b, 1, 1));
        } else if (north) {
            collisions.appendAssumeCapacity(.new(a, 0, 0, b, 1, 0.5));
        } else if (south) {
            collisions.appendAssumeCapacity(.new(a, 0, 0.5, b, 1, 1));
        } else if (!any) {
            collisions.appendAssumeCapacity(.new(a, 0, 0, b, 1, 1));
        }
    }
    fn wall(north: bool, south: bool, west: bool, east: bool) Box(f64) {
        const x0: f64 = if (west) 0 else 0.25;
        const x1: f64 = if (east) 1 else 0.75;
        const z0: f64 = if (north) 0 else 0.25;
        const z1: f64 = if (south) 1 else 0.75;
        const y: f64 = 1.5;

        return if (north and south and !(west or east))
            .new(0.3125, 0, z0, 0.6875, y, z1)
        else if (west and east and !(north or south))
            .new(x0, 0, 0.3125, x1, y, 0.6875)
        else
            .new(x0, 0, z0, x1, y, z1);
    }
    fn funnel(collisions: *std.ArrayList(Box(f64)), inner_height: f64) void {
        collisions.appendAssumeCapacity(.new(0, 0, 0, 1, inner_height, 1));
        collisions.appendAssumeCapacity(.new(0, 0, 0, 0.125, 1, 1));
        collisions.appendAssumeCapacity(.new(0, 0, 0, 1, 1, 0.125));
        collisions.appendAssumeCapacity(.new(0.875, 0, 0, 1, 1, 1));
        collisions.appendAssumeCapacity(.new(0, 0, 0.875, 1, 1, 1));
    }

    fn stair(collisions: *std.ArrayList(Box(f64)), facing: PhysicalState.StairFacing, half: PhysicalState.Half, shape: VirtualState.StairShape) void {
        collisions.appendAssumeCapacity(switch (half) {
            .top => .new(0, 0.5, 0, 1, 1, 1),
            .bottom => .new(0, 0, 0, 1, 0.5, 1),
        });

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

        const split = shape == .outer_left or shape == .outer_right;
        collisions.appendAssumeCapacity(if (split)
            (if (axis_is_x)
                .new(s0, y0, bz0, s1, y1, bz1)
            else
                .new(bx0, y0, s0, bx1, y1, s1))
        else
            .new(bx0, y0, bz0, bx1, y1, bz1));

        if (shape == .inner_left or shape == .inner_right) {
            collisions.appendAssumeCapacity(if (axis_is_x)
                .new(s0, y0, 1 - bz1, s1, y1, 1 - bz0)
            else
                .new(1 - bx1, y0, s0, 1 - bx0, y1, s1));
        }
    }
};

const std = @import("std");

const main = @import("main");

const physical_state = @import("physical_state.zig");
const Block = @import("block.zig").Block;

const Box = main.Box;
const Direction = main.Direction;
const Vector3 = main.Vector3;
const World = main.World;
const PhysicalState = physical_state.PhysicalState;
