const std = @import("std");
const root = @import("root");
const PhysicalBlockState = root.PhysicalBlockState;
const PackedNibbleArray = @import("util").PackedNibbleArray;

block_states: [4096]PhysicalBlockState,
block_light: PackedNibbleArray(4096),
sky_light: PackedNibbleArray(4096),
