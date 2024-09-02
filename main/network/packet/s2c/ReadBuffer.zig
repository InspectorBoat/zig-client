const std = @import("std");
const root = @import("root");
const network = root.network;
const VarIntByte = network.VarIntByte;
const Vector3 = root.Vector3;
const Uuid = @import("util").Uuid;
const ItemStack = root.ItemStack;
const NbtElement = root.NbtElement;

/// A buffer to read incoming packet data (s2c)
backer: []const u8,
read_location: usize,

pub fn initCapacity(allocator: std.mem.Allocator, bytes: usize) !@This() {
    return .{
        .backer = try allocator.alloc(u8, bytes),
        .read_location = 0,
    };
}

pub fn fromOwnedSlice(slice: []const u8) @This() {
    return .{
        .backer = slice,
        .read_location = 0,
    };
}

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    allocator.free(self.backer);
}

/// resets the buffer
pub fn clear(self: *@This()) void {
    self.backer.items.len = 0;
    self.read_location = 0;
}

/// T must be a boolean, integer or float type with nonzero size and have a bit size divisible by 8
pub fn read(self: *@This(), comptime T: type) error{EndOfBuffer}!T {
    if (@typeInfo(T) != .int and @typeInfo(T) != .float and T != bool) @compileError("type to retrieve (" ++ @typeName(T) ++ ") must be boolean, integer or float type");
    if (T != bool and @sizeOf(T) * 8 != @bitSizeOf(T)) @compileError("type to retrieve (" ++ @typeInfo(T) ++ ") must have a bit size divisible by 8");
    if (@sizeOf(T) == 0) @compileError("type to retrieve (" ++ @typeName(T) ++ ") must not be zero-sized");
    const last_read_index = self.read_location + @sizeOf(T) - 1;
    if (last_read_index >= self.backer.len) {
        return error.EndOfBuffer;
    }

    // booleans have to be special cased because their bit size is 1
    if (T == bool) return try self.read(u8) != 0;

    const value_slice = self.backer[self.read_location..][0..@sizeOf(T)];
    self.read_location += @sizeOf(T);

    // use this so we don't have to special case floats
    const ValueAsInt = std.meta.Int(.unsigned, @bitSizeOf(T));
    const value_as_int = std.mem.bytesToValue(ValueAsInt, value_slice);
    return @bitCast(std.mem.bigToNative(ValueAsInt, value_as_int));
}

pub fn remainingBytes(self: @This()) usize {
    return self.backer.len - self.read_location;
}

/// T must have a bit size divisible by 8 and must be a packed struct
pub fn readPacked(self: *@This(), comptime T: type) !T {
    if (@sizeOf(T) * 8 != @bitSizeOf(T)) @compileError("type to retrieve (" ++ @typeInfo(T) ++ ") must have a bit size divisible by 8");
    if (@typeInfo(T) != .@"struct") @compileError("type to retrieve (" ++ @typeName(T) ++ ") must be a struct");
    if (@typeInfo(T).@"struct".layout != .@"packed") @compileError("type to retrieve (" ++ @typeName(T) ++ ") must be packed");
    return @bitCast(try self.read(std.meta.Int(.unsigned, @bitSizeOf(T))));
}

/// T must be an enum backed by an i32
pub fn readEnum(self: *@This(), comptime T: type) !?T {
    if (@typeInfo(T) != .@"enum") @compileError("type to retrieve (" ++ @typeName(T) ++ "must be an enum");
    if (@typeInfo(T).@"enum".tag_type != i32) @compileError("type to retrieve (" ++ @typeName(T) ++ "must be backed by an i32");
    return std.meta.intToEnum(T, try self.readVarInt()) catch null;
}

/// return value is backed by the buffer
pub fn readArrayNonAllocating(self: *@This(), comptime Count: usize) !*const [Count]u8 {
    const last_read_index = self.read_location + Count - 1;
    if (last_read_index >= self.backer.len) {
        return error.EndOfBuffer;
    }
    const array = self.backer[self.read_location..][0..Count];
    self.read_location += Count;
    return array;
}

/// return value is backed by the buffer
pub fn readBytesNonAllocating(self: *@This(), count: usize) ![]const u8 {
    const last_read_index = self.read_location + count - 1;
    if (last_read_index >= self.backer.len) {
        return error.EndOfBuffer;
    }
    const slice = self.backer[self.read_location .. self.read_location + count];
    self.read_location += count;
    return slice;
}

/// return value is not backed by the buffer
pub fn readBytesAllocating(self: *@This(), count: usize, allocator: std.mem.Allocator) ![]const u8 {
    const direct_slice = try self.readBytesNonAllocating(count);
    const slice = try allocator.alloc(u8, count);
    @memcpy(slice, direct_slice);
    return slice;
}

