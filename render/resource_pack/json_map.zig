pub fn JsonMap(Element: type) type {
    return struct {
        map: std.StringHashMapUnmanaged(Element),

        pub fn jsonParse(arena: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) !@This() {
            var map: std.StringHashMapUnmanaged(Element) = .empty;

            if (.object_begin != try source.next()) return error.UnexpectedToken;

            while (true) {
                switch (try source.nextAllocMax(arena, .alloc_if_needed, options.max_value_len.?)) {
                    inline .string, .allocated_string => |slice| {
                        const key = try arena.dupe(u8, slice);

                        if (map.contains(key)) switch (options.duplicate_field_behavior) {
                            .@"error" => return error.DuplicateField,
                            // discard the value and continue
                            .use_first => {
                                _ = std.json.innerParse(Element, arena, source, options) catch |err| return err;
                                continue;
                            },
                            .use_last => {},
                        };

                        const value = try std.json.innerParse(Element, arena, source, options);
                        try map.put(arena, key, value);
                    },
                    .object_end => break,
                    else => return error.UnexpectedToken,
                }
            }

            return .{ .map = map };
        }
    };
}

const std = @import("std");
