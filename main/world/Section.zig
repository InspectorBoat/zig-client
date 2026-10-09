const std = @import("std");
const root = @import("root");
const Block = root.Block;
const PackedNibbleArray = @import("util").PackedNibbleArray;

block_states: [16 * 16 * 16]Block.PhysicalState,
block_light: PackedNibbleArray(16, 16, 16),
sky_light: PackedNibbleArray(16, 16, 16),