/// return value is backed by the buffer
pub fn readByteSliceNonAllocating(self: *@This()) ![]const u8 {
    const byte_length = try self.readVarInt();
    return try self.readBytesNonAllocating(@intCast(byte_length));
}

/// return value is not backed by the buffer
pub fn readByteSliceAllocating(self: *@This(), allocator: std.mem.Allocator) ![]const u8 {
    const byte_length = try self.readVarInt();
    return try self.readBytesAllocating(@intCast(byte_length), allocator);
}

/// returns a slice view of the unread bytes (starting at read_location and continuing to the end)
pub fn readRemainingBytesNonAllocating(self: *@This()) []const u8 {
    return self.readBytesNonAllocating(self.remainingBytes()) catch unreachable;
}

pub fn readRemainingBytesAllocating(self: *@This(), allocator: std.mem.Allocator) ![]const u8 {
    return try self.readBytesAllocating(self.remainingBytes(), allocator);
}

/// return value is backed by the buffer
pub fn readStringNonAllocating(self: *@This(), max_code_points: usize) ![]const u8 {
    const byte_length = try self.readVarInt();
    if (byte_length < 0) return error.NegativeStringLength;
    if (byte_length > max_code_points * 4) return error.StringTooLong;
    const slice = try self.readBytesNonAllocating(@intCast(byte_length));
    if (try std.unicode.utf8CountCodepoints(slice) > max_code_points) return error.StringTooLong;
    return slice;
}

/// return value is not backed by the buffer
pub fn readStringAllocating(self: *@This(), max_code_points: usize, allocator: std.mem.Allocator) ![]const u8 {
    const direct_string = try self.readStringNonAllocating(max_code_points);
    const string = try allocator.alloc(u8, direct_string.len);
    @memcpy(string, direct_string);
    return string;
}

pub fn readItemStackAllocating(self: *@This(), allocator: std.mem.Allocator) !?ItemStack {
    var item_stack: ?ItemStack = null;
    const item_id = try self.read(i16);
    if (item_id >= 0) {
        item_stack = .{
            .size = try self.read(i8),
            .metadata = try self.read(i16),
            .item = @enumFromInt(item_id),
            .nbt = switch (try NbtElement.readDiscardName(self, allocator)) {
                .Compound => |compound| compound,
                else => null,
            },
        };
    }
    return item_stack;
}

/// Uses an i32 and java's """""""""slight  modification""""""""" of utf8
pub fn readJavaUtfAllocating(self: *@This(), allocator: std.mem.Allocator) ![]const u8 {
    const length = try self.read(i32);
    return try self.readBytesAllocating(@intCast(length), allocator);
}

/// Uses an i32 and java's """""""""slight  modification""""""""" of utf8
pub fn readJavaUtfNonAllocating(self: *@This(), allocator: std.mem.Allocator) ![]const u8 {
    const length = try self.read(i32);
    return try self.readBytesNonAllocating(@intCast(length), allocator);
}

pub fn readBlockPos(self: *@This()) !Vector3(i32) {
    const l = try self.read(i64);
    const SIZE_X: i64 = 38;
    const SIZE_Y: i64 = 26;
    const OFFSET_X: i32 = 26;
    const OFFSET_Y: i32 = 12;
    const OFFSET_Z: i32 = 26;
    const x = ((l << (64 - SIZE_X - OFFSET_X)) >> (64 - OFFSET_X));
    const y = ((l << (64 - SIZE_Y - OFFSET_Y)) >> (64 - OFFSET_Y));
    const z = ((l << (64 - OFFSET_Z)) >> (64 - OFFSET_Z));
    return Vector3(i32){
        .x = @intCast(x),
        .y = @intCast(y),
        .z = @intCast(z),
    };
}

pub fn readUuid(self: *@This()) !Uuid {
    return Uuid{
        .bytes = std.mem.toBytes(try self.read(u128)),
    };
}

pub fn readVarInt(self: *@This()) !i32 {
    var result: u32 = 0;
    for (0..5) |i| {
        // read byte from buffer
        const byte: VarIntByte = @bitCast(try self.read(u8));
        const data_bits: u32 = byte.data_bits;
        // add byte to data
        result |= data_bits << @intCast(i * 7);
        if (!byte.has_more_bytes) {
            break;
        }
    } else {
        return error.VarIntTooBig;
    }

    return @bitCast(result);
}

