pub const BlockStateMap = CustomMap(Block.VirtualState, BakedModel);

/// Create a lookup table mapping from Block.VirtualState -> BakedModel
pub fn createBlockStateToModelTable(
    gpa: std.mem.Allocator,
    textures: std.array_hash_map.String(ImageError!zigimg.Image),
    resolved_models: std.array_hash_map.String(ModelError!ResolvedModel),
    state_to_model_maps: std.array_hash_map.String(StateError!StateToModelMap),
) !BlockStateMap {
    @setRuntimeSafety(false);

    var lookup_table: BlockStateMap = try .init(gpa, 8192 * 2);
    @setEvalBranchQuota(1000000);
    inline for (std.enums.values(Block)) |block| {
        try blockToModel(gpa, block, &lookup_table, textures, resolved_models, state_to_model_maps);
    }
    lookup_table.logDiagnostics();
    return lookup_table;
}

noinline fn blockToModel(
    gpa: std.mem.Allocator,
    comptime block: Block,
    lookup_table: *BlockStateMap,
    textures: std.array_hash_map.String(ImageError!zigimg.Image),
    resolved_models: std.array_hash_map.String(ModelError!ResolvedModel),
    state_to_model_maps: std.array_hash_map.String(StateError!StateToModelMap),
) !void {
    for (allValues(@FieldType(Block.VirtualState.Properties, @tagName(block)))) |properties| {
        const baked_model: BakedModel = stateToModel(gpa, block, properties, textures, resolved_models, state_to_model_maps) catch .{
            .faces = &.{},
        };
        lookup_table.put(
            .{ .block = block, .properties = @unionInit(Block.VirtualState.Properties, @tagName(block), properties) },
            baked_model,
        );
    }
}

noinline fn stateToModel(
    gpa: std.mem.Allocator,
    comptime block: Block,
    properties: @FieldType(Block.VirtualState.Properties, @tagName(block)),
    textures: std.array_hash_map.String(ImageError!zigimg.Image),
    resolved_models: std.array_hash_map.String(ModelError!ResolvedModel),
    state_to_model_maps: std.array_hash_map.String(StateError!StateToModelMap),
) !BakedModel {
    var block_name_buffer: [128]u8, var properties_buffer: [128]u8 = .{ undefined, undefined };

    const block_name_key = try getNameString(&block_name_buffer, block, properties);
    const properties_key = getPropertiesString(&properties_buffer, block, properties);

    const state_to_model_map = state_to_model_maps.get(block_name_key) orelse {
        std.log.scoped(.resource_pack).err("{s} uses missing blockstate to model file", .{block_name_key});
        return error.MissingBlockstateModelFile;
    } catch |e| {
        std.log.scoped(.resource_pack).err("{s} uses broken blockstate to model file ({})", .{ block_name_key, e });
        return e;
    };
    const model_variants = state_to_model_map.variants.map.get(properties_key) orelse {
        std.log.scoped(.resource_pack).err("no variant found for {s}:[{s}]", .{ block_name_key, properties_key });
        return error.MissingVariant;
    };
    const model_variant = switch (model_variants) {
        .single => |single| single,
        // TODO: support this
        .multi => |multi| multi[0],
    };

    var model_name_buffer: [128]u8 = undefined;
    const model_name = std.mem.print(&model_name_buffer, "block/{s}", .{model_variant.model}) catch unreachable;

    const resolved_model = resolved_models.get(model_name) orelse {
        std.log.scoped(.resource_pack).err("{s}:[{s}] uses missing model {s}", .{ block_name_key, properties_key, model_name });
        return error.MissingModel;
    } catch |e| {
        std.log.scoped(.resource_pack).err("{s}:[{s}] uses broken model {s} ({})", .{ block_name_key, properties_key, model_name, e });
        return e;
    };

    return try .bake(gpa, textures, resolved_model, model_variant.x, model_variant.y, model_variant.uvlock);
}

