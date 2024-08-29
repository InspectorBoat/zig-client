const std = @import("std");
const ReadPacketBuffer = @import("../network/packet/ReadPacketBuffer.zig");
const WritePacketBuffer = @import("../network/packet/WritePacketBuffer.zig");

pub const NbtElementTag = enum(i8) {
    End = 0,
    Byte = 1,
    Short = 2,
    Int = 3,
    Long = 4,
    Float = 5,
    Double = 6,
    ByteArray = 7,
    String = 8,
    List = 9,
    Compound = 10,
    IntArray = 11,
};

pub const NbtReadError = error{
    OutOfMemory,
    StringTooLarge,
    EndOfBuffer,
    InvalidNbtElementType,
    BadListLength,
};

pub const NbtWriteError = error{
    OutOfMemory,
    StringTooLarge,
};

pub const NbtElement = union(NbtElementTag) {
    End: NbtEnd,
    Byte: NbtByte,
    Short: NbtShort,
    Int: NbtInt,
    Long: NbtLong,
    Float: NbtFloat,
    Double: NbtDouble,
    ByteArray: NbtByteArray,
    String: NbtString,
    List: NbtList,
    Compound: NbtCompound,
    IntArray: NbtIntArray,

    pub fn writeBlankName(self: *@This(), buffer: *WritePacketBuffer) NbtWriteError!void {
        try self.writeWithName(buffer, "");
    }

    pub fn writeWithName(self: *@This(), buffer: *WritePacketBuffer, key: []const u8) NbtWriteError!void {
        std.debug.print("writing {s}\n", .{@tagName(self.*)});
        try buffer.write(i8, @intFromEnum(self.*));
        switch (self.*) {
            .End => {},
            inline else => |*specific_element| {
                try buffer.writeJavaUtf(key);
                try specific_element.write(buffer);
            },
        }
    }

    pub fn readDiscardName(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) NbtReadError!@This() {
        const read_result = try readWithName(buffer, allocator);
        // TODO: this is lazy
        if (read_result.name) |name| allocator.free(name);
        return read_result.element;
    }

    pub fn readElementType(buffer: *ReadPacketBuffer) !NbtElementTag {
        return std.meta.intToEnum(NbtElementTag, try buffer.read(i8)) catch return error.InvalidNbtElementType;
    }

    pub fn readWithName(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) NbtReadError!struct { name: ?[]const u8, element: NbtElement } {
        // read the byte telling us the tag of the element
        switch (try readElementType(buffer)) {
            .End => return .{ .name = null, .element = NbtElement{ .End = .{} } },
            // inline switch to make specific_tag_type comptime known
            inline else => |element_type| {
                const name = try buffer.readJavaUtfAllocating(allocator);
                // the type of the nbt element corresponding to the tag
                const ElementType = typeFromTag(element_type);
                return .{
                    .name = name,
                    .element = @unionInit(
                        NbtElement,
                        nameFromTag(element_type),
                        try ElementType.read(buffer, allocator),
                    ),
                };
            },
        }
    }
    pub fn read(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) NbtReadError!NbtElement {
        // read the byte telling us the tag of the element
        return switch (try readElementType(buffer)) {
            .Compound => .{ .Compound = try NbtCompound.read(buffer, allocator) },
            else => std.debug.panic("Root tag must be a named compound tag\n", .{}),
        };
    }

    pub fn nameFromTag(comptime element_type: NbtElementTag) []const u8 {
        return @tagName(element_type);
    }

    pub fn typeFromTag(comptime element_type: NbtElementTag) type {
        return std.meta.TagPayload(NbtElement, element_type);
    }

    pub fn deepEquals(self: *@This(), other: *@This()) bool {
        switch (self.*) {
            inline else => |*specific_element| {
                return specific_element.deepEquals(other);
            },
        }
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        switch (self.*) {
            inline else => |*specific_element_type| {
                specific_element_type.deinit(allocator);
            },
        }
    }
};

