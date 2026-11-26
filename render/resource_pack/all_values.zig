/// how many distinct values can a field of type T hold

fn count(T: type) usize {
    return switch (@typeInfo(T)) {
        .int => @as(usize, 1) << @typeInfo(T).int.bits,
        .@"enum" => @typeInfo(T).@"enum".field_names.len,
        .bool => 2,
        else => @compileError("unsupported field type"),
    };
}

/// the ith of those values
fn nth(T: type, n: comptime_int) T {
    return switch (@typeInfo(T)) {
        .int => @intCast(n),
        .@"enum" => |e| @fromBackingInt(e.field_values[n]),
        .bool => n == 1,
        else => @compileError("unsupported field type"),
    };
}

fn numValues(T: type) comptime_int {
    var total = 1;
    for (@typeInfo(T).@"struct".field_types, @typeInfo(T).@"struct".field_names) |@"type", name| {
        if (name[0] != '_') total *= count(@"type");
    }
    return total;
}

/// Every combination of field values for the struct type T.
/// All fields must be int, enum, or bool.
pub fn allValues(T: type) [numValues(T)]T {
    return comptime blk: {
        const field_names = @typeInfo(T).@"struct".field_names;
        const field_types = @typeInfo(T).@"struct".field_types;

        var values: [numValues(T)]T = undefined;
        for (0..numValues(T)) |i| {
            var rem = i;
            for (field_names, field_types) |name, @"type"| {
                if (name[0] == '_') {
                    @field(values[i], name) = 0;
                    continue;
                }
                @field(values[i], name) = nth(@"type", rem % count(@"type"));
                rem /= count(@"type");
            }
        }
        break :blk values;
    };
}

test allValues {
    const Foo = struct {
        _0: u8 = 0,
        a: u3,
        b: bool,
        c: enum { bar },
        _1: u1 = 0,
    };
    try std.testing.expectEqualSlices(Foo, &.{
        .{ .a = 0, .b = false, .c = .bar },
        .{ .a = 1, .b = false, .c = .bar },
        .{ .a = 2, .b = false, .c = .bar },
        .{ .a = 3, .b = false, .c = .bar },
        .{ .a = 4, .b = false, .c = .bar },
        .{ .a = 5, .b = false, .c = .bar },
        .{ .a = 6, .b = false, .c = .bar },
        .{ .a = 7, .b = false, .c = .bar },
        .{ .a = 0, .b = true, .c = .bar },
        .{ .a = 1, .b = true, .c = .bar },
        .{ .a = 2, .b = true, .c = .bar },
        .{ .a = 3, .b = true, .c = .bar },
        .{ .a = 4, .b = true, .c = .bar },
        .{ .a = 5, .b = true, .c = .bar },
        .{ .a = 6, .b = true, .c = .bar },
        .{ .a = 7, .b = true, .c = .bar },
    }, &allValues(Foo));
}

const std = @import("std");
