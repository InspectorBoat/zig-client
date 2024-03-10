const std = @import("std");
const PackedStructArray = @import("../world/packed_struct_array.zig").PackedStructArray;
const FilteredBlockState = @import("../block/block.zig").FilteredBlockState;

block_states: PackedStructArray(FilteredBlockState, 4096),
block_light: std.PackedIntArray(u4, 4096),
sky_light: std.PackedIntArray(u4, 4096),