pub const NbtEnd = struct {
    pub fn write(self: *const @This(), buffer: *WritePacketBuffer) NbtWriteError!void {
        _ = self;
        _ = buffer;
    }

    pub fn read(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) NbtReadError!@This() {
        _ = allocator;
        _ = buffer;
        return .{};
    }

    pub fn deepEquals(self: *@This(), other: *NbtElement) bool {
        _ = self;
        return other.* == .End;
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        _ = self;
        _ = allocator;
    }
};

pub fn NbtNumber(comptime Value: type) type {
    return struct {
        value: Value,

        pub fn write(self: *const @This(), buffer: *WritePacketBuffer) NbtWriteError!void {
            try buffer.write(Value, self.value);
        }

        pub fn read(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) NbtReadError!@This() {
            _ = allocator;
            return .{
                .value = try buffer.read(Value),
            };
        }

        pub fn deepEquals(self: *@This(), other: *NbtElement) bool {
            if (other.* != tagFromType(@This())) return false;
            return self.value == @field(other, nameFromType(@This())).value;
        }

        /// Assumes no duplicate field types
        pub fn nameFromType(comptime Type: type) []const u8 {
            for (@typeInfo(NbtElement).Union.fields) |field| {
                if (field.type == Type) return field.name;
            }
        }

        /// Assumes no duplicate field types
        pub fn tagFromType(comptime Type: type) NbtElementTag {
            inline for (@typeInfo(NbtElementTag).Enum.fields, @typeInfo(NbtElement).Union.fields) |tag, field| {
                if (field.type == Type) {
                    return @enumFromInt(tag.value);
                }
            }
            unreachable;
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            _ = self;
            _ = allocator;
        }
    };
}

pub const NbtByte = NbtNumber(i8);
pub const NbtShort = NbtNumber(i16);
pub const NbtInt = NbtNumber(i32);
pub const NbtLong = NbtNumber(i64);
pub const NbtFloat = NbtNumber(f32);
pub const NbtDouble = NbtNumber(f64);

pub const NbtByteArray = struct {
    values: []const i8,

    pub fn write(self: *const @This(), buffer: *WritePacketBuffer) NbtWriteError!void {
        try buffer.write(i32, @intCast(self.values.len));
        for (self.values) |element| {
            try buffer.write(i32, @intCast(element));
        }
    }

    pub fn read(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) NbtReadError!@This() {
        const element_count: usize = @intCast(try buffer.read(i32));
        const values = try allocator.alloc(i8, element_count);
        const bytes = try buffer.readBytesNonAllocating(element_count * @sizeOf(i8));

        @memcpy(values, @as([]const i8, @ptrCast(bytes)));
        return .{
            .values = values,
        };
    }

    pub fn deepEquals(self: *@This(), other: *NbtElement) bool {
        if (other.* != .ByteArray) return false;
        if (self.values.len != other.*.ByteArray.values.len) return false;
        for (self.values, other.*.ByteArray.values) |i, j| {
            if (i != j) return false;
        }
        return true;
    }
    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        allocator.free(self.values);
    }
};

pub const NbtString = struct {
    value: []const u8,

    pub fn write(self: *const @This(), buffer: *WritePacketBuffer) NbtWriteError!void {
        try buffer.writeJavaUtf(self.value);
    }

    pub fn read(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) NbtReadError!@This() {
        return .{
            .value = try buffer.readJavaUtfAllocating(allocator),
        };
    }

    pub fn deepEquals(self: *@This(), other: *NbtElement) bool {
        if (other.* != .String) return false;
        if (self.value.len != other.*.String.value.len) return false;
        for (self.value, other.*.String.value) |i, j| {
            if (i != j) return false;
        }
        return true;
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        allocator.free(self.value);
    }
};

