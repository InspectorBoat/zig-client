nbt: ?Nbt.Compound,
item: Item,
size: i32,
metadata: i32,

pub fn dupe(allocator: std.mem.Allocator, maybe_item_stack: ?@This()) !?@This() {
    if (maybe_item_stack) |item_stack| if (item_stack.nbt) |nbt| return .{
        .item = item_stack.item,
        .size = item_stack.size,
        .metadata = item_stack.metadata,
        .nbt = try nbt.dupe(allocator),
    };

    return maybe_item_stack;
}

pub fn split(self: *@This(), allocator: std.mem.Allocator, items_to_split: i32) !@This() {
    var new_stack: @This() = (try dupe(allocator, self.*)).?;
    self.size -= items_to_split;
    new_stack.size = items_to_split;
    return new_stack;
}

/// Check for item, metadata, and nbt equality
pub fn canMerge(lhs: @This(), rhs: @This()) bool {
    if (lhs.item == rhs.item and lhs.metadata == rhs.metadata) {
        const lhs_has_nbt = lhs.nbt != null;
        const rhs_has_nbt = rhs.nbt != null;
        if (lhs_has_nbt and rhs_has_nbt) return Nbt.deepEquals(&.{ .compound = lhs.nbt.? }, &.{ .compound = rhs.nbt.? });
        return lhs_has_nbt == rhs_has_nbt;
    }
    return false;
}

pub fn deinit(allocator: std.mem.Allocator, maybe_item_stack: *?@This()) void {
    if (maybe_item_stack.*) |*item_stack| if (item_stack.nbt) |*nbt| nbt.deinit(allocator);
}

pub fn deepEquals(lhs: @This(), rhs: @This()) bool {
    return lhs.size == rhs.size and canMerge(lhs, rhs);
}

pub fn playerCanUse(self: @This(), block_pos: Vector3(i32), face: Direction, player: *const Entity.LocalPlayer) bool {
    _ = self;
    _ = block_pos;
    _ = face;
    _ = player;
    return true;
}

pub fn useOn(self: @This(), world: *World, player: *const Entity.LocalPlayer, block_pos: Vector3(i32), face: Direction, offset: Vector3(f64)) !bool {
    if (self.item.getBlock()) |block| {
        switch (self.item) {
            .stone_slab, .wooden_slab, .stone_slab2 => return self.useOnSlab(world, player, block_pos, face, offset, block),
            .snow_layer => return self.useOnSnow(world, player, block_pos, face, offset),
            else => return self.useOnBlock(world, player, block_pos, face, offset, block),
        }
    }

    switch (self.item) {
        .armor_stand => return false,
        .banner => return self.useOnSignLike(world, player, block_pos, face, .standing_banner),
        .bed => return true,
        .carrot, .potato, .wheat_seeds, .pumpkin_seeds, .melon_seeds, .nether_wart => return self.useOnCrop(world, player, block_pos, face),
        .dye => return self.useOnDye(world, player, block_pos, face, offset),
        .ender_eye => return self.useOnEnderEye(world, player, block_pos, face),
        .fire_charge => return true,
        .flint_and_steel => return self.useOnFlintAndSteel(world, player, block_pos, face),
        .fireworks => return false,
        .lead => return world.getBlock(block_pos).isFence(),
        .minecart, .chest_minecart, .furnace_minecart, .tnt_minecart, .hopper_minecart, .command_block_minecart => {
            return switch (world.getBlock(block_pos)) {
                .rail, .golden_rail, .detector_rail, .activator_rail => true,
                else => false,
            };
        },
        .record_13, .record_cat, .record_blocks, .record_chirp, .record_far, .record_mall, .record_mellohi, .record_stal, .record_strad, .record_ward, .record_11, .record_wait => return self.useOnMusicDisc(world, block_pos),
        .redstone => return self.useOnRedstone(world, player, block_pos, face),
        .string => return self.useOnBlock(world, player, block_pos, face, offset, .tripwire),
        .reeds => return self.useOnBlock(world, player, block_pos, face, offset, .reeds),
        .cake => return self.useOnBlock(world, player, block_pos, face, offset, .cake),
        .repeater => return self.useOnBlock(world, player, block_pos, face, offset, .unpowered_repeater),
        .brewing_stand => return self.useOnBlock(world, player, block_pos, face, offset, .brewing_stand),
        .cauldron => return self.useOnBlock(world, player, block_pos, face, offset, .cauldron),
        .flower_pot => return self.useOnBlock(world, player, block_pos, face, offset, .flower_pot),
        .comparator => return self.useOnBlock(world, player, block_pos, face, offset, .unpowered_comparator),
        .sign => return self.useOnSignLike(world, player, block_pos, face, .standing_sign),
        .skull => return self.useOnSkull(world, player, block_pos, face),
        .spawn_egg => return true,
        .wooden_hoe, .stone_hoe, .iron_hoe, .diamond_hoe, .golden_hoe => return self.useOnHoe(world, player, block_pos, face),
        inline .wooden_door, .spruce_door, .birch_door, .jungle_door, .acacia_door, .dark_oak_door, .iron_door => |door_item| return self.useOnDoor(world, player, block_pos, face, @field(Block, @tagName(door_item))),
        // TODO: fuckkkkkk this is so trivial but the client only decrements stack size if it predicts the painting/item can survive and that is TECHNICALLY OBSERVABLE
        .painting, .item_frame => return face.plane() != .vertical and self.playerCanUse(block_pos, face, player),
        else => return false,
    }
}

