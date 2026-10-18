const std = @import("std");

const Block = @import("main").Block;
const Direction = @import("main").Direction;
const Entity = @import("main").Entity;
const Vector3 = @import("main").Vector3;
const World = @import("main").World;

const attributes = @import("block_attributes.zig");

pub const PhysicalState = packed struct(u16) {
    properties: Properties,
    block: Block,
    _: u4 = 0,

    pub const air_blockstate: @This() = .{
        .block = .air,
        .properties = .{ .air = .{} },
    };

    pub fn validateRaw(raw: u16) @This() {
        const high_bits: u12 = @intCast(raw >> 4);
        const block: Block = if (high_bits <= 197) @fromBackingInt(@intCast(high_bits)) else return .air_blockstate;

        const low_bits: u4 = @intCast(raw & 0b1111);

        const valid_metadata_table = @import("valid_metadata_table.zig").@"export";
        if (!valid_metadata_table.get(block).isSet(low_bits)) return .air_blockstate;

        return @bitCast(raw);
    }

    pub fn payload(self: @This(), comptime block: Block) @TypeOf(@field(self.properties, @tagName(block))) {
        std.debug.assert(self.block == block);
        return @field(self.properties, @tagName(block));
    }

    pub fn maybePayload(self: @This(), comptime block: Block) ?@TypeOf(@field(self.properties, @tagName(block))) {
        return if (self.block == block)
            @field(self.properties, @tagName(block))
        else
            null;
    }

    /// check for solid blocking cube, a top-half slab/stair, a hopper, or a full snow layer
    pub fn hasSolidTop(self: @This()) bool {
        const block = self.block;
        if (block.getMaterial().blocksMovementAndNotTranslucent() and block.isCube()) return true;

        return switch (block) {
            .oak_stairs,
            .stone_stairs,
            .brick_stairs,
            .stone_brick_stairs,
            .nether_brick_stairs,
            .sandstone_stairs,
            .spruce_stairs,
            .birch_stairs,
            .jungle_stairs,
            .quartz_stairs,
            .acacia_stairs,
            .dark_oak_stairs,
            .red_sandstone_stairs,
            => self.properties.oak_stairs.half == .top,
            .stone_slab, .wooden_slab, .stone_slab2 => self.properties.stone_slab.half == .top,
            .hopper => true,
            .snow_layer => self.properties.snow_layer.layers == .@"7" or self.properties.snow_layer.layers == .@"8",
            else => false,
        };
    }

    pub fn use(self: @This(), world: *World, player: *Entity.LocalPlayer, block_pos: Vector3(i32)) !bool {
        const can_modify_world = !world.game_mode.restrictsWorldModification();

        return switch (self.block) {
            .anvil, .beacon, .bed, .brewing_stand => true,
            .cake => {
                // TODO: check hunger, etc, then eat it...
                return true;
            },
            // an already-powered button still eats the click
            .wooden_button, .stone_button => {
                var next = self;
                if (self.properties.stone_button.powered) return true;
                next.properties.stone_button.powered = true;
                try world.setBlockState(.failing, block_pos, next);
                return true;
            },
            .cauldron => true,

            .chest, .trapped_chest => true,

            .command_block => {
                std.debug.panic("TODO: block entities", .{});
            },

            .powered_comparator, .unpowered_comparator => {
                if (!can_modify_world) return false;
                var next = self;
                const mode = &next.properties.unpowered_comparator.mode;
                mode.* = if (mode.* == .compare) .subtract else .compare;
                try world.setBlockState(.failing, block_pos, next);
                return true;
            },

            .crafting_table => true,

            .daylight_detector, .daylight_detector_inverted => {
                if (!can_modify_world) return false;

                const power = self.properties.daylight_detector.power;

                try world.setBlockState(.failing, block_pos, if (self.block == .daylight_detector)
                    .{ .block = .daylight_detector_inverted, .properties = .{ .daylight_detector_inverted = .{ .power = power } } }
                else
                    .{ .block = .daylight_detector, .properties = .{ .daylight_detector = .{ .power = power } } });
                return true;
            },

            .dispenser, .dropper => true,

            .iron_door => true,

            .wooden_door,
            .spruce_door,
            .birch_door,
            .jungle_door,
            .acacia_door,
            .dark_oak_door,
            => {
                // the open bit lives on the lower half, so set the state of that block
                const is_lower_half = self.properties.wooden_door.half == .lower;
                const owning_pos = if (is_lower_half) block_pos else block_pos.down();
                const owning_state = if (is_lower_half) self else world.getBlockState(owning_pos);
                if (owning_state.block != self.block) return false;

                var next = owning_state;
                next.properties.wooden_door.other.when_lower.open = !next.properties.wooden_door.other.when_lower.open;

                try world.setBlockState(.failing, owning_pos, next);
                return true;
            },

            .dragon_egg => true,

            .enchanting_table => true,

            .ender_chest => true,

            .fence,
            .nether_brick_fence,
            .spruce_fence,
            .birch_fence,
            .jungle_fence,
            .dark_oak_fence,
            .acacia_fence,
            => true,

            .fence_gate,
            .spruce_fence_gate,
            .birch_fence_gate,
            .jungle_fence_gate,
            .dark_oak_fence_gate,
            .acacia_fence_gate,
            => {
                // opening also swings the gate to face away from the player
                const facing: PhysicalState.PackedHorizontalFacing = switch (@mod(
                    @as(i32, @intFromFloat(@floor(player.base.rotation.yaw / 90.0 + 0.5))),
                    4,
                )) {
                    0 => .south,
                    1 => .west,
                    2 => .north,
                    else => .east,
                };

                var next = self;
                const open = &next.properties.fence_gate.open;
                if (open.*) {
                    open.* = false;
                } else {
                    const opposite: PhysicalState.PackedHorizontalFacing = switch (facing) {
                        .south => .north,
                        .north => .south,
                        .west => .east,
                        .east => .west,
                    };
                    if (next.properties.fence_gate.facing == opposite) next.properties.fence_gate.facing = facing;
                    open.* = true;
                }
                try world.setBlockState(.failing, block_pos, next);
                return true;
            },

            // TODO: implement
            .flower_pot => true,

            .furnace, .lit_furnace => true,

            .hopper => true,

            .jukebox => {
                if (!self.properties.jukebox.has_record) return false;
                var next = self;
                next.properties.jukebox.has_record = false;
                try world.setBlockState(.failing, block_pos, next);
                return true;
            },

            .lever => {
                var next = self;
                const powered = &next.properties.lever.powered;
                powered.* = !powered.*;
                try world.setBlockState(.failing, block_pos, next);
                return true;
            },

            .noteblock => true,

            .piston_extension => false,

            .redstone_ore => {
                // turn unlit into lit, but still return false
                try world.setBlockState(.failing, block_pos, .{
                    .block = .lit_redstone_ore,
                    .properties = .{ .lit_redstone_ore = .{} },
                });
                return false;
            },

            .lit_redstone_ore => false,

            .powered_repeater, .unpowered_repeater => {
                if (!can_modify_world) return false;
                var next = self;
                const delay = &next.properties.unpowered_repeater.delay;
                delay.* = @fromBackingInt(@intCast(@backingInt(delay.*) +% 1));
                try world.setBlockState(.failing, block_pos, next);
                return true;
            },

            .standing_sign, .wall_sign => true,

            // stairs just delegate to their parent block
            // here for explicitness
            .oak_stairs,
            .stone_stairs,
            .brick_stairs,
            .stone_brick_stairs,
            .nether_brick_stairs,
            .sandstone_stairs,
            .spruce_stairs,
            .birch_stairs,
            .jungle_stairs,
            .quartz_stairs,
            .acacia_stairs,
            .dark_oak_stairs,
            .red_sandstone_stairs,
            => false,

            .tnt => {
                // TODO: ignite with flint and steel
                return false;
            },

            .iron_trapdoor => true,

            .trapdoor => {
                var next = self;
                const open = &next.properties.trapdoor.open;
                open.* = !open.*;
                try world.setBlockState(.failing, block_pos, next);
                return true;
            },

            inline else => |unhandled| {
                @setEvalBranchQuota(10_000);
                // make sure our override arms are exhaustive
                comptime std.debug.assert(!attributes.overrides_use.contains(unhandled));
                return false;
            },
        };
    }

    pub const Properties = packed union(u4) {
        air: packed struct(u4) { _: u4 = 0 },
        stone: packed struct(u4) { variant: StoneVariant, _: u1 = 0 },
        grass: packed struct(u4) { _: u4 = 0 },
        dirt: packed struct(u4) { variant: DirtVariant, _: u2 = 0 },
        cobblestone: packed struct(u4) { _: u4 = 0 },
        planks: packed struct(u4) { variant: WoodVariant, _: u1 = 0 },
        sapling: packed struct(u4) { variant: WoodVariant, stage: u1 },
        bedrock: packed struct(u4) { _: u4 = 0 },
        flowing_water: packed struct(u4) { level: u4 },
        water: packed struct(u4) { level: u4 },
        flowing_lava: packed struct(u4) { level: u4 },
        lava: packed struct(u4) { level: u4 },
        sand: packed struct(u4) { variant: SandVariant, _: u3 = 0 },
        gravel: packed struct(u4) { _: u4 = 0 },
        gold_ore: packed struct(u4) { _: u4 = 0 },
        iron_ore: packed struct(u4) { _: u4 = 0 },
        coal_ore: packed struct(u4) { _: u4 = 0 },
        log: packed struct(u4) { variant: WoodVariant1, axis: LogAxis },
        leaves: packed struct(u4) { variant: WoodVariant1, not_decayable: bool, check_decay: bool },
        sponge: packed struct(u4) { wet: bool, _: u3 = 0 },
        glass: packed struct(u4) { _: u4 = 0 },
        lapis_ore: packed struct(u4) { _: u4 = 0 },
        lapis_block: packed struct(u4) { _: u4 = 0 },
        dispenser: packed struct(u4) { facing: Facing, triggered: bool },
        sandstone: packed struct(u4) { variant: SandstoneVariant, _: u2 = 0 },
        noteblock: packed struct(u4) { _: u4 = 0 },
        bed: packed struct(u4) { facing: PackedHorizontalFacing, occupied: bool, part: BedPart },
        golden_rail: packed struct(u4) { shape: StraightRailShape, powered: bool },
        detector_rail: packed struct(u4) { shape: StraightRailShape, powered: bool },
        sticky_piston: packed struct(u4) { facing: Facing, extended: bool },
        web: packed struct(u4) { _: u4 = 0 },
        tallgrass: packed struct(u4) { variant: TallGrassVariant, _: u2 = 0 },
        deadbush: packed struct(u4) { _: u4 = 0 },
        piston: packed struct(u4) { facing: Facing, extended: bool },
        piston_head: packed struct(u4) { facing: Facing, type: PistonType },
        wool: packed struct(u4) { color: Color },
        piston_extension: packed struct(u4) { facing: Facing, sticky: bool },
        yellow_flower: packed struct(u4) { _: u4 = 0 },
        red_flower: packed struct(u4) { variant: RedFlowerVariant },
        brown_mushroom: packed struct(u4) { _: u4 = 0 },
        red_mushroom: packed struct(u4) { _: u4 = 0 },
        gold_block: packed struct(u4) { _: u4 = 0 },
        iron_block: packed struct(u4) { _: u4 = 0 },
        double_stone_slab: packed struct(u4) { variant: StoneSlabVariant, seamless: bool },
        stone_slab: packed struct(u4) { variant: StoneSlabVariant, half: Half },
        brick_block: packed struct(u4) { _: u4 = 0 },
        tnt: packed struct(u4) { explode: bool, _: u3 = 0 },
        bookshelf: packed struct(u4) { _: u4 = 0 },
        mossy_cobblestone: packed struct(u4) { _: u4 = 0 },
        obsidian: packed struct(u4) { _: u4 = 0 },
        torch: packed struct(u4) { facing: TorchFacing, _: u1 = 0 },
        fire: packed struct(u4) { age: u4 },
        mob_spawner: packed struct(u4) { _: u4 = 0 },
        oak_stairs: packed struct(u4) { facing: StairFacing, half: Half, _: u1 = 0 },
        chest: packed struct(u4) { facing: HorizontalFacing, _: u1 = 0 },
        redstone_wire: packed struct(u4) { power: u4 },
        diamond_ore: packed struct(u4) { _: u4 = 0 },
        diamond_block: packed struct(u4) { _: u4 = 0 },
        crafting_table: packed struct(u4) { _: u4 = 0 },
        wheat: packed struct(u4) { age: u3, _: u1 = 0 },
        farmland: packed struct(u4) { moisture: u3, _: u1 = 0 },
        furnace: packed struct(u4) { facing: HorizontalFacing, _: u1 = 0 },
        lit_furnace: packed struct(u4) { facing: HorizontalFacing, _: u1 = 0 },
        standing_sign: packed struct(u4) { rotation: u4 },
        wooden_door: packed struct(u4) { other: packed union { when_upper: packed struct(u3) { hinge: DoorHinge, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: DoorFacing, open: bool } }, half: DoorHalf },
        ladder: packed struct(u4) { facing: HorizontalFacing, _: u1 = 0 },
        rail: packed struct(u4) { shape: CurveableRailShape },
        stone_stairs: packed struct(u4) { facing: StairFacing, half: Half, _: u1 = 0 },
        wall_sign: packed struct(u4) { facing: HorizontalFacing, _: u1 = 0 },
        lever: packed struct(u4) { facing: LeverFacing, powered: bool },
        stone_pressure_plate: packed struct(u4) { powered: bool, _: u3 = 0 },
        iron_door: packed struct(u4) { other: packed union { when_upper: packed struct(u3) { hinge: DoorHinge, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: DoorFacing, open: bool } }, half: DoorHalf },
        wooden_pressure_plate: packed struct(u4) { powered: bool, _: u3 = 0 },
        redstone_ore: packed struct(u4) { _: u4 = 0 },
        lit_redstone_ore: packed struct(u4) { _: u4 = 0 },
        unlit_redstone_torch: packed struct(u4) { facing: TorchFacing, _: u1 = 0 },
        redstone_torch: packed struct(u4) { facing: TorchFacing, _: u1 = 0 },
        stone_button: packed struct(u4) { facing: ButtonFacing, powered: bool },
        snow_layer: packed struct(u4) { layers: SnowLayers, _: u1 = 0 },
        ice: packed struct(u4) { _: u4 = 0 },
        snow: packed struct(u4) { _: u4 = 0 },
        cactus: packed struct(u4) { age: u4 },
        clay: packed struct(u4) { _: u4 = 0 },
        reeds: packed struct(u4) { age: u4 },
        jukebox: packed struct(u4) { has_record: bool, _: u3 = 0 },
        fence: packed struct(u4) { _: u4 = 0 },
        pumpkin: packed struct(u4) { facing: PackedHorizontalFacing, _: u2 = 0 },
        netherrack: packed struct(u4) { _: u4 = 0 },
        soul_sand: packed struct(u4) { _: u4 = 0 },
        glowstone: packed struct(u4) { _: u4 = 0 },
        portal: packed struct(u4) { axis: PortalAxis, _: u2 = 0 },
        lit_pumpkin: packed struct(u4) { facing: PackedHorizontalFacing, _: u2 = 0 },
        cake: packed struct(u4) { bites: CakeBites, _: u1 = 0 },
        unpowered_repeater: packed struct(u4) { facing: PackedHorizontalFacing, delay: RepeaterDelay },
        powered_repeater: packed struct(u4) { facing: PackedHorizontalFacing, delay: RepeaterDelay },
        stained_glass: packed struct(u4) { color: Color },
        trapdoor: packed struct(u4) { facing: TrapdoorFacing, open: bool, half: Half },
        monster_egg: packed struct(u4) { variant: MonsterEggVariant, _: u1 = 0 },
        stonebrick: packed struct(u4) { variant: StoneBrickVariant, _: u2 = 0 },
        brown_mushroom_block: packed struct(u4) { variant: MushroomBlockVariant },
        red_mushroom_block: packed struct(u4) { variant: MushroomBlockVariant },
        iron_bars: packed struct(u4) { _: u4 = 0 },
        glass_pane: packed struct(u4) { _: u4 = 0 },
        melon_block: packed struct(u4) { _: u4 = 0 },
        pumpkin_stem: packed struct(u4) { age: u3, _: u1 = 0 },
        melon_stem: packed struct(u4) { age: u3, _: u1 = 0 },
        vine: packed struct(u4) { south: bool, west: bool, north: bool, east: bool },
        fence_gate: packed struct(u4) { facing: PackedHorizontalFacing, open: bool, powered: bool },
        brick_stairs: packed struct(u4) { facing: StairFacing, half: Half, _: u1 = 0 },
        stone_brick_stairs: packed struct(u4) { facing: StairFacing, half: Half, _: u1 = 0 },
        mycelium: packed struct(u4) { _: u4 = 0 },
        waterlily: packed struct(u4) { _: u4 = 0 },
        nether_brick: packed struct(u4) { _: u4 = 0 },
        nether_brick_fence: packed struct(u4) { _: u4 = 0 },
        nether_brick_stairs: packed struct(u4) { facing: StairFacing, half: Half, _: u1 = 0 },
        nether_wart: packed struct(u4) { age: u2, _: u2 = 0 },
        enchanting_table: packed struct(u4) { _: u4 = 0 },
        brewing_stand: packed struct(u4) { has_bottle_0: bool, has_bottle_1: bool, has_bottle_2: bool, _: u1 = 0 },
        cauldron: packed struct(u4) { level: u2, _: u2 = 0 },
        end_portal: packed struct(u4) { _: u4 = 0 },
        end_portal_frame: packed struct(u4) { facing: PackedHorizontalFacing, eye: bool, _: u1 = 0 },
        end_stone: packed struct(u4) { _: u4 = 0 },
        dragon_egg: packed struct(u4) { _: u4 = 0 },
        redstone_lamp: packed struct(u4) { _: u4 = 0 },
        lit_redstone_lamp: packed struct(u4) { _: u4 = 0 },
        double_wooden_slab: packed struct(u4) { variant: WoodVariant, _: u1 = 0 },
        wooden_slab: packed struct(u4) { variant: WoodVariant, half: Half },
        cocoa: packed struct(u4) { facing: PackedHorizontalFacing, age: Age02 },
        sandstone_stairs: packed struct(u4) { facing: StairFacing, half: Half, _: u1 = 0 },
        emerald_ore: packed struct(u4) { _: u4 = 0 },
        ender_chest: packed struct(u4) { facing: HorizontalFacing, _: u1 = 0 },
        tripwire_hook: packed struct(u4) { facing: PackedHorizontalFacing, attached: bool, powered: bool },
        tripwire: packed struct(u4) { powered: bool, suspended: bool, attached: bool, disarmed: bool },
        emerald_block: packed struct(u4) { _: u4 = 0 },
        spruce_stairs: packed struct(u4) { facing: StairFacing, half: Half, _: u1 = 0 },
        birch_stairs: packed struct(u4) { facing: StairFacing, half: Half, _: u1 = 0 },
        jungle_stairs: packed struct(u4) { facing: StairFacing, half: Half, _: u1 = 0 },
        command_block: packed struct(u4) { triggered: bool, _: u3 = 0 },
        beacon: packed struct(u4) { _: u4 = 0 },
        cobblestone_wall: packed struct(u4) { variant: CobblestoneWallVariant, _: u3 = 0 },
        flower_pot: packed struct(u4) { legacy_data: u4 },
        carrots: packed struct(u4) { age: u3, _: u1 = 0 },
        potatoes: packed struct(u4) { age: u3, _: u1 = 0 },
        wooden_button: packed struct(u4) { facing: ButtonFacing, powered: bool },
        skull: packed struct(u4) { facing: Facing, nodrop: bool },
        anvil: packed struct(u4) { facing: PackedHorizontalFacing, damage: Age02 },
        trapped_chest: packed struct(u4) { facing: HorizontalFacing, _: u1 = 0 },
        light_weighted_pressure_plate: packed struct(u4) { power: u4 },
        heavy_weighted_pressure_plate: packed struct(u4) { power: u4 },
        unpowered_comparator: packed struct(u4) { facing: PackedHorizontalFacing, mode: ComparatorMode, powered: bool },
        powered_comparator: packed struct(u4) { facing: PackedHorizontalFacing, mode: ComparatorMode, powered: bool },
        daylight_detector: packed struct(u4) { power: u4 },
        redstone_block: packed struct(u4) { _: u4 = 0 },
        quartz_ore: packed struct(u4) { _: u4 = 0 },
        hopper: packed struct(u4) { facing: HopperFacing, enabled: bool },
        quartz_block: packed struct(u4) { variant: QuartzBlockVariant, _: u1 = 0 },
        quartz_stairs: packed struct(u4) { facing: StairFacing, half: Half, _: u1 = 0 },
        activator_rail: packed struct(u4) { shape: StraightRailShape, powered: bool },
        dropper: packed struct(u4) { facing: Facing, triggered: bool },
        stained_hardened_clay: packed struct(u4) { color: Color },
        stained_glass_pane: packed struct(u4) { color: Color },
        leaves2: packed struct(u4) { variant: WoodVariant2, _: u1 = 0, not_decayable: bool, check_decay: bool },
        log2: packed struct(u4) { variant: WoodVariant2, _: u1 = 0, axis: LogAxis },
        acacia_stairs: packed struct(u4) { facing: StairFacing, half: Half, _: u1 = 0 },
        dark_oak_stairs: packed struct(u4) { facing: StairFacing, half: Half, _: u1 = 0 },
        slime: packed struct(u4) { _: u4 = 0 },
        barrier: packed struct(u4) { _: u4 = 0 },
        iron_trapdoor: packed struct(u4) { facing: TrapdoorFacing, open: bool, half: Half },
        prismarine: packed struct(u4) { variant: PrismarineVariant, _: u2 = 0 },
        sea_lantern: packed struct(u4) { _: u4 = 0 },
        hay_block: packed struct(u4) { _: u2 = 0, axis: HayBlockAxis },
        carpet: packed struct(u4) { color: Color },
        hardened_clay: packed struct(u4) { _: u4 = 0 },
        coal_block: packed struct(u4) { _: u4 = 0 },
        packed_ice: packed struct(u4) { _: u4 = 0 },
        double_plant: packed struct(u4) { variant: DoublePlantVariant, half: DoublePlantHalf },
        standing_banner: packed struct(u4) { rotation: u4 },
        wall_banner: packed struct(u4) { facing: HorizontalFacing, _: u1 = 0 },
        daylight_detector_inverted: packed struct(u4) { power: u4 },
        red_sandstone: packed struct(u4) { variant: RedSandstoneVariant, _: u2 = 0 },
        red_sandstone_stairs: packed struct(u4) { facing: StairFacing, half: Half, _: u1 = 0 },
        double_stone_slab2: packed struct(u4) { seamless: bool, _: u3 = 0 },
        stone_slab2: packed struct(u4) { _: u3 = 0, half: Half },
        spruce_fence_gate: packed struct(u4) { facing: PackedHorizontalFacing, open: bool, powered: bool },
        birch_fence_gate: packed struct(u4) { facing: PackedHorizontalFacing, open: bool, powered: bool },
        jungle_fence_gate: packed struct(u4) { facing: PackedHorizontalFacing, open: bool, powered: bool },
        dark_oak_fence_gate: packed struct(u4) { facing: PackedHorizontalFacing, open: bool, powered: bool },
        acacia_fence_gate: packed struct(u4) { facing: PackedHorizontalFacing, open: bool, powered: bool },
        spruce_fence: packed struct(u4) { _: u4 = 0 },
        birch_fence: packed struct(u4) { _: u4 = 0 },
        jungle_fence: packed struct(u4) { _: u4 = 0 },
        dark_oak_fence: packed struct(u4) { _: u4 = 0 },
        acacia_fence: packed struct(u4) { _: u4 = 0 },
        spruce_door: packed struct(u4) { other: packed union { when_upper: packed struct(u3) { hinge: DoorHinge, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: DoorFacing, open: bool } }, half: DoorHalf },
        birch_door: packed struct(u4) { other: packed union { when_upper: packed struct(u3) { hinge: DoorHinge, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: DoorFacing, open: bool } }, half: DoorHalf },
        jungle_door: packed struct(u4) { other: packed union { when_upper: packed struct(u3) { hinge: DoorHinge, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: DoorFacing, open: bool } }, half: DoorHalf },
        acacia_door: packed struct(u4) { other: packed union { when_upper: packed struct(u3) { hinge: DoorHinge, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: DoorFacing, open: bool } }, half: DoorHalf },
        dark_oak_door: packed struct(u4) { other: packed union { when_upper: packed struct(u3) { hinge: DoorHinge, powered: bool, _: u1 = 0 }, when_lower: packed struct(u3) { facing: DoorFacing, open: bool } }, half: DoorHalf },
    };

    pub const CakeBites = enum(u3) { @"0", @"1", @"2", @"3", @"4", @"5", @"6" };
    pub const StairFacing = enum(u2) { east = 0, west = 1, south = 2, north = 3 };
    pub const Facing = enum(u3) { down = 0, up = 1, north = 2, south = 3, west = 4, east = 5 };
    pub const HorizontalFacing = enum(u3) { north = 2, south = 3, west = 4, east = 5 };
    pub const PackedHorizontalFacing = enum(u2) { south = 0, west = 1, north = 2, east = 3 };
    pub const DoorFacing = enum(u2) { east = 0, south = 1, west = 2, north = 3 };
    pub const TrapdoorFacing = enum(u2) { north = 0, south = 1, west = 2, east = 3 };
    pub const TorchFacing = enum(u3) { east = 1, west = 2, south = 3, north = 4, up = 5 };
    pub const ButtonFacing = enum(u3) { down = 0, east = 1, west = 2, south = 3, north = 4, up = 5 };
    pub const LeverFacing = enum(u3) { down_x, east, west, south, north, up_z, up_x, down_z };
    pub const HopperFacing = enum(u3) { down = 0, north = 2, south = 3, west = 4, east = 5 };
    pub const WoodVariant = enum(u3) { oak = 0, spruce = 1, birch = 2, jungle = 3, acacia = 4, dark_oak = 5 };
    pub const WoodVariant1 = enum(u2) { oak = 0, spruce = 1, birch = 2, jungle = 3 };
    pub const WoodVariant2 = enum(u1) { acacia = 0, dark_oak = 1 };
    pub const RepeaterDelay = enum(u2) { @"1" = 0, @"2" = 1, @"3" = 2, @"4" = 3 };
    pub const LogAxis = enum(u2) { y = 0, x = 1, z = 2, none = 3 };
    pub const Half = enum(u1) { bottom = 0, top = 1 };
    pub const StoneVariant = enum(u3) { stone = 0, granite = 1, smooth_granite = 2, diorite = 3, smooth_diorite = 4, andesite = 5, smooth_andesite = 6 };
    pub const DirtVariant = enum(u2) { dirt, coarse_dirt, podzol };
    pub const SandVariant = enum(u1) { sand, red_sand };
    pub const SandstoneVariant = enum(u2) { sandstone, chiseled_sandstone, smooth_sandstone };
    pub const RedSandstoneVariant = enum(u2) { red_sandstone, chiseled_red_sandstone, smooth_red_sandstone };
    pub const StraightRailShape = enum(u3) { north_south, east_west, ascending_east, ascending_west, ascending_north, ascending_south };
    pub const Color = enum(u4) { white, orange, magenta, light_blue, yellow, lime, pink, gray, silver, cyan, purple, blue, brown, green, red, black };
    pub const CurveableRailShape = enum(u4) { north_south, east_west, ascending_east, ascending_west, ascending_north, ascending_south, south_east, south_west, north_west, north_east };
    pub const QuartzBlockVariant = enum(u3) { default, chiseled, lines_x, lines_y, lines_z };
    pub const DoorHalf = enum(u1) { lower, upper };
    pub const DoorHinge = enum(u1) { left, right };
    pub const BedPart = enum(u1) { foot, head };
    pub const TallGrassVariant = enum(u2) { dead_bush, tall_grass, fern };
    pub const RedFlowerVariant = enum(u4) { poppy, blue_orchid, allium, houstonia, red_tulip, orange_tulip, white_tulip, pink_tulip, oxeye_daisy };
    pub const StoneSlabVariant = enum(u3) { stone, sandstone, wood_old, cobblestone, brick, stone_brick, nether_brick, quartz };
    pub const MonsterEggVariant = enum(u3) { stone, cobblestone, stone_brick, mossy_brick, cracked_brick, chiseled_brick };
    pub const PortalAxis = enum(u2) { x = 1, z = 2 };
    pub const StoneBrickVariant = enum(u2) { stonebrick, mossy_stonebrick, cracked_stonebrick, chiseled_stonebrick };
    pub const MushroomBlockVariant = enum(u4) { north_west, north, north_east, west, center, east, south_west, south, south_east, stem, all_inside, all_outside, all_stem };
    pub const CobblestoneWallVariant = enum(u1) { cobblestone, mossy_cobblestone };
    pub const PrismarineVariant = enum(u2) { prismarine, prismarine_bricks, dark_prismarine };
    pub const HayBlockAxis = enum(u2) { y, x, z };
    pub const DoublePlantVariant = enum(u3) { sunflower, syringa, double_grass, double_fern, double_rose, paeonia };
    pub const DoublePlantHalf = enum(u1) { lower, upper };
    pub const PistonType = enum(u1) { normal, sticky };
    pub const SnowLayers = enum(u3) { @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8" };
    pub const Age02 = enum(u2) { @"0", @"1", @"2" };
    pub const ComparatorMode = enum(u1) { compare, subtract };
};