pub fn readVarIntExtra(self: *@This(), comptime max_bytes: usize) error{ VarIntTooBig, EndOfBuffer }!struct { i32, usize } {
    if (max_bytes > 5) @compileError("max_bytes must be 5 or less");
    var result: u32 = 0;
    var bytes_read: usize = 0;
    for (0..max_bytes) |i| {
        // read byte from buffer
        const byte: VarIntByte = @bitCast(try self.read(u8));
        const data_bits: u32 = byte.data_bits;
        // add byte to data
        result |= data_bits << @intCast(i * 7);
        bytes_read += 1;
        if (!byte.has_more_bytes) {
            break;
        }
    } else {
        return error.VarIntTooBig;
    }

    return .{ @bitCast(result), bytes_read };
}

// little endian
pub fn readVarIntFromArray(comptime max_bytes: usize, var_int: [max_bytes]VarIntByte) i32 {
    if (max_bytes > 5) @compileError("max_bytes must be 5 or less");
    var result: u32 = 0;
    for (var_int, 0..) |byte, i| {
        // data portion of byte
        const data_bits: u32 = byte.data_bits;
        // add byte data to result
        result |= data_bits << @intCast(i * 7);
        if (!byte.has_more_bytes) {
            break;
        }
    }

    return @bitCast(result);
}

test readVarInt {
    const WriteBuffer = network.packet.c2s.WriteBuffer;
    std.debug.print("\n", .{});

    // initialize buffer to write to
    var write_buffer = WriteBuffer.init(std.testing.allocator);
    var read_buffer: @This() = undefined;
    // deinitializing read_buffer is unnecessary because it shares a backer with write_buffer
    defer write_buffer.deinit();

    try write_buffer.writeVarInt(0);
    // initialize read_buffer with write_buffer's backer
    read_buffer = .{ .backer = write_buffer.backer.items, .read_location = 0 };
    // read varint
    try std.testing.expectEqual(0, read_buffer.readVarInt());
    // resetting read_buffer is unnecesssary
    write_buffer.clear();

    try write_buffer.writeVarInt(1);
    read_buffer = .{ .backer = write_buffer.backer.items, .read_location = 0 };
    try std.testing.expectEqual(1, read_buffer.readVarInt());
    write_buffer.clear();

    try write_buffer.writeVarInt(2);
    read_buffer = .{ .backer = write_buffer.backer.items, .read_location = 0 };
    try std.testing.expectEqual(2, read_buffer.readVarInt());
    write_buffer.clear();

    try write_buffer.writeVarInt(127);
    read_buffer = .{ .backer = write_buffer.backer.items, .read_location = 0 };
    try std.testing.expectEqual(127, read_buffer.readVarInt());
    write_buffer.clear();

    try write_buffer.writeVarInt(255);
    read_buffer = .{ .backer = write_buffer.backer.items, .read_location = 0 };
    try std.testing.expectEqual(255, read_buffer.readVarInt());
    write_buffer.clear();

    try write_buffer.writeVarInt(25565);
    read_buffer = .{ .backer = write_buffer.backer.items, .read_location = 0 };
    try std.testing.expectEqual(25565, read_buffer.readVarInt());
    write_buffer.clear();

    try write_buffer.writeVarInt(2097151);
    read_buffer = .{ .backer = write_buffer.backer.items, .read_location = 0 };
    try std.testing.expectEqual(2097151, read_buffer.readVarInt());
    write_buffer.clear();

    try write_buffer.writeVarInt(2147483647);
    read_buffer = .{ .backer = write_buffer.backer.items, .read_location = 0 };
    try std.testing.expectEqual(2147483647, read_buffer.readVarInt());
    write_buffer.clear();

    try write_buffer.writeVarInt(-1);
    read_buffer = .{ .backer = write_buffer.backer.items, .read_location = 0 };
    try std.testing.expectEqual(-1, read_buffer.readVarInt());
    write_buffer.clear();

    try write_buffer.writeVarInt(-2147483648);
    read_buffer = .{ .backer = write_buffer.backer.items, .read_location = 0 };
    try std.testing.expectEqual(-2147483648, read_buffer.readVarInt());
    write_buffer.clear();

    try write_buffer.writeVarInt(0);
    try write_buffer.writeVarInt(1);
    try write_buffer.writeVarInt(2);
    try write_buffer.writeVarInt(127);
    try write_buffer.writeVarInt(255);
    try write_buffer.writeVarInt(25565);
    read_buffer = .{ .backer = write_buffer.backer.items, .read_location = 0 };
    try std.testing.expectEqual(0, read_buffer.readVarInt());
    try std.testing.expectEqual(1, read_buffer.readVarInt());
    try std.testing.expectEqual(2, read_buffer.readVarInt());
    try std.testing.expectEqual(127, read_buffer.readVarInt());
    try std.testing.expectEqual(255, read_buffer.readVarInt());
    try std.testing.expectEqual(25565, read_buffer.readVarInt());

    write_buffer.clear();
}
