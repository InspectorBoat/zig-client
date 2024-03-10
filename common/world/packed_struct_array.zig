const std = @import("std");

pub fn PackedStructArray(comptime Element: type, comptime length: usize) type {
    return struct {
        int_array: std.PackedIntArray(std.meta.Int(.unsigned, @bitSizeOf(Element)), length),
        pub fn get(self: @This(), index: usize) Element {
            return @bitCast(self.int_array.get(index));
        }
        pub fn set(self: *@This(), index: usize, element: Element) void {
            self.int_array.set(index, @bitCast(element));
        }
    };
}
