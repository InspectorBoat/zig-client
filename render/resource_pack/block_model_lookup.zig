const std = @import("std");
const root = @import("root").block;
const Block = root.Block;
const ResolvedBlockModel = @import("ResolvedBlockModel.zig");
const StateToModelMap = @import("StateToModelMap.zig");

pub fn createLookupTable(
    gpa: std.mem.Allocator,
    resolved_block_models: std.StringHashMapUnmanaged(ResolvedBlockModel),
    state_to_model_maps: std.StringHashMapUnmanaged(StateToModelMap),
) !std.AutoHashMapUnmanaged(Block.VirtualState, ResolvedBlockModel) {
    var lookup_table: std.AutoHashMapUnmanaged(Block.VirtualState, ResolvedBlockModel) = .empty;
    @setEvalBranchQuota(1000000);
    var total: usize = 0;
    inline for (std.enums.values(Block)) |block| {
        const all_states = allValues(@FieldType(Block.VirtualState, @tagName(block)));
        for (all_states) |properties| {
            const map_name = getNameString(gpa, block, properties) catch |e| switch (e) {
                error.NoModel => continue,
                else => return e,
            };
            defer gpa.free(map_name);
            const properties_key = try getPropertiesString(gpa, block, properties);
            defer gpa.free(properties_key);

            std.log.scoped(.resource_pack_states).debug("{s} {s}", .{ map_name, properties_key });

            const state_to_model_map = state_to_model_maps.get(map_name) orelse return error.MapNotFound;
            const model_variants = state_to_model_map.variants.map.get(properties_key) orelse return error.VariantNotFound;
            var resolved_block_model = switch (model_variants) {
                .single => |single| resolved_block_models.get(single.model) orelse return error.ModelNotFound,
                .multi => |multi| resolved_block_models.get(multi[0].model) orelse return error.ModelNotFound,
            };
            resolved_block_model.elements = try gpa.dupe(ResolvedBlockModel.Element, resolved_block_model.elements);

            // dirty UB hack alert
            const state = @unionInit(Block.VirtualState, @tagName(block), properties);
            try lookup_table.put(gpa, state, resolved_block_model);

            total += 1;
        }
    }
    std.log.scoped(.resource_pack_states).debug("{} states with models", .{total});
    return lookup_table;
}

pub fn getNameString(
    gpa: std.mem.Allocator,
    comptime block: Block,
    properties: @FieldType(Block.VirtualState, @tagName(block)),
) (error{NoModel} || std.mem.Allocator.Error)![]const u8 {
    var string: std.ArrayList(u8) = .empty;
    errdefer string.deinit(gpa);
    switch (block) {
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

        .flower_pot, //todo
        .quartz_block, //todo
        => return error.NoModel,

        .deadbush => try string.appendSlice(gpa, "dead_bush"),
        .yellow_flower => try string.appendSlice(gpa, "dandelion"),
        .double_stone_slab2 => try string.appendSlice(gpa, "red_sandstone_double_slab"),
        .stone_slab2 => try string.appendSlice(gpa, "red_sandstone_slab"),

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
        => try string.appendSlice(gpa, @tagName(properties.variant)),

        .stained_hardened_clay,
        .stained_glass,
        .stained_glass_pane,
        .wool,
        .carpet,
        => try string.print(gpa, "{s}_{s}", .{ @tagName(properties.color), @tagName(block) }),

        .planks,
        .sapling,
        .monster_egg,
        => try string.print(gpa, "{s}_{s}", .{ @tagName(properties.variant), @tagName(block) }),

        .log, .log2 => try string.print(gpa, "{s}_log", .{@tagName(properties.variant)}),
        .leaves, .leaves2 => try string.print(gpa, "{s}_leaves", .{@tagName(properties.variant)}),
        .double_wooden_slab, .double_stone_slab => try string.print(gpa, "{s}_double_slab", .{@tagName(properties.variant)}),
        .wooden_slab, .stone_slab => try string.print(gpa, "{s}_slab", .{@tagName(properties.variant)}),
        .cobblestone_wall => try string.print(gpa, "{s}_wall", .{@tagName(properties.variant)}),

        else => try string.appendSlice(gpa, @tagName(block)),
    }
    return try string.toOwnedSlice(gpa);
}

pub fn getPropertiesString(
    gpa: std.mem.Allocator,
    comptime block: Block,
    properties: @FieldType(Block.VirtualState, @tagName(block)),
) ![]const u8 {
    var string: std.ArrayList(u8) = .empty;
    errdefer string.deinit(gpa);

    const field_names_const = @typeInfo(@FieldType(Block.VirtualState, @tagName(block))).@"struct".field_names;
    comptime var field_names = field_names_const[0..field_names_const.len].*;
    comptime std.mem.sort([:0]const u8, &field_names, {}, struct {
        fn lessThan(_: void, lhs: [:0]const u8, rhs: [:0]const u8) bool {
            return std.mem.lessThanZ(u8, lhs, rhs);
        }
    }.lessThan);
    inline for (field_names) |field_name| {
        if (!skipField(block, properties, field_name)) {
            if (string.items.len > 0) try string.append(gpa, ',');
            try string.appendSlice(gpa, field_name);
            try string.append(gpa, '=');
            const property = @field(properties, field_name);
            switch (@typeInfo(@TypeOf(property))) {
                .@"enum" => try string.appendSlice(gpa, @tagName(property)),
                .int => try string.print(gpa, "{}", .{property}),
                .bool => try string.appendSlice(gpa, if (property) "true" else "false"),
                else => unreachable,
            }
        }
    }
    if (string.items.len == 0) try string.appendSlice(gpa, "normal");
    return string.toOwnedSlice(gpa);
}

pub fn skipField(comptime block: Block, properties: @FieldType(Block.VirtualState, @tagName(block)), comptime field_name: []const u8) bool {
    if (block == .dirt and properties.variant != .podzol and std.mem.eql(u8, field_name, "snowy")) return true;
    if ((block == .leaves or block == .leaves2) and (std.mem.eql(u8, field_name, "not_decayable") or std.mem.eql(u8, field_name, "check_decay"))) return true;
    if ((block == .double_stone_slab or block == .double_stone_slab2) and std.mem.eql(u8, field_name, "seamless")) return true;
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

// how many distinct values can a field of type T hold
fn count(T: type) usize {
    return switch (@typeInfo(T)) {
        .int => @as(usize, 1) << @typeInfo(T).int.bits,
        .@"enum" => @typeInfo(T).@"enum".field_names.len,
        .bool => 2,
        else => @compileError("unsupported field type"),
    };
}

// the ith of those values
fn nth(T: type, i: comptime_int) T {
    return switch (@typeInfo(T)) {
        .int => @intCast(i),
        .@"enum" => |e| @fromBackingInt(e.field_values[i]),
        .bool => i == 1,
        else => @compileError("unsupported field type"),
    };
}

fn allValues(T: type) []const T {
    return comptime blk: {
        const field_names = @typeInfo(T).@"struct".field_names;
        const field_types = @typeInfo(T).@"struct".field_types;
        var total = 1;
        for (field_types) |@"type"| total *= count(@"type");

        var values: [total]T = undefined;
        for (0..total) |i| {
            var rem = i;
            for (field_names, field_types) |name, @"type"| {
                @field(values[i], name) = nth(@"type", rem % count(@"type"));
                rem /= count(@"type");
            }
        }
        const values_const = values;
        break :blk &values_const;
    };
}
