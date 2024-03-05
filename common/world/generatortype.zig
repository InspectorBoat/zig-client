const std = @import("std");

pub const GeneratorType = enum {
    Default,
    Flat,
    LargeBiomes,
    Amplified,
    Customized,
    DebugAllBlockStates,
    Default_1_1,

    pub const keys = std.ComptimeStringMap(@This(), .{
        .{ "default", .Default },
        .{ "flat", .Flat },
        .{ "largeBiomes", .LargeBiomes },
        .{ "amplified", .Amplified },
        .{ "customized", .Customized },
        .{ "debug_all_block_states", .DebugAllBlockStates },
        .{ "default_1_1", .Default_1_1 },
    });
};
