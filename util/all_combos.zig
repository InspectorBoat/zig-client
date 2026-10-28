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

/// Every combination of field values for the struct type T.
/// All fields must be int, enum, or bool.
pub fn allValues(T: type) [
    blk: {
        var total = 1;
        for (@typeInfo(T).@"struct".field_types) |@"type"| total *= count(@"type");
        break :blk total;
    }
]T {
    return comptime blk: {
        const field_names = @typeInfo(T).@"struct".field_names;
        const field_types = @typeInfo(T).@"struct".field_types;
        var total = 1;
        for (field_types) |@"type"| total *= count(@"type");

        var values: [total]T = undefined;
        for (0..total) |i| {
            var rem = i;
            for (field_names, field_types) |name, @"type"| {
                @field(values[i], name) = nth(@"type", rem % count(@"type"));
                rem /= count(@"type");
            }
        }
        break :blk values;
    };
}

const std = @import("std");
