const std = @import("std");

const main = @import("main");

const C2S = main.network.packet.C2S;
const S2C = main.network.packet.S2C;

pub const Nbt = union(Tag) {
    pub const Tag = enum(i8) {
        end = 0,
        byte = 1,
        short = 2,
        int = 3,
        long = 4,
        float = 5,
        double = 6,
        byte_array = 7,
        string = 8,
        list = 9,
        compound = 10,
        int_array = 11,
    };

    end: End,
    byte: Byte,
    short: Short,
    int: Int,
    long: Long,
    float: Float,
    double: Double,
    byte_array: ByteArray,
    string: String,
    list: List,
    compound: Compound,
    int_array: IntArray,

    pub const ReadError = error{
        OutOfMemory,
        StringTooLarge,
        EndOfBuffer,
        InvalidNbtElementType,
        BadListLength,
    };

    pub const WriteError = error{
        OutOfMemory,
        StringTooLarge,
    };

    pub fn writeBlankName(self: *const @This(), buffer: *C2S.WriteBuffer) WriteError!void {
        try self.writeWithName(buffer, "");
    }

    pub fn writeWithName(self: *const @This(), buffer: *C2S.WriteBuffer, key: []const u8) WriteError!void {
        try buffer.write(i8, @backingInt(self.*));
        switch (self.*) {
            .end => {},
            inline else => |*specific_element| {
                try buffer.writeJavaUtf(key);
                try specific_element.write(buffer);
            },
        }
    }

    pub fn readDiscardName(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) ReadError!@This() {
        const read_result = try readWithName(allocator, buffer);
        // TODO: this is lazy
        if (read_result.name) |name| allocator.free(name);
        return read_result.element;
    }

    pub fn readElementType(buffer: *S2C.ReadBuffer) !Tag {
        return std.enums.fromInt(Tag, try buffer.read(i8)) orelse return error.InvalidNbtElementType;
    }

    pub fn readWithName(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) ReadError!struct { name: ?[]const u8, element: Nbt } {
        // read the byte telling us the tag of the element
        switch (try readElementType(buffer)) {
            .end => return .{ .name = null, .element = .{ .end = .{} } },

            inline else => |element_type| {
                const name = try buffer.readJavaUtfAllocating(allocator);
                // the type of the nbt element corresponding to the tag
                const ElementType = @FieldType(Nbt, @tagName(element_type));
                return .{
                    .name = name,
                    .element = @unionInit(
                        Nbt,
                        @tagName(element_type),
                        try ElementType.read(allocator, buffer),
                    ),
                };
            },
        }
    }

    pub fn deepEquals(self: *const @This(), other: *const @This()) bool {
        switch (self.*) {
            inline else => |*specific_element| {
                return specific_element.deepEquals(other);
            },
        }
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        switch (self.*) {
            inline else => |*specific_element| {
                specific_element.deinit(allocator);
            },
        }
    }

    pub fn dupe(self: *const @This(), allocator: std.mem.Allocator) error{OutOfMemory}!@This() {
        switch (self.*) {
            inline else => |*specific_element, specific_element_tag| {
                return @unionInit(@This(), @tagName(specific_element_tag), try specific_element.dupe(allocator));
            },
        }
    }

    pub const End = struct {
        pub fn write(_: *const @This(), _: *C2S.WriteBuffer) WriteError!void {}

        pub fn read(_: std.mem.Allocator, _: *S2C.ReadBuffer) ReadError!@This() {
            return .{};
        }

        pub fn deepEquals(_: *const @This(), other: *const Nbt) bool {
            return other.* == .end;
        }

        pub fn deinit(_: *@This(), _: std.mem.Allocator) void {}

        pub fn dupe(_: *const @This(), _: std.mem.Allocator) !@This() {
            return .{};
        }
    };

    pub fn Number(comptime Value: type) type {
        return struct {
            value: Value,

            pub fn write(self: *const @This(), buffer: *C2S.WriteBuffer) WriteError!void {
                try buffer.write(Value, self.value);
            }

            pub fn read(_: std.mem.Allocator, buffer: *S2C.ReadBuffer) ReadError!@This() {
                return .{
                    .value = try buffer.read(Value),
                };
            }

            pub fn deepEquals(self: *const @This(), other: *const Nbt) bool {
                switch (other.*) {
                    inline else => |element| {
                        if (@TypeOf(element) != @This()) return false;
                        return element.value == self.value;
                    },
                }
            }

            pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
                _ = self;
                _ = allocator;
            }

            pub fn dupe(self: *const @This(), allocator: std.mem.Allocator) !@This() {
                _ = allocator;
                return self.*;
            }
        };
    }

    pub const Byte = Number(i8);
    pub const Short = Number(i16);
    pub const Int = Number(i32);
    pub const Long = Number(i64);
    pub const Float = Number(f32);
    pub const Double = Number(f64);

    pub const ByteArray = struct {
        values: []const i8,

        pub fn write(self: *const @This(), buffer: *C2S.WriteBuffer) WriteError!void {
            try buffer.write(i32, @intCast(self.values.len));
            for (self.values) |element| {
                try buffer.write(i32, @intCast(element));
            }
        }

        pub fn read(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) ReadError!@This() {
            const element_count: usize = @intCast(try buffer.read(i32));
            const values = try allocator.alloc(i8, element_count);
            const bytes = try buffer.readBytesNonAllocating(element_count * @sizeOf(i8));

            @memcpy(values, @as([]const i8, @ptrCast(bytes)));
            return .{
                .values = values,
            };
        }

        pub fn deepEquals(self: *const @This(), other: *const Nbt) bool {
            if (other.* != .byte_array) return false;
            return std.mem.eql(i8, self.values, other.byte_array.values);
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            allocator.free(self.values);
        }

        pub fn dupe(self: *const @This(), allocator: std.mem.Allocator) !@This() {
            return .{ .values = try allocator.dupe(i8, self.values) };
        }
    };

    pub const String = struct {
        value: []const u8,

        pub fn write(self: *const @This(), buffer: *C2S.WriteBuffer) WriteError!void {
            try buffer.writeJavaUtf(self.value);
        }

        pub fn read(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) ReadError!@This() {
            return .{
                .value = try buffer.readJavaUtfAllocating(allocator),
            };
        }

        pub fn deepEquals(self: *const @This(), other: *const Nbt) bool {
            if (other.* != .string) return false;
            return std.mem.eql(u8, self.value, other.string.value);
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            allocator.free(self.value);
        }

        pub fn dupe(self: *const @This(), allocator: std.mem.Allocator) !@This() {
            return .{ .value = try allocator.dupe(u8, self.value) };
        }
    };

    pub const List = struct {
        elements: []Nbt,
        element_type: Tag,

        pub fn init(
            comptime nbt_element_type: Tag,
            allocator: std.mem.Allocator,
            specific_elements: []const @FieldType(Nbt, @tagName(nbt_element_type)),
        ) !@This() {
            var elements = try allocator.alloc(Nbt, specific_elements.len);
            _ = &elements;
            for (specific_elements, elements) |specific_element, *element| {
                element.* = @unionInit(Nbt, @tagName(nbt_element_type), specific_element);
            }
            return .{
                .elements = elements,
                .element_type = nbt_element_type,
            };
        }

        pub fn write(self: *const @This(), buffer: *C2S.WriteBuffer) WriteError!void {
            const element_type: Tag = if (self.elements.len == 0) .end else self.elements[0];

            try buffer.write(i8, @backingInt(element_type));
            try buffer.write(i32, @intCast(self.elements.len));

            for (self.elements) |*element| {
                switch (element.*) {
                    inline else => |*specific_element| {
                        try specific_element.write(buffer);
                    },
                }
            }
        }

        pub fn read(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) ReadError!@This() {
            const element_type = try Nbt.readElementType(buffer);
            const element_count: usize = @intCast(try buffer.read(i32));

            if (element_type == .end and element_count != 0) return error.BadListLength;

            const elements = try allocator.alloc(Nbt, element_count);
            switch (element_type) {
                inline else => |specific_element_type| {
                    const NbtElementType = @FieldType(Nbt, @tagName(specific_element_type));
                    for (elements) |*element| {
                        element.* = @unionInit(Nbt, @tagName(specific_element_type), try NbtElementType.read(allocator, buffer));
                    }
                },
            }
            return .{
                .elements = elements,
                .element_type = element_type,
            };
        }

        pub fn deepEquals(self: *const @This(), other: *const Nbt) bool {
            if (other.* != .list) return false;
            if (self.elements.len != other.*.list.elements.len) return false;
            for (self.elements, other.*.list.elements) |*i, *j| {
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

        pub fn dupe(self: *const @This(), allocator: std.mem.Allocator) !@This() {
            const new_elements = try allocator.alloc(Nbt, self.elements.len);
            for (new_elements, self.elements) |*new_element, *old_element| {
                new_element.* = try old_element.dupe(allocator);
            }
            return .{ .element_type = self.element_type, .elements = new_elements };
        }
    };

    pub const Compound = struct {
        elements: std.StringHashMapUnmanaged(Nbt),

        pub fn init(
            allocator: std.mem.Allocator,
            initializer: anytype,
        ) !@This() {
            var compound: @This() = .{
                .elements = .{},
            };
            inline for (@typeInfo(@TypeOf(initializer)).@"struct".field_names) |field_name| {
                const name = try allocator.dupe(u8, field_name);
                try compound.elements.put(allocator, name, @field(initializer, field_name));
            }
            return compound;
        }

        pub fn write(self: *const @This(), buffer: *C2S.WriteBuffer) WriteError!void {
            var entries = self.elements.iterator();
            while (entries.next()) |entry| {
                const key = entry.key_ptr.*;
                const element = entry.value_ptr;
                try element.writeWithName(buffer, key);
            }
            // write end
            var end: Nbt = .{ .end = .{} };
            try end.writeBlankName(buffer);
        }

        pub fn read(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) ReadError!@This() {
            var elements = std.StringHashMapUnmanaged(Nbt){};

            var read_result = try Nbt.readWithName(allocator, buffer);
            while (read_result.element != .end) : (read_result = try Nbt.readWithName(allocator, buffer)) {
                try elements.put(allocator, read_result.name.?, read_result.element);
            }

            return .{
                .elements = elements,
            };
        }

        pub fn deepEquals(self: *const @This(), other: *const Nbt) bool {
            if (other.* != .compound) return false;
            if (self.elements.size != other.*.compound.elements.size) return false;
            var self_entries = self.elements.iterator();
            while (self_entries.next()) |self_entry| {
                if (other.*.compound.elements.getPtr(self_entry.key_ptr.*)) |other_element| {
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

        pub fn dupe(self: @This(), allocator: std.mem.Allocator) !@This() {
            var new_elements: std.StringHashMapUnmanaged(Nbt) = .{};
            var iterator = self.elements.iterator();
            while (iterator.next()) |entry| {
                try new_elements.put(allocator, try allocator.dupe(u8, entry.key_ptr.*), try entry.value_ptr.dupe(allocator));
            }
            return .{ .elements = new_elements };
        }
    };

    pub const IntArray = struct {
        values: []const i32,

        pub fn init(
            allocator: std.mem.Allocator,
            values: []const i32,
        ) !@This() {
            return .{
                .values = try allocator.dupe(i32, values),
            };
        }

        pub fn write(self: *const @This(), buffer: *C2S.WriteBuffer) WriteError!void {
            try buffer.write(i32, @intCast(self.values.len));
            for (self.values) |element| {
                try buffer.write(i32, element);
            }
        }

        pub fn read(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) ReadError!@This() {
            const element_count: usize = @intCast(try buffer.read(i32));

            const values = try allocator.alloc(i32, element_count);
            for (values) |*value| {
                value.* = try buffer.read(i32);
            }
            return .{
                .values = values,
            };
        }

        pub fn deepEquals(self: *const @This(), other: *const Nbt) bool {
            if (other.* != .int_array) return false;
            return std.mem.eql(i32, self.values, other.int_array.values);
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            allocator.free(self.values);
        }

        pub fn dupe(self: *const @This(), allocator: std.mem.Allocator) !@This() {
            return .{ .values = try allocator.dupe(i32, self.values) };
        }
    };
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

test Nbt {
    var nbt: Nbt = .{
        .compound = try .init(
            std.testing.allocator,
            .{
                .foo = Nbt{ .byte = .{ .value = 121 } },
                .bar = Nbt{ .int_array = try .init(
                    std.testing.allocator,
                    @as([]const i32, &.{ 0xEADBEEF, 0xCAB1312, 0xAFEBABE }),
                ) },
                .qux = Nbt{ .double = .{ .value = 52.1 } },
                .foobar = Nbt{
                    .list = try .init(.double, std.testing.allocator, &.{
                        .{ .value = 1 },
                        .{ .value = 52 },
                        .{ .value = 15 },
                    }),
                },
            },
        ),
    };
    defer nbt.deinit(std.testing.allocator);

    var buffer: C2S.WriteBuffer = .initBuffer(try std.testing.allocator.alloc(u8, 4096));
    defer buffer.backer.deinit(std.testing.allocator);

    try nbt.writeBlankName(&buffer);

    var read_buffer = buffer.toReadBuffer();

    var read_nbt: Nbt = try .readDiscardName(std.testing.allocator, &read_buffer);
    defer read_nbt.deinit(std.testing.allocator);

    try std.testing.expect(nbt.deepEquals(&read_nbt));
}
