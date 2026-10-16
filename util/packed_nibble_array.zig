const std = @import("std");

pub fn PackedNibbleArray(x_size: usize, y_size: usize, z_size: usize) type {
    return struct {
        const len = @divCeil(x_size * y_size * z_size, 2);
        bytes: [len]u8,
        pub fn get(self: *const @This(), x: usize, y: usize, z: usize) u4 {
            const index = y * z_size * x_size + z * x_size + x;
            return @truncate(self.bytes[index / 2] >> @as(u3, @intCast((index & 1) * 4)));
        }
        pub fn set(self: *@This(), x: usize, y: usize, z: usize, value: u4) void {
            const index = y * z_size * x_size + z * x_size + x;
            self.bytes[index / 2] &= @as(u8, 0xF) << @intCast(((index & 1) ^ 1) * 4);
            self.bytes[index / 2] |= @as(u8, value) << @intCast((index & 1) * 4);
        }
        pub fn init(values: [x_size * y_size * z_size]u4) @This() {
            var self: @This() = .{ .bytes = @splat(0) };
            var i: usize = 0;
            for (0..16) |x| {
                for (0..16) |y| {
                    for (0..16) |z| {
                        self.set(x, y, z, values[i]);
                        i += 1;
                    }
                }
            }
            return self;
        }
    };
}

test "PackedNibbleArray" {
    var rand_impl: std.Random.DefaultPrng = .init(155215);
    const rand = rand_impl.random();
    var ints: [16 * 16 * 16]u4 = undefined;
    for (&ints) |*int| {
        int.* = rand.int(u4);
    }
    const @"packed": PackedNibbleArray(16, 16, 16) = .init(ints);

    var i: usize = 0;
    for (0..16) |x| {
        for (0..16) |y| {
            for (0..16) |z| {
                try std.testing.expectEqual(ints[i], @"packed".get(x, y, z));
                i += 1;
            }
        }
    }
}
