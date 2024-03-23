const std = @import("std");
const PackedStructArray = @import("../world/packed_struct_array.zig").PackedStructArray;
const ConcreteBlockState = @import("../block/block.zig").ConcreteBlockState;

block_states: [4096]ConcreteBlockState,
block_light: std.PackedIntArray(u4, 4096),
sky_light: std.PackedIntArray(u4, 4096),