fn useOnBlock(self: @This(), world: *World, player: *const Entity.LocalPlayer, block_pos: Vector3(i32), face: Direction, offfset: Vector3(f64), block: Block) !bool {
    if (self.size == 0) return false;

    const existing_block = world.getBlock(block_pos);
    const placement_pos = if (!existing_block.getMaterial().isReplaceable()) block_pos.dir(face) else block_pos;
    if (!self.playerCanUse(placement_pos, face, player)) return false;
    if (!block.canBePlaced(world, placement_pos, face)) return false;
    const physical_state: Block.PhysicalState = .getPlacementState(
        block,
        self.metadata,
        world,
        player.getEyePos(),
        .fromYaw(player.base.rotation.yaw),
        placement_pos,
        face,
        offfset,
    );
    try world.setBlockState(.failing, placement_pos, physical_state);
    return true;
}

fn useOnCrop(self: @This(), world: *World, player: *const Entity.LocalPlayer, block_pos: Vector3(i32), face: Direction) !bool {
    if (face != .up) return false;
    if (!self.playerCanUse(block_pos.up(), face, player)) return false;
    const soil: Block = if (self.item == .nether_wart) .soul_sand else .farmland;
    if (world.getBlock(block_pos) != soil or world.getBlock(block_pos.up()) != .air) return false;

    const crop_state: Block.PhysicalState = switch (self.item) {
        .carrot => .{ .block = .carrots, .properties = .{ .carrots = .{ .age = 0 } } },
        .potato => .{ .block = .potatoes, .properties = .{ .potatoes = .{ .age = 0 } } },
        .wheat_seeds => .{ .block = .wheat, .properties = .{ .wheat = .{ .age = 0 } } },
        .pumpkin_seeds => .{ .block = .pumpkin_stem, .properties = .{ .pumpkin_stem = .{ .age = 0 } } },
        .melon_seeds => .{ .block = .melon_stem, .properties = .{ .melon_stem = .{ .age = 0 } } },
        .nether_wart => .{ .block = .nether_wart, .properties = .{ .nether_wart = .{ .age = 0 } } },
        else => unreachable,
    };
    try world.setBlockState(.failing, block_pos.up(), crop_state);
    return true;
}

fn canBoneMeal(world: *World, block_pos: Vector3(i32)) bool {
    const state = world.getBlockState(block_pos);
    return switch (state.block) {
        .wheat => state.properties.wheat.age < 7,
        .carrots => state.properties.carrots.age < 7,
        .potatoes => state.properties.potatoes.age < 7,
        .pumpkin_stem => state.properties.pumpkin_stem.age < 7,
        .melon_stem => state.properties.melon_stem.age < 7,

        .cocoa => @backingInt(state.properties.cocoa.age) < 2,
        .tallgrass => state.properties.tallgrass.variant != .dead_bush,
        .double_plant => blk: {
            const lower = if (state.properties.double_plant.half == .upper) world.getBlockState(block_pos.down()) else state;
            if (lower.block != .double_plant) break :blk false;
            const variant = lower.properties.double_plant.variant;
            break :blk variant != .double_grass and variant != .double_fern;
        },
        .grass, .sapling, .brown_mushroom, .red_mushroom => true,
        else => false,
    };
}

