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

pub fn unread(self: @This()) usize {
    return self.backer.len - self.read_location;
}

/// T must be a boolean, integer or float type with nonzero size and have a bit size divisible by 8
pub fn read(self: *@This(), comptime T: type) !T {
    if (self.read_location + @sizeOf(T) > self.backer.len) return error.EndOfBuffer;

    // booleans have to be special cased because their bit size is 1
    if (T == bool) return try self.read(u8) != 0;

    defer self.read_location += @sizeOf(T);

    return @bitCast(
        std.mem.readInt(
            @Int(.unsigned, @bitSizeOf(T)),
            self.backer[self.read_location..][0..@sizeOf(T)],
            .big,
        ),
    );
}

/// T must have a bit size divisible by 8 and must be a packed struct
pub fn readPacked(self: *@This(), comptime T: type) !T {
    return @fromBackingInt(try self.read(std.meta.BackingInt(T)));
}

/// T must be an enum backed by an i32
pub fn readEnum(self: *@This(), comptime T: type) !?T {
    return std.enums.fromInt(T, try self.readVarInt()) orelse null;
}

pub fn readBytes(self: *@This(), len: usize) ![]const u8 {
    if (self.read_location + len > self.backer.len) return error.EndOfBuffer;
    const slice = self.backer[self.read_location..][0..len];
    self.read_location += len;
    return slice;
}

pub fn allocBytes(self: *@This(), allocator: std.mem.Allocator, len: usize) ![]u8 {
    const direct = try self.readBytes(len);
    const slice = try allocator.alloc(u8, len);
    @memcpy(slice, direct);
    return slice;
}

pub fn readSlice(self: *@This()) ![]const u8 {
    const byte_length = try self.readVarInt();
    return try self.readBytes(@intCast(byte_length));
}

pub fn allocSlice(self: *@This(), allocator: std.mem.Allocator) ![]u8 {
    const byte_length = try self.readVarInt();
    return try self.allocBytes(allocator, @intCast(byte_length));
}

pub fn readAll(self: *@This()) []const u8 {
    return self.readBytes(self.unread()) catch unreachable;
}

pub fn allocAll(self: *@This(), allocator: std.mem.Allocator) ![]u8 {
    return try self.allocBytes(allocator, self.unread());
}

pub fn readString(self: *@This(), max_code_points: usize) ![]const u8 {
    const byte_length = try self.readVarInt();
    if (byte_length < 0) return error.NegativeStringLength;
    if (byte_length > max_code_points * 4) return error.StringTooLong;
    const slice = try self.readBytes(@intCast(byte_length));
    if (try std.unicode.utf8CountCodepoints(slice) > max_code_points) return error.StringTooLong;
    return slice;
}

pub fn allocString(self: *@This(), allocator: std.mem.Allocator, max_code_points: usize) ![]u8 {
    const direct = try self.readString(max_code_points);
    const string = try allocator.alloc(u8, direct.len);
    @memcpy(string, direct);
    return string;
}

pub fn allocItemStack(self: *@This(), allocator: std.mem.Allocator) !?Item.Stack {
    var item_stack: ?Item.Stack = null;
    const item_id = try self.read(i16);
    if (item_id >= 0) {
        item_stack = .{
            .size = try self.read(i8),
            .metadata = try self.read(i16),
            .item = @fromBackingInt(@intCast(item_id)),
            .nbt = try self.allocNbtCompound(allocator),
        };
    }
    return item_stack;
}

pub fn allocNbtCompound(self: *@This(), allocator: std.mem.Allocator) !?Nbt.Compound {
    const nbt: Nbt = try .readDiscardName(allocator, self);
    return switch (nbt) {
        .end => null,
        .compound => |compound| compound,
        else => error.ExpectedNbtCompound,
    };
}

/// Uses a u16 and java's """""""""slight modification""""""""" of utf8
pub fn allocJavaUtf(self: *@This(), allocator: std.mem.Allocator) ![]const u8 {
    return try self.allocBytes(allocator, try self.read(u16));
}

/// Uses a u16 and java's """""""""slight modification""""""""" of utf8
pub fn readJavaUtf(self: *@This()) ![]const u8 {
    return try self.readBytes(try self.read(u16));
}

pub fn readBlockPos(self: *@This()) !Vector3(i32) {
    const BlockPos = packed struct(i64) {
        z: i26,
        y: i12,
        x: i26,
    };

    const block_pos_packed: BlockPos = @fromBackingInt(try self.read(i64));
    return .cast(block_pos_packed);
}

