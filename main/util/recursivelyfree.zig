const std = @import("std");

/// Special_cases must be an array, shaped like the following:
/// ```zig
/// []type {
///     struct {
///         pub const Type = T,
///         pub fn free(value: Type, allocator: std.mem.Allocator) void {
///             // free value here
///         }
///     }
/// }
///
/// ```
pub fn recursivelyFree(comptime T: type, value: T, comptime special_cases: []const type, allocator: std.mem.Allocator) void {
    recursivelyFreeWithLogging(T, T, value, special_cases, allocator);
}

/// recursively frees a struct via allocator
pub fn recursivelyFreeWithLogging(comptime Original: type, comptime T: type, value: T, comptime special_cases: []const type, allocator: std.mem.Allocator) void {
    inline for (special_cases) |case| {
        if (T == case.Type) {
            case.free(value, allocator);
            return;
        }
    }
    switch (@typeInfo(T)) {
        .Pointer => |Pointer| {
            switch (Pointer.size) {
                .One => {
                    recursivelyFreeWithLogging(Original, Pointer.child, value.*, special_cases, allocator);
                    // std.debug.print("freed {*} of {}\n", .{ value, Original });
                    allocator.destroy(value);
                },
                .Slice => {
                    for (value) |element| {
                        recursivelyFreeWithLogging(Original, Pointer.child, element, special_cases, allocator);
                    }
                    // if (value.len != 0) std.debug.print("freed {*} of {}\n", .{ value.ptr, Original });
                    allocator.free(value);
                },
                .Many => @compileError("Cannot free many item pointer (root type " ++ @typeName(Original) ++ ")"),
                .C => @compileError("Cannot free C pointer (root type " ++ @typeName(Original) ++ ")"),
            }
        },
        .Array => |Array| {
            for (value) |element| {
                recursivelyFreeWithLogging(Original, Array.child, element, special_cases, allocator);
            }
        },
        .Optional => |Optional| {
            if (value) |nonnull| {
                recursivelyFreeWithLogging(Original, Optional.child, nonnull, special_cases, allocator);
            }
        },
        .ErrorUnion => |Error| {
            if (value) |nonerror| {
                recursivelyFreeWithLogging(Original, Error.payload, nonerror, special_cases, allocator);
            }
        },
        .Union => |Union| {
            if (Union.tag_type) |_| {
                switch (value) {
                    inline else => |field_value| {
                        recursivelyFreeWithLogging(Original, @TypeOf(field_value), field_value, special_cases, allocator);
                    },
                }
            } else @compileError("Cannot free non-tagged union (root type " ++ @typeName(Original) ++ ")");
        },
        .Struct => |Struct| {
            inline for (Struct.fields) |field| {
                recursivelyFreeWithLogging(Original, field.type, @field(value, field.name), special_cases, allocator);
            }
        },
        else => {},
    }
}