fn useOnDye(self: @This(), world: *World, player: *const Entity.LocalPlayer, block_pos: Vector3(i32), face: Direction, offset: Vector3(f64)) !bool {
    const target = block_pos.dir(face);
    if (!self.playerCanUse(target, face, player)) return false;

    const metadata = if (self.metadata < 0 or self.metadata >= 16) 0 else self.metadata;
    switch (metadata) {
        3 => {
            const state = world.getBlockState(block_pos);
            if (state.block != .log or state.properties.log.variant != .jungle) return false;
            if (face == .down or face == .up) return false;

            if (world.getBlock(target) == .air) {
                const placement_state: Block.PhysicalState = .getPlacementState(
                    .cocoa,
                    0,
                    world,
                    player.getEyePos(),
                    .fromYaw(player.base.rotation.yaw),
                    target,
                    face,
                    offset,
                );
                try world.setBlockState(.failing, target, placement_state);
            }
            return true;
        },
        15 => {
            const state = world.getBlockState(block_pos);
            return switch (state.block) {
                .wheat => state.properties.wheat.age < 7,
                .carrots => state.properties.carrots.age < 7,
                .potatoes => state.properties.potatoes.age < 7,
                .pumpkin_stem => state.properties.pumpkin_stem.age < 7,
                .melon_stem => state.properties.melon_stem.age < 7,

                .cocoa => @backingInt(state.properties.cocoa.age) < 2,
                .tallgrass => state.properties.tallgrass.variant != .dead_bush,
                .double_plant => blk: {
                    const lower = if (state.properties.double_plant.half == .upper) world.getBlockState(block_pos.down()) else state;
                    if (lower.block != .double_plant) break :blk false;
                    const variant = lower.properties.double_plant.variant;
                    break :blk variant != .double_grass and variant != .double_fern;
                },
                .grass, .sapling, .brown_mushroom, .red_mushroom => true,
                else => false,
            };
        },
        else => return false,
    }
}

fn useOnEnderEye(self: @This(), world: *World, player: *const Entity.LocalPlayer, block_pos: Vector3(i32), face: Direction) bool {
    if (!self.playerCanUse(block_pos.dir(face), face, player)) return false;
    const state = world.getBlockState(block_pos);
    return state.block == .end_portal_frame and !state.properties.end_portal_frame.eye;
}

fn useOnFlintAndSteel(self: @This(), world: *World, player: *const Entity.LocalPlayer, block_pos: Vector3(i32), face: Direction) !bool {
    const target = block_pos.dir(face);
    if (!self.playerCanUse(target, face, player)) return false;

    if (world.getBlock(target).getMaterial() == .air) {
        try world.setBlockState(.failing, target, .{
            .block = .fire,
            .properties = .{ .fire = .{ .age = 0 } },
        });
    }
    return true;
}

fn useOnHoe(self: @This(), world: *World, player: *const Entity.LocalPlayer, block_pos: Vector3(i32), face: Direction) bool {
    if (!self.playerCanUse(block_pos.dir(face), face, player)) return false;
    if (face == .down or world.getBlock(block_pos.up()).getMaterial() != .air) return false;

    const state = world.getBlockState(block_pos);
    return switch (state.block) {
        .grass => true,
        .dirt => state.properties.dirt.variant == .dirt or state.properties.dirt.variant == .coarse_dirt,
        else => false,
    };
}

fn useOnMusicDisc(self: @This(), world: *World, block_pos: Vector3(i32)) bool {
    _ = self;
    const state = world.getBlockState(block_pos);
    return state.block == .jukebox and !state.properties.jukebox.has_record;
}