pub const NbtList = struct {
    elements: []NbtElement,
    element_type: NbtElementTag,

    pub fn init(
        comptime nbt_element_type: NbtElementTag,
        specific_elements: []const std.meta.TagPayloadByName(NbtElement, @tagName(nbt_element_type)),
        allocator: std.mem.Allocator,
    ) !@This() {
        var elements = try allocator.alloc(NbtElement, specific_elements.len);
        _ = &elements;
        for (specific_elements, elements) |specific_element, *element| {
            element.* = @unionInit(NbtElement, @tagName(nbt_element_type), specific_element);
        }
        return .{
            .elements = elements,
            .element_type = nbt_element_type,
        };
    }

    pub fn write(self: *@This(), buffer: *WritePacketBuffer) NbtWriteError!void {
        self.element_type = if (self.elements.len == 0) .End else @as(NbtElementTag, self.elements[0]);

        try buffer.write(i8, @intFromEnum(self.element_type));
        try buffer.write(i32, @intCast(self.elements.len));

        for (self.elements) |*element| {
            switch (element.*) {
                inline else => |*specific_element| {
                    try specific_element.write(buffer);
                },
            }
        }
    }

    pub fn read(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) NbtReadError!@This() {
        const element_type = try NbtElement.readElementType(buffer);
        const element_count: usize = @intCast(try buffer.read(i32));

        if (element_type == .End and element_count != 0) return error.BadListLength;

        const elements = try allocator.alloc(NbtElement, element_count);
        switch (element_type) {
            inline else => |specific_element_type| {
                const NbtElementType = std.meta.TagPayload(NbtElement, specific_element_type);
                for (elements) |*element| {
                    element.* = @unionInit(NbtElement, @tagName(specific_element_type), try NbtElementType.read(buffer, allocator));
                }
            },
        }
        return .{
            .elements = elements,
            .element_type = element_type,
        };
    }

    pub fn deepEquals(self: *@This(), other: *NbtElement) bool {
        if (other.* != .List) return false;
        if (self.elements.len != other.*.List.elements.len) return false;
        for (self.elements, other.*.List.elements) |*i, *j| {
            if (!i.deepEquals(j)) return false;
        }
        return true;
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        for (self.elements) |*element| {
            element.deinit(allocator);
        }
        allocator.free(self.elements);
    }
};

pub const NbtCompound = struct {
    elements: std.StringHashMapUnmanaged(NbtElement),

    pub fn init(initializer: anytype, allocator: std.mem.Allocator) !@This() {
        var compound = @This(){
            .elements = std.StringHashMapUnmanaged(NbtElement){},
        };
        inline for (std.meta.fields(@TypeOf(initializer))) |field| {
            const name = try allocator.dupe(u8, field.name);
            try compound.elements.put(allocator, name, @field(initializer, field.name));
        }
        return compound;
    }

    pub fn write(self: *const @This(), buffer: *WritePacketBuffer) NbtWriteError!void {
        var entries = self.elements.iterator();
        while (entries.next()) |entry| {
            const key = entry.key_ptr.*;
            const element = entry.value_ptr;
            try element.writeWithName(buffer, key);
        }
        // write end
        var end = NbtElement{ .End = .{} };
        try end.writeBlankName(buffer);
    }

    pub fn read(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) NbtReadError!@This() {
        var elements = std.StringHashMapUnmanaged(NbtElement){};

        var read_result = try NbtElement.readWithName(buffer, allocator);
        while (read_result.element != .End) : (read_result = try NbtElement.readWithName(buffer, allocator)) {
            try elements.put(allocator, read_result.name.?, read_result.element);
        }

        return .{
            .elements = elements,
        };
    }

    pub fn deepEquals(self: *@This(), other: *NbtElement) bool {
        if (other.* != .Compound) return false;
        if (self.elements.size != other.*.Compound.elements.size) return false;
        var self_entries = self.elements.iterator();
        while (self_entries.next()) |self_entry| {
            if (other.*.Compound.elements.getPtr(self_entry.key_ptr.*)) |other_element| {
                if (!self_entry.value_ptr.deepEquals(other_element)) return false;
            } else {
                return false;
            }
        }
        return true;
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        var entries = self.elements.iterator();
        while (entries.next()) |*entry| {
            const name = entry.key_ptr.*;
            allocator.free(name);
            const element = entry.value_ptr;
            element.deinit(allocator);
        }
        self.elements.deinit(allocator);
    }
};

