const std = @import("std");
const VarIntByte = @import("../../network/type/var_int_byte.zig").VarIntByte;
const Vector3 = @import("../../type/vector.zig").Vector3;
const ItemStack = @import("../../item/ItemStack.zig");
const Uuid = @import("../../type/Uuid.zig");
const ReadPacketBuffer = @import("./ReadPacketBuffer.zig");

/// A buffer to write packet data (c2s)
backer: std.ArrayList(u8),

pub fn init(allocator: std.mem.Allocator) @This() {
    return @This(){
        .backer = std.ArrayList(u8).init(allocator),
    };
}

pub fn initCapacity(allocator: std.mem.Allocator, bytes: usize) !@This() {
    return @This(){
        .backer = try std.ArrayListUnmanaged(u8).initCapacity(allocator, bytes),
    };
}

pub fn deinit(self: *@This()) void {
    self.backer.deinit();
}

/// resets the buffer
pub fn clear(self: *@This()) void {
    self.backer.items.len = 0;
}

/// Returns a read buffer view of this buffer without copying.
pub fn toReadBuffer(self: *@This()) ReadPacketBuffer {
    return ReadPacketBuffer{
        .backer = self.backer.items,
        .read_location = 0,
    };
}

/// T must be an boolean, integer or float with nonzero size and have a bit size divisible by 8
pub fn write(self: *@This(), comptime T: type, value: T) std.mem.Allocator.Error!void {
    if (@typeInfo(T) != .Int and @typeInfo(T) != .Float and T != bool) @compileError("type to retrieve (" ++ @typeName(T) ++ ") must be integer, float, or boolean");
    if (T != bool and @sizeOf(T) * 8 != @bitSizeOf(T)) @compileError("type to retrieve (" ++ @typeName(T) ++ ") must have a bit size divisible by 8");
    if (@sizeOf(T) == 0) @compileError("type to retrieve (" ++ @typeName(T) ++ ") must not be zero-sized");

    if (T == bool) return try self.backer.append(@intCast(@intFromBool(value)));

    const ValueAsInt = std.meta.Int(.unsigned, @bitSizeOf(T));
    const value_as_int: ValueAsInt = @bitCast(value);
    const value_slice = std.mem.toBytes(std.mem.nativeToBig(ValueAsInt, value_as_int));

    try self.backer.appendSlice(&value_slice);
}

pub fn writePacked(self: *@This(), comptime T: type, value: T) !void {
    if (@sizeOf(T) * 8 != @bitSizeOf(T)) @compileError("type to write (" ++ @typeName(T) ++ ") must have a bit size divisible by 8");
    if (@sizeOf(T) != 1) @compileError("type to write (" ++ @typeName(T) ++ ") must have a byte size of 1");

    try self.backer.append(@bitCast(value));
}

/// T must be an enum backed by an i32
pub fn writeEnum(self: *@This(), comptime T: type, value: T) !void {
    if (@typeInfo(T) != .Enum) @compileError("type to write (" ++ @typeName(T) ++ "must be an enum");
    if (@typeInfo(T).Enum.tag_type != i32) @compileError("type to write (" ++ @typeName(T) ++ "must be backed by an i32");
    return try self.writeVarInt(@intFromEnum(value));
}

pub fn writeBytes(self: *@This(), b: []const u8) !void {
    try self.backer.appendSlice(b);
}

pub fn writeByteSlice(self: *@This(), b: []const u8) !void {
    try self.writeVarInt(@intCast(b.len));
    try self.writeBytes(b);
}

pub fn writeBlockPos(self: *@This(), block_pos: Vector3(i32)) !void {
    const MASK_X: i64 = 0x3ffffff;
    const MASK_Y: i64 = 0xfff;
    const MASK_Z: i64 = 0x3ffffff;
    const SIZE_X: i64 = 38;
    const SIZE_Y: i64 = 26;

    try self.write(
        i64,
        (block_pos.x & MASK_X) << SIZE_X |
            (block_pos.y & MASK_Y) << SIZE_Y |
            (block_pos.z & MASK_Z) << 0,
    );
}