fn useOnRedstone(self: @This(), world: *World, player: *const Entity.LocalPlayer, block_pos: Vector3(i32), face: Direction) !bool {
    const existing_block = world.getBlock(block_pos);
    const target = if (existing_block.getMaterial().isReplaceable()) block_pos else block_pos.dir(face);
    if (!self.playerCanUse(target, face, player)) return false;

    if (!Block.canBePlaced(.redstone_wire, world, target, face)) return false;

    try world.setBlockState(.failing, target, .{
        .block = .redstone_wire,
        .properties = .{ .redstone_wire = .{ .power = 0 } },
    });
    return true;
}

fn useOnSignLike(self: @This(), world: *World, player: *const Entity.LocalPlayer, block_pos: Vector3(i32), face: Direction, standing: Block) bool {
    if (face == .down) return false;
    if (!world.getBlock(block_pos).getMaterial().isSolid()) return false;

    const target = block_pos.dir(face);
    if (!self.playerCanUse(target, face, player)) return false;
    return standing.canBePlaced(world, target, face);
}

fn useOnSkull(self: @This(), world: *World, player: *const Entity.LocalPlayer, block_pos: Vector3(i32), face: Direction) bool {
    if (face == .down) return false;

    const clicked = world.getBlockState(block_pos);
    var target = block_pos;
    if (!clicked.block.getMaterial().isReplaceable()) {
        if (!clicked.block.getMaterial().isSolid()) return false;
        target = block_pos.dir(face);
    }

    if (!self.playerCanUse(target, face, player)) return false;
    return Block.canBePlaced(.skull, world, target, face);
}

fn useOnDoor(self: @This(), world: *World, player: *const Entity.LocalPlayer, block_pos: Vector3(i32), face: Direction, block: Block) !bool {
    if (face != .up) return false;

    const existing_block = world.getBlock(block_pos);
    const target = if (!existing_block.getMaterial().isReplaceable()) block_pos.dir(face) else block_pos;
    if (!self.playerCanUse(target, face, player)) return false;
    if (!block.canBePlaced(world, target, face)) return false;

    const facing: Direction = .fromYaw(player.base.rotation.yaw);
    const clockwise_pos = target.dir(switch (facing) {
        .north => .east,
        .east => .south,
        .south => .west,
        .west => .north,
        else => unreachable,
    });
    const counter_clockwise_pos = target.dir(switch (facing) {
        .north => .west,
        .west => .south,
        .south => .east,
        .east => .north,
        else => unreachable,
    });
    const clockwise_count = @as(u2, @intFromBool(world.getBlock(clockwise_pos).isSolid())) + @as(u2, @intFromBool(world.getBlock(clockwise_pos.up()).isSolid()));
    const counter_clockwise_count = @as(u2, @intFromBool(world.getBlock(counter_clockwise_pos).isSolid())) + @as(u2, @intFromBool(world.getBlock(counter_clockwise_pos.up()).isSolid()));
    const clockwise_door = world.getBlock(clockwise_pos) == block or world.getBlock(clockwise_pos.up()) == block;
    const counter_clockwise_door = world.getBlock(counter_clockwise_pos) == block or world.getBlock(counter_clockwise_pos.up()) == block;
    const right_hinge = (counter_clockwise_door and !clockwise_door) or clockwise_count > counter_clockwise_count;

    try world.setBlockState(.failing, target, .{ .block = block, .properties = .{ .wooden_door = .{ .other = .{ .when_lower = .{ .facing = facing.toAssert(Block.PhysicalState.DoorFacing), .open = false } }, .half = .lower } } });
    try world.setBlockState(.failing, target.up(), .{ .block = block, .properties = .{ .wooden_door = .{ .other = .{ .when_upper = .{ .hinge = if (right_hinge) .right else .left, .powered = false } }, .half = .upper } } });
    return true;
}

fn useOnSnow(self: @This(), world: *World, player: *const Entity.LocalPlayer, block_pos: Vector3(i32), face: Direction, offset: Vector3(f64)) !bool {
    if (self.size == 0) return false;

    var target = block_pos;
    var state = world.getBlockState(block_pos);
    if ((face != .up or state.block != .snow_layer) and !state.block.getMaterial().isReplaceable()) {
        target = block_pos.dir(face);
        state = world.getBlockState(target);
    }

    if (!self.playerCanUse(target, face, player)) return false;
    if (state.block == .snow_layer) {
        const layers: u3 = @backingInt(state.properties.snow_layer.layers);
        if (layers < 7) {
            var next = state;
            next.properties.snow_layer.layers = @fromBackingInt(@intCast(layers + 1));
            try world.setBlockState(.failing, target, next);
            return true;
        }
    }

    return self.useOnBlock(world, player, block_pos, face, offset, .snow_layer);
}

