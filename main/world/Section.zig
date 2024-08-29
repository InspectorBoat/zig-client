const std = @import("std");
const root = @import("root");
const ConcreteBlockState = root.ConcreteBlockState;
const PackedNibbleArray = @import("util").PackedNibbleArray;

block_states: [4096]ConcreteBlockState,
block_light: PackedNibbleArray(4096),
sky_light: PackedNibbleArray(4096),
