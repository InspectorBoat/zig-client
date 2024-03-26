const std = @import("std");

start: std.time.Instant,

pub fn init() @This() {
    return .{ .start = std.time.Instant.now() catch unreachable };
}

pub inline fn ns(self: @This()) f64 {
    const now = std.time.Instant.now() catch unreachable;
    return @as(f64, @floatFromInt(now.since(self.start)));
}

pub inline fn ms(self: @This()) f64 {
    return self.ns() / @as(f64, @floatFromInt(std.time.ns_per_ms));
}
