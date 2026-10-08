const std = @import("std");
const root = @import("root");
const PhysicalBlockState = root.PhysicalBlockState;
const PackedNibbleArray = @import("util").PackedNibbleArray;

block_states: [16 * 16 * 16]PhysicalBlockState,
block_light: PackedNibbleArray(16, 16, 16),
sky_light: PackedNibbleArray(16, 16, 16),