pub fn readUuid(self: *@This()) !Uuid {
    return .{ .bytes = std.mem.toBytes(try self.read(u128)) };
}

pub fn readVarInt(self: *@This()) !i32 {
    const result, _ = try self.readVarIntExtra(5);
    return result;
}

pub fn readVarIntExtra(self: *@This(), comptime max_bytes: usize) !struct { i32, usize } {
    comptime std.debug.assert(max_bytes <= 5);
    var result: u32 = 0;
    for (0..max_bytes) |i| {
        const byte: VarIntByte = @fromBackingInt(try self.read(u8));
        result |= @as(u32, byte.data) << @intCast(i * 7);
        if (!byte.cont) return .{ @bitCast(result), i + 1 };
    } else return error.VarIntTooBig;
}

test readVarInt {
    const WriteBuffer = network.packet.C2S.WriteBuffer;

    // initialize buffer to write to
    var write_buffer: WriteBuffer = .initBuffer(try std.testing.allocator.alloc(u8, 4096));
    defer write_buffer.backer.deinit(std.testing.allocator);

    try write_buffer.writeVarInt(0);
    var read_buffer: @This() = .fromOwnedSlice(write_buffer.backer.items);
    try std.testing.expectEqual(0, read_buffer.readVarInt());

    try write_buffer.writeVarInt(1);
    read_buffer.backer = write_buffer.backer.items;
    try std.testing.expectEqual(1, read_buffer.readVarInt());

    try write_buffer.writeVarInt(2);
    read_buffer.backer = write_buffer.backer.items;
    try std.testing.expectEqual(2, read_buffer.readVarInt());

    try write_buffer.writeVarInt(127);
    read_buffer.backer = write_buffer.backer.items;
    try std.testing.expectEqual(127, read_buffer.readVarInt());

    try write_buffer.writeVarInt(255);
    read_buffer.backer = write_buffer.backer.items;
    try std.testing.expectEqual(255, read_buffer.readVarInt());

    try write_buffer.writeVarInt(25565);
    read_buffer.backer = write_buffer.backer.items;
    try std.testing.expectEqual(25565, read_buffer.readVarInt());

    try write_buffer.writeVarInt(2097151);
    read_buffer.backer = write_buffer.backer.items;
    try std.testing.expectEqual(2097151, read_buffer.readVarInt());

    try write_buffer.writeVarInt(2147483647);
    read_buffer.backer = write_buffer.backer.items;
    try std.testing.expectEqual(2147483647, read_buffer.readVarInt());

    try write_buffer.writeVarInt(-1);
    read_buffer.backer = write_buffer.backer.items;
    try std.testing.expectEqual(-1, read_buffer.readVarInt());

    try write_buffer.writeVarInt(-2147483648);
    read_buffer.backer = write_buffer.backer.items;
    try std.testing.expectEqual(-2147483648, read_buffer.readVarInt());

    try write_buffer.writeVarInt(0);
    try write_buffer.writeVarInt(1);
    try write_buffer.writeVarInt(2);
    try write_buffer.writeVarInt(127);
    try write_buffer.writeVarInt(255);
    try write_buffer.writeVarInt(25565);
    read_buffer.backer = write_buffer.backer.items;
    try std.testing.expectEqual(0, read_buffer.readVarInt());
    try std.testing.expectEqual(1, read_buffer.readVarInt());
    try std.testing.expectEqual(2, read_buffer.readVarInt());
    try std.testing.expectEqual(127, read_buffer.readVarInt());
    try std.testing.expectEqual(255, read_buffer.readVarInt());
    try std.testing.expectEqual(25565, read_buffer.readVarInt());
}

test readJavaUtf {
    var buffer: @This() = .{
        .backer = &.{ 0x00, 0x02, 'h', 'i' },
        .read_location = 0,
    };
    const utf = try buffer.readJavaUtf();
    try std.testing.expectEqualStrings("hi", utf);
    try std.testing.expectEqual(buffer.backer.len, buffer.read_location);
}

const std = @import("std");

const main = @import("main");
const Uuid = @import("util").Uuid;

const Item = main.Item;
const Nbt = main.Nbt;
const Vector3 = main.Vector3;
const network = main.network;
const VarIntByte = network.VarIntByte;
