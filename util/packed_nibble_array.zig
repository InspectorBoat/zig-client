const std = @import("std");

pub fn PackedNibbleArray(len: usize) type {
    return struct {
        bytes: [len / 2]u8,
        pub fn get(self: *const @This(), index: usize) u4 {
            return @truncate(self.bytes[index / 2] >> @as(u3, @intCast((index & 1) * 4)));
        }
        pub fn set(self: *@This(), index: usize, value: u4) void {
            self.bytes[index / 2] &= @as(u8, 0xF) << @intCast(((index & 1) ^ 1) * 4);
            self.bytes[index / 2] |= @as(u8, value) << @intCast((index & 1) * 4);
        }
        pub fn init(values: [len]u4) @This() {
            var self: @This() = .{ .raw = .{0} ** (len / 2) };
            for (values, 0..) |value, i| {
                self.set(i, value);
            }
            return self;
        }
    };
}

test "PackedNibbleArray" {
    var rand_impl = std.Random.DefaultPrng.init(155215);
    const rand = rand_impl.random();
    var ints: [16]u4 = undefined;
    for (&ints) |*int| {
        int.* = rand.int(u4);
    }
    const @"packed" = PackedNibbleArray(16).init(ints);
    for (ints, 0..16) |expected, i| {
        try std.testing.expectEqual(expected, @"packed".get(@intCast(i)));
    }
}