pub fn writeItemStack(self: *@This(), item_stack: ?ItemStack) !void {
    _ = self; // autofix
    _ = item_stack; // autofix
    std.debug.panic("unimplemented", .{});
}

pub fn writeUuid(self: *@This(), uuid: Uuid) !void {
    try self.writeBytes(&uuid.bytes);
}

pub fn writeString(self: *@This(), s: []const u8) (error{StringTooLarge} || std.mem.Allocator.Error)!void {
    if (s.len > 32767) return error.StringTooLarge;
    try self.writeVarInt(@intCast(s.len));
    try self.writeBytes(s);
}

/// TODO: this is probably wrong
pub fn writeJavaUtf(self: *@This(), s: []const u8) !void {
    try self.write(i32, @intCast(s.len));
    try self.writeBytes(s);
}

// little endian
pub fn writeVarInt(self: *@This(), i: i32) std.mem.Allocator.Error!void {
    // cast value to unsigned version to avoid shifting in 1s
    var u = @as(u32, @bitCast(i));
    for (0..5) |_| {
        // the next 7 data bits
        const data_bits = @as(u7, @truncate(u));

        // shift the data bits off
        u >>= 7;
        // whether the value is now all zeros
        const has_more_bytes = u != 0;

        const byte_to_write: VarIntByte = .{
            .data_bits = data_bits,
            .has_more_bytes = has_more_bytes,
        };

        try self.write(u8, @bitCast(byte_to_write));

        if (!has_more_bytes) break;
    } else {
        std.debug.panic("tried to write more than 5 bytes in a varint. this shouldn't be possible! varint: {}", .{u});
    }
}

pub fn fromOwnedArrayList(array_list: std.ArrayList(u8)) @This() {
    return @This(){
        .backer = array_list,
    };
}

test writeVarInt {
    std.debug.print("\n", .{});
    var buffer = @This().init(std.testing.allocator);
    defer buffer.deinit();

    try buffer.writeVarInt(0);
    try std.testing.expectEqualSlices(u8, &[_]u8{0x00}, buffer.backer.items);
    buffer.clear();

    try buffer.writeVarInt(1);
    try std.testing.expectEqualSlices(u8, &[_]u8{0x01}, buffer.backer.items);
    buffer.clear();

    try buffer.writeVarInt(2);
    try std.testing.expectEqualSlices(u8, &[_]u8{0x02}, buffer.backer.items);
    buffer.clear();

    try buffer.writeVarInt(127);
    try std.testing.expectEqualSlices(u8, &[_]u8{0x7f}, buffer.backer.items);
    buffer.clear();

    try buffer.writeVarInt(255);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xff, 0x01 }, buffer.backer.items);
    buffer.clear();

    try buffer.writeVarInt(25565);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xdd, 0xc7, 0x01 }, buffer.backer.items);
    buffer.clear();

    try buffer.writeVarInt(2097151);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xff, 0xff, 0x7f }, buffer.backer.items);
    buffer.clear();

    try buffer.writeVarInt(2147483647);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xff, 0xff, 0xff, 0xff, 0x07 }, buffer.backer.items);
    buffer.clear();

    try buffer.writeVarInt(-1);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xff, 0xff, 0xff, 0xff, 0x0f }, buffer.backer.items);
    buffer.clear();

    try buffer.writeVarInt(-2147483648);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0x80, 0x80, 0x80, 0x80, 0x08 }, buffer.backer.items);
    buffer.clear();

    try buffer.writeVarInt(0);
    try buffer.writeVarInt(1);
    try buffer.writeVarInt(2);
    try buffer.writeVarInt(127);
    try buffer.writeVarInt(255);
    try buffer.writeVarInt(25565);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0x00, 0x01, 0x02, 0x7f, 0xff, 0x01, 0xdd, 0xc7, 0x01 }, buffer.backer.items);
    buffer.clear();
}