pub fn getNameString(
    scratch_buffer: []u8,
    comptime block: Block,
    properties: @FieldType(Block.VirtualState.Properties, @tagName(block)),
) error{NoModel}![]const u8 {
    @setRuntimeSafety(false);
    return switch (block) {
        .air,
        .flowing_water,
        .water,
        .flowing_lava,
        .lava,
        .piston_extension,
        .chest,
        .trapped_chest,
        .ender_chest,
        .standing_sign,
        .wall_sign,
        .standing_banner,
        .wall_banner,
        .skull,
        .end_portal,
        .barrier,

        .flower_pot, // todo
        => error.NoModel,

        .deadbush => "dead_bush",
        .yellow_flower => "dandelion",
        .double_stone_slab2 => "red_sandstone_double_slab",
        .stone_slab2 => "red_sandstone_slab",

        .stone,
        .sand,
        .prismarine,
        .stonebrick,
        .double_plant,
        .dirt,
        .red_flower,
        .red_sandstone,
        .sandstone,
        .tallgrass,
        => @tagName(properties.variant),

        .stained_hardened_clay,
        .stained_glass,
        .stained_glass_pane,
        .wool,
        .carpet,
        => std.mem.print(scratch_buffer, "{s}_{s}", .{ @tagName(properties.color), @tagName(block) }) catch unreachable,

        .planks,
        .sapling,
        .monster_egg,
        => std.mem.print(scratch_buffer, "{s}_{s}", .{ @tagName(properties.variant), @tagName(block) }) catch unreachable,

        .log, .log2 => std.mem.print(scratch_buffer, "{s}_log", .{@tagName(properties.variant)}) catch unreachable,
        .leaves, .leaves2 => std.mem.print(scratch_buffer, "{s}_leaves", .{@tagName(properties.variant)}) catch unreachable,
        .double_wooden_slab, .double_stone_slab => std.mem.print(scratch_buffer, "{s}_double_slab", .{@tagName(properties.variant)}) catch unreachable,
        .wooden_slab, .stone_slab => std.mem.print(scratch_buffer, "{s}_slab", .{@tagName(properties.variant)}) catch unreachable,
        .cobblestone_wall => std.mem.print(scratch_buffer, "{s}_wall", .{@tagName(properties.variant)}) catch unreachable,

        .quartz_block => switch (properties.variant) {
            .default => "quartz_block",
            .chiseled => "chiseled_quartz_block",
            .lines_x, .lines_y, .lines_z => "quartz_column",
        },

        else => @tagName(block),
    };
}

pub fn getPropertiesString(
    scratch_buffer: []u8,
    comptime block: Block,
    properties: @FieldType(Block.VirtualState.Properties, @tagName(block)),
) []const u8 {
    if (block == .quartz_block) {
        return switch (properties.variant) {
            .default, .chiseled => "normal",
            .lines_x => "axis=x",
            .lines_y => "axis=y",
            .lines_z => "axis=z",
        };
    }

    const field_names_const = @typeInfo(@FieldType(Block.VirtualState.Properties, @tagName(block))).@"struct".field_names;
    comptime var field_names = field_names_const[0..field_names_const.len].*;
    comptime std.mem.sort([:0]const u8, &field_names, {}, struct {
        fn lessThan(_: void, lhs: [:0]const u8, rhs: [:0]const u8) bool {
            return std.mem.lessThanZ(u8, lhs, rhs);
        }
    }.lessThan);

    var string: std.ArrayList(u8) = .initBuffer(scratch_buffer);

    // TODO: seamless slabs
    inline for (field_names) |field_name| {
        if (!skipField(block, field_name, properties)) {
            if (string.items.len > 0) string.appendAssumeCapacity(',');
            string.appendSliceAssumeCapacity(field_name);
            string.appendAssumeCapacity('=');

            const property = @field(properties, field_name);

            switch (@typeInfo(@TypeOf(property))) {
                .@"enum" => string.appendSliceAssumeCapacity(@tagName(property)),
                .int, .bool => string.printAssumeCapacity("{}", .{property}),
                else => unreachable,
            }
        }
    }
    if (string.items.len == 0) return "normal";
    return string.items;
}