fn useOnSlab(self: @This(), world: *World, player: *const Entity.LocalPlayer, block_pos: Vector3(i32), face: Direction, offset: Vector3(f64), single: Block) !bool {
    if (self.size == 0) return false;
    if (!self.playerCanUse(block_pos.dir(face), face, player)) return false;

    const variant_metadata = slabVariantMetadata(single, self.metadata);
    const clicked = world.getBlockState(block_pos);
    if (clicked.block == single and slabVariant(clicked) == variant_metadata) {
        const half = clicked.properties.stone_slab.half;
        if ((face == .up and half == .bottom) or (face == .down and half == .top)) {
            try world.setBlockState(.failing, block_pos, doubleSlabState(single, variant_metadata));
            return true;
        }
    }

    const target = block_pos.dir(face);
    const target_state = world.getBlockState(target);
    if (target_state.block == single and slabVariant(target_state) == variant_metadata) {
        try world.setBlockState(.failing, target, doubleSlabState(single, variant_metadata));
        return true;
    }

    const existing_block = world.getBlock(block_pos);
    const placement_pos = if (!existing_block.getMaterial().isReplaceable()) block_pos.dir(face) else block_pos;
    if (!self.playerCanUse(placement_pos, face, player)) return false;
    if (!single.canBePlaced(world, placement_pos, face)) return false;

    const half: Block.PhysicalState.Half = if (face != .down and (face == .up or !(offset.y > 0.5))) .bottom else .top;
    try world.setBlockState(.failing, placement_pos, singleSlabState(single, variant_metadata, half));
    return true;
}

fn slabVariantMetadata(slab: Block, metadata: i32) u3 {
    const variant: u3 = @intCast(metadata & 7);
    return switch (slab) {
        .wooden_slab => if (variant > 5) 0 else variant,
        .stone_slab2 => 0,
        .stone_slab => variant,
        else => unreachable,
    };
}

fn slabVariant(state: Block.PhysicalState) u3 {
    return switch (state.block) {
        .stone_slab => @backingInt(state.properties.stone_slab.variant),
        .wooden_slab => @backingInt(state.properties.wooden_slab.variant),
        .stone_slab2 => 0,
        else => unreachable,
    };
}

fn singleSlabState(single: Block, variant: u3, half: Block.PhysicalState.Half) Block.PhysicalState {
    var state: Block.PhysicalState = .{ .block = single, .properties = @fromBackingInt(0) };
    switch (single) {
        .stone_slab => state.properties.stone_slab = .{ .variant = @fromBackingInt(@intCast(variant)), .half = half },
        .wooden_slab => state.properties.wooden_slab = .{ .variant = @fromBackingInt(@intCast(variant)), .half = half },
        .stone_slab2 => state.properties.stone_slab2 = .{ .half = half },
        else => unreachable,
    }
    return state;
}

fn doubleSlabState(single: Block, variant: u3) Block.PhysicalState {
    return switch (single) {
        .stone_slab => .{ .block = .double_stone_slab, .properties = .{ .double_stone_slab = .{ .variant = @fromBackingInt(variant), .seamless = false } } },
        .wooden_slab => .{ .block = .double_wooden_slab, .properties = .{ .double_wooden_slab = .{ .variant = @fromBackingInt(variant) } } },
        .stone_slab2 => .{ .block = .double_stone_slab2, .properties = .{ .double_stone_slab2 = .{ .seamless = false } } },
        else => unreachable,
    };
}

pub fn format(self: *const @This(), writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.print("{s}:{}", .{ @tagName(self.item), self.metadata });
    if (self.nbt) |nbt| try nbt.format(writer);
    if (self.size != 1) try writer.print("x{}", .{self.size});
}

const std = @import("std");

const main = @import("main");

const Block = main.Block;
const Direction = main.Direction;
const Entity = main.Entity;
const Item = main.Item;
const Nbt = main.Nbt;
const Vector3 = main.Vector3;
const World = main.World;
