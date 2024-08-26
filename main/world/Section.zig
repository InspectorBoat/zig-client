const std = @import("std");
const PackedStructArray = @import("../world/packed_struct_array.zig").PackedStructArray;
const ConcreteBlockState = @import("../block/block.zig").ConcreteBlockState;
const PackedNibbleArray = @import("util").PackedNibbleArray;

block_states: [4096]ConcreteBlockState,
block_light: PackedNibbleArray(4096),
sky_light: PackedNibbleArray(4096),