pub fn skipField(comptime block: Block, comptime field_name: []const u8, properties: @FieldType(Block.VirtualState.Properties, @tagName(block))) bool {
    if (field_name[0] == '_') return true;

    if (block == .dirt) if (properties.variant != .podzol and std.mem.eql(u8, field_name, "snowy")) return true;
    if (block == .leaves or block == .leaves2) if (std.mem.eql(u8, field_name, "not_decayable") or std.mem.eql(u8, field_name, "check_decay")) return true;
    if (block == .double_stone_slab or block == .double_stone_slab2) if (std.mem.eql(u8, field_name, "seamless")) return true;

    switch (block) {
        .bed => if (std.mem.eql(u8, field_name, "occupied")) return true,

        .tnt => if (std.mem.eql(u8, field_name, "explode")) return true,

        .fire => if (std.mem.eql(u8, field_name, "age")) return true,

        .redstone_wire => if (std.mem.eql(u8, field_name, "power")) return true,

        .flower_pot => if (std.mem.eql(u8, field_name, "legacy_data")) return true,

        .jukebox => if (std.mem.eql(u8, field_name, "has_record")) return true,

        .cactus, .reeds => if (std.mem.eql(u8, field_name, "age")) return true,

        .pumpkin_stem, .melon_stem => if (properties.facing != .up and std.mem.eql(u8, field_name, "age")) return true,

        .tripwire => if (std.mem.eql(u8, field_name, "powered") or std.mem.eql(u8, field_name, "disarmed")) return true,

        .hopper => if (std.mem.eql(u8, field_name, "enabled")) return true,

        .wooden_door,
        .spruce_door,
        .birch_door,
        .jungle_door,
        .acacia_door,
        .dark_oak_door,
        .iron_door,
        .fence_gate,
        .spruce_fence_gate,
        .birch_fence_gate,
        .jungle_fence_gate,
        .dark_oak_fence_gate,
        .acacia_fence_gate,
        => if (std.mem.eql(u8, field_name, "powered")) return true,

        .dispenser,
        .dropper,
        .command_block,
        => if (std.mem.eql(u8, field_name, "triggered")) return true,

        .stained_hardened_clay,
        .stained_glass,
        .stained_glass_pane,
        .wool,
        .carpet,
        => if (std.mem.eql(u8, field_name, "color")) return true,

        .stone,
        .sand,
        .prismarine,
        .stonebrick,
        .double_plant,
        .dirt,
        .red_flower,
        .red_sandstone,
        .sandstone,
        .tallgrass,
        .planks,
        .sapling,
        .monster_egg,
        .log,
        .log2,
        .leaves,
        .leaves2,
        .double_wooden_slab,
        .double_stone_slab,
        .wooden_slab,
        .stone_slab,
        .cobblestone_wall,
        => if (std.mem.eql(u8, field_name, "variant")) return true,

        else => {},
    }

    return false;
}

const std = @import("std");

const main = @import("main");
const render = @import("render");
const zigimg = @import("zigimg");
const allValues = @import("util").allValues;

pub const ModelTemplate = @import("ModelTemplate.zig");
pub const StateToModelMap = @import("StateToModelMap.zig");

const Block = main.Block;
const Direction = main.Direction;
const Vector3 = main.Vector3;
const Renderer = render.Renderer;
const BakedModel = render.resource_pack.BakedModel;
const ImageError = render.resource_pack.ImageError;
const ModelError = render.resource_pack.ModelError;
const ResolvedModel = render.resource_pack.ResolvedModel;
const StateError = render.resource_pack.StateError;

