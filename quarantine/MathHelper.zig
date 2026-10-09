const std = @import("std");

pub const sine_table = blk: {
    @setEvalBranchQuota(100000);
    var table: [65536]f32 = undefined;
    for (&table, 0..) |*entry, i| {
        entry.* = @floatCast(@sin(@as(f64, @floatFromInt(i)) * std.math.pi * 2.0 / 65536.0));
    }
    break :blk table;
};

/// Mirrors Java `SINE_TABLE[(int)(x * 10430.378F) & 65535]`. Java's float->int
/// cast saturates at the i32 bounds and maps NaN to 0 (JLS 5.1.3), and only then
/// is the index masked to 16 bits - so reproduce all three steps in that order.
/// `@intFromFloat` is undefined on NaN/out-of-range, hence the explicit guards.
fn tableIndex(scaled: f32) u16 {
    const as_int: i32 = if (std.math.isNan(scaled))
        0
    else if (scaled >= 2147483648.0)
        std.math.maxInt(i32)
    else if (scaled <= -2147483648.0)
        std.math.minInt(i32)
    else
        @intFromFloat(scaled);
    return @truncate(@as(u32, @bitCast(as_int)));
}

pub fn sin(x: f32) f32 {
    return sine_table[tableIndex(x * 10430.378)];
}

pub fn cos(x: f32) f32 {
    return sine_table[tableIndex(x * 10430.378 + 16384.0)];
}

pub fn wrapDegrees(degrees: f32) f32 {
    var d = @rem(degrees, 360.0);
    if (d >= 180.0) {
        d -= 360.0;
    }

    if (d < -180.0) {
        d += 360.0;
    }

    return d;
}