pub const NbtIntArray = struct {
    values: []const i32,

    pub fn init(values: []const i32, allocator: std.mem.Allocator) !@This() {
        return .{
            .values = try allocator.dupe(i32, values),
        };
    }

    pub fn write(self: *const @This(), buffer: *WritePacketBuffer) NbtWriteError!void {
        try buffer.write(i32, @intCast(self.values.len));
        for (self.values) |element| {
            try buffer.write(i32, element);
        }
    }

    pub fn read(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) NbtReadError!@This() {
        const element_count: usize = @intCast(try buffer.read(i32));

        const values = try allocator.alloc(i32, element_count);
        for (values) |*value| {
            value.* = try buffer.read(i32);
        }
        return .{
            .values = values,
        };
    }

    pub fn deepEquals(self: *@This(), other: *NbtElement) bool {
        if (other.* != .IntArray) {
            std.debug.print("expected array, found {}\n", .{@as(NbtElementTag, other.*)});
            return false;
        }
        if (self.values.len != other.IntArray.values.len) {
            std.debug.print("expected length {}, found {}\n", .{ self.values.len, other.IntArray.values.len });
            return false;
        }
        for (self.values, other.IntArray.values, 0..) |v1, v2, index| {
            if (v1 != v2) {
                std.debug.print("expected {x} at index {}, found {x}\n", .{ @as(u32, @bitCast(v1)), index, @as(u32, @bitCast(v2)) });

                return false;
            }
        }
        return true;
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        allocator.free(self.values);
    }
};

pub fn ReadLimiter(comptime Limit: usize) type {
    return struct {
        comptime limit: usize = Limit,
        bytes_read: usize = 0,
        pub fn read(self: *@This(), bytes_to_read: usize) type {
            self.bytes_read += bytes_to_read;
            if (self.bytes_read > self.limit) {}
        }
    };
}

test "NbtCompound" {
    std.debug.print("\n", .{});
    var nbt = NbtElement{
        .Compound = try NbtCompound.init(
            .{
                .foo = NbtElement{ .Byte = .{ .value = 121 } },
                .bar = NbtElement{ .IntArray = try NbtIntArray.init(&.{ @bitCast(@as(u32, 0xDEADBEEF)), @bitCast(@as(u32, 0xACAB1312)), @bitCast(@as(u32, 0xCAFEBABE)) }, std.testing.allocator) },
                .qux = NbtElement{ .Double = .{ .value = 52.1 } },
                .foobar = NbtElement{
                    .List = try NbtList.init(.Double, &.{
                        NbtDouble{ .value = 1 },
                        NbtDouble{ .value = 52 },
                        NbtDouble{ .value = 15 },
                    }, std.testing.allocator),
                },
            },
            std.testing.allocator,
        ),
    };
    defer nbt.deinit(std.testing.allocator);

    var buffer = WritePacketBuffer.init(std.testing.allocator);
    defer buffer.deinit();

    try nbt.writeBlankName(&buffer);
    std.debug.print("{x}\n", .{buffer.backer.items});

    var read_buffer = buffer.toReadBuffer();

    var read_nbt = try NbtElement.readDiscardName(&read_buffer, std.testing.allocator);
    defer read_nbt.deinit(std.testing.allocator);

    try std.testing.expect(nbt.deepEquals(&read_nbt));
    std.debug.print("{}\n", .{read_nbt});
}