fn CustomMap(
    comptime K: type,
    comptime V: type,
) type {
    return struct {
        values: [*]V,
        keys: [*]K,
        capacity: u32,
        size: u32,

        // yes i know this is undefined behavior dont worry about it
        pub const empty_key: K = @fromBackingInt(std.math.maxInt(u20));

        // so we can read past the end without having to wrap
        pub const bonus_capacity: usize = 32;

        pub fn deinit(self: *@This(), gpa: std.mem.Allocator) void {
            const key_align = if (@sizeOf(K) == 0) 1 else @alignOf(K);
            const val_align = if (@sizeOf(V) == 0) 1 else @alignOf(V);
            const max_align: std.mem.Alignment = comptime .fromByteUnits(@max(key_align, val_align));

            const keys_start: usize = 0;
            const keys_end: usize = keys_start + (self.capacity + bonus_capacity) * @sizeOf(K);

            const vals_start: usize = std.mem.alignForward(usize, keys_end, val_align);
            const vals_end: usize = vals_start + (self.capacity + bonus_capacity) * @sizeOf(V);

            const total_size = max_align.forward(vals_end);

            const key_ptr: [*]align(max_align.toByteUnits()) u8 = @ptrCast(@alignCast(self.keys));
            const slice_ptr = key_ptr - keys_start;
            gpa.free(slice_ptr[0..total_size]);
            self.* = undefined;
        }

        pub fn init(gpa: std.mem.Allocator, capacity: u32) std.mem.Allocator.Error!@This() {
            std.debug.assert(std.math.isPowerOfTwo(capacity));

            const key_align = if (@sizeOf(K) == 0) 1 else @alignOf(K);
            const val_align = if (@sizeOf(V) == 0) 1 else @alignOf(V);
            const max_align: std.mem.Alignment = comptime .fromByteUnits(@max(key_align, val_align));

            const real_capacity = capacity + bonus_capacity;

            const keys_start: usize = 0;
            const keys_end: usize = keys_start + real_capacity * @sizeOf(K);

            const vals_start: usize = std.mem.alignForward(usize, keys_end, val_align);
            const vals_end: usize = vals_start + real_capacity * @sizeOf(V);

            const total_size = max_align.forward(vals_end);

            const slice = try gpa.alignedAlloc(u8, max_align, total_size);

            const keys: [*]K = @ptrCast(@alignCast(slice.ptr + keys_start));
            const values: [*]V = @ptrCast(@alignCast(slice.ptr + vals_start));

            @memset(keys[0..real_capacity], empty_key);

            return .{
                .values = values,
                .keys = keys,
                .size = 0,
                .capacity = capacity,
            };
        }

        /// Reports how far keys have been displaced from their home slot by collisions.
        pub fn logDiagnostics(self: @This()) void {
            const mask: u32 = self.capacity - 1;

            var count: usize = 0;
            var total_displacement: usize = 0;
            var min_displacement: usize = std.math.maxInt(usize);
            var max_displacement: usize = 0;

            for (self.keys[0 .. self.capacity + bonus_capacity], 0..) |key, idx| {
                if (key == empty_key) continue;

                const home_idx: usize = hash(key) & mask;
                const displacement = idx - home_idx;

                count += 1;
                total_displacement += displacement;
                min_displacement = @min(min_displacement, displacement);
                max_displacement = @max(max_displacement, displacement);
            }

            if (count == 0) {
                std.log.scoped(.resource_pack).info("hashmap diagnostics: empty", .{});
                return;
            }

            const average_displacement = @as(f64, @floatFromInt(total_displacement)) / @as(f64, @floatFromInt(count));
            std.log.scoped(.resource_pack).info(
                "hashmap diagnostics: {} keys, average displacement {d:.2}, minimum {}, maximum {}",
                .{ count, average_displacement, min_displacement, max_displacement },
            );
        }

        pub fn hash(key: K) u32 {
            // Computationally easy, spectrally good multipliers for congruential pseudorandom number generators
            // https://arxiv.org/html/2001.05304v1
            const backing: u32 = @backingInt(key);
            return (backing *% 1870261802) >> 18;
        }

        pub inline fn getIndex(self: @This(), key: K) ?usize {
            std.debug.assert(self.size != 0);

            const mask: u32 = self.capacity - 1;
            var idx: usize = hash(key) & mask;

            while (true) : (idx += 1) {
                const key_at = self.keys[idx];
                if (key_at == empty_key) return null;
                if (key_at == key) return idx;
            }
        }

        /// clobbering not allowed
        pub fn put(self: *@This(), key: K, value: V) void {
            std.debug.assert(self.size < self.capacity);

            const mask: u32 = self.capacity - 1;
            var idx: usize = hash(key) & mask;
            while (true) : (idx += 1) {
                const key_at = self.keys[idx];
                if (key_at == empty_key) break;
                if (key_at == key) unreachable;

                std.debug.assert(idx < self.capacity + bonus_capacity);
            }

            self.keys[idx] = key;
            self.values[idx] = value;
            self.size += 1;
        }

        pub fn getPtr(self: @This(), key: K) ?*V {
            return if (self.getIndex(key)) |idx| &self.values[idx] else null;
        }

        pub fn get(self: @This(), key: K) ?V {
            return if (self.getIndex(key)) |idx| self.values[idx] else null;
        }

        pub fn contains(self: @This(), key: K) bool {
            return self.getIndex(key) != null;
        }
    };
}
