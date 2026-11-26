pub const Protocol = enum(i32) {
    handshake = -1,
    play = 0,
    status = 1,
    login = 2,
};

pub const Uuid = struct {
    bytes: [16]u8,
    /// expects a string formatted as xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx, where x is a ascii hex digit
    pub fn fromAscii(string: []const u8) !@This() {
        if (string.len != 36) return error.BadStringLength;
        for (string, 0..36) |char, i| {
            switch (i) {
                8, 13, 18, 23 => if (char != '-') return error.ExpectedDash,
                else => if (!std.ascii.isHex(char)) return error.ExpectedHex,
            }
        }
        const without_dashes = string[0..8] ++ string[9..13] ++ string[14..18] ++ string[19..23] ++ string[24..36];
        const parsed_int = try std.fmt.parseInt(u128, without_dashes, 16);
        return .{ .bytes = std.mem.toBytes(parsed_int) };
    }

    const std = @import("std");
};

pub fn ScaledRotation2(comptime Element: type, comptime Factor: comptime_float) type {
    return struct {
        yaw: Element,
        pitch: Element,

        pub fn normalize(self: @This()) Rotation2(f32) {
            return .{
                .yaw = @as(f32, @floatFromInt(self.yaw)) / @as(f32, Factor),
                .pitch = @as(f32, @floatFromInt(self.pitch)) / @as(f32, Factor),
            };
        }
    };
}

pub fn ScaledRotation1(comptime Element: type, comptime Factor: comptime_float) type {
    return struct {
        head_yaw: Element,

        pub fn normalize(self: @This()) f32 {
            return @as(f32, @floatFromInt(self.head_yaw)) / @as(f32, Factor);
        }
    };
}

pub fn ScaledVector(comptime Element: type, comptime Factor: comptime_float) type {
    switch (@typeInfo(Element)) {
        .int, .float => {},
        else => @compileError("Element must be integer or float type, found " ++ @typeName(Element)),
    }
    return struct {
        raw: Vector3(Element),

        pub fn normalize(self: @This()) Vector3(f64) {
            return switch (@typeInfo(Element)) {
                .int => .{
                    .x = @as(f64, @floatFromInt(self.raw.x)) / @as(f64, Factor),
                    .y = @as(f64, @floatFromInt(self.raw.y)) / @as(f64, Factor),
                    .z = @as(f64, @floatFromInt(self.raw.z)) / @as(f64, Factor),
                },
                .float => .{
                    .x = @as(f64, @floatCast(self.raw.x)) / @as(f64, Factor),
                    .y = @as(f64, @floatCast(self.raw.y)) / @as(f64, Factor),
                    .z = @as(f64, @floatCast(self.raw.z)) / @as(f64, Factor),
                },
                else => unreachable,
            };
        }
    };
}

pub const VarIntByte = packed struct(u8) {
    /// Data bits
    data: u7,
    /// Continuation flag
    cont: bool,
};

test {
    _ = Session;
    _ = AesCfb8;
    _ = packet.S2C.Login.Hello;
    _ = RingBuffer;
    _ = RingAllocator;
    _ = RingAllocatorWithFallback;
}

const main = @import("main");

pub const AesCfb8 = @import("AesCfb8.zig");
pub const Connection = @import("Connection.zig");
pub const GameProfile = @import("GameProfile.zig");
pub const RingAllocator = @import("RingAllocator.zig");
pub const RingAllocatorWithFallback = @import("RingAllocatorWithFallback.zig");
pub const RingBuffer = @import("RingBuffer.zig");
pub const Session = @import("Session.zig");
pub const packet = @import("packet/packet.zig");
pub const SpscQueue = @import("spsc_queue.zig").SpscQueue;

const Rotation2 = main.Rotation2;
const Vector3 = main.Vector3;
