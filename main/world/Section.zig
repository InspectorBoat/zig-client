const main = @import("main");
const PackedNibbleArray = @import("util").PackedNibbleArray;

const Block = main.Block;

block_states: [16 * 16 * 16]Block.PhysicalState,
block_light: PackedNibbleArray(16, 16, 16),
sky_light: PackedNibbleArray(16, 16, 16),
