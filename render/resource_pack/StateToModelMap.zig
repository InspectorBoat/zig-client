/// A resource pack's `blockstates/<name>.json`
/// This is how the game figures out what model to use for a given virtual block state.
/// Given a block state, it produces a key based on the block state's properties, then
/// looks in the StateToModelMap file named after the block. For example, for the block
/// state acacia_fence[north=true,west=false,east=true,south=true], it would look in
/// the StateToModelMap produced by blockstates/acacia_fence.json for the key
/// "east=true,north=true,south=true,west=false"
///
/// Keys are the block state's properties flattened into a comma-joined
/// `name=value` list, sorted alphabetically by property name. Not all
/// properties are always used. For example, leaves/leaves2 drop the
/// check_decayable and decayable properties.
///
/// Some properties are also consumed instead to figure out what StateToModelMap
/// to index into. For example, instead of looking in blockstates/carpet.json,
/// `carpet` uses the `color` property, and looks in `blockstates/<color>_carpet.json`.
/// The `color` property is then dropped from the state key.
///
/// A value is either a single variant (`single`) or an array of them (`multi`).
///
/// A `ModelVariant` is a reference to a model plus orientation. uvlock controls
/// whether uvs are rotated along with the geometry, or stay fixed in space.
/// `model` is a bare name. "redstone_ne" resolves to `models/block/redstone_ne.json`.
const std = @import("std");
const JsonMap = @import("json_map.zig").JsonMap;

variants: JsonMap(ModelVariants),

const ModelVariants = union(enum) {
    multi: []const ModelVariant,
    single: ModelVariant,

    pub fn jsonParse(arena: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !@This() {
        switch (try source.peekNextTokenType()) {
            .array_begin => {
                _ = try source.next();

                var model_variants: std.ArrayList(ModelVariant) = .empty;
                while (true) {
                    switch (try source.peekNextTokenType()) {
                        .array_end => {
                            _ = try source.next();
                            break;
                        },
                        else => {},
                    }

                    try model_variants.append(arena, try std.json.innerParse(ModelVariant, arena, source, options));
                }

                return .{ .multi = try model_variants.toOwnedSlice(arena) };
            },
            else => return .{ .single = try std.json.innerParse(ModelVariant, arena, source, options) },
        }
    }
};

pub const ModelVariant = struct {
    model: []const u8,
    y: Angle = .@"0",
    x: Angle = .@"0",
    uvlock: bool = false,

    pub const Angle = enum { @"0", @"90", @"180", @"270" };
};
