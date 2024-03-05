const std = @import("std");
const BlockState = @import("../block/BlockState.zig");

block_states: [4096]BlockState,
block_light: std.PackedIntArray(u4, 4096),
sky_light: std.PackedIntArray(u4, 4096),
