pub const Nbt = union(Tag) {
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

        pub fn read(buffer: *S2C.ReadBuffer) !@This() {
            return std.enums.fromInt(@This(), try buffer.read(i8)) orelse return error.InvalidNbtTag;
        }
        pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
            try buffer.write(i8, @backingInt(self));
        }
    };

    pub const ReadError = error{
        OutOfMemory,
        StringTooLarge,
        EndOfBuffer,
        InvalidNbtTag,
        BadListLength,
    };

    pub const WriteError = error{
        OutOfMemory,
        StringTooLarge,
    };

    pub fn writeBlankName(self: *const @This(), buffer: *C2S.WriteBuffer) WriteError!void {
        try self.writeWithName(buffer, "");
    }

    pub fn writeWithName(self: *const @This(), buffer: *C2S.WriteBuffer, name: []const u8) WriteError!void {
        try @as(Tag, self.*).write(buffer);
        switch (self.*) {
            .end => {},
            inline else => |*known_element| {
                try buffer.writeJavaUtf(name);
                try known_element.write(buffer);
            },
        }
    }

    pub fn readDiscardName(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) ReadError!@This() {
        switch (try Tag.read(buffer)) {
            .end => return .end,

            inline else => |tag| {
                _ = try buffer.readJavaUtfNonAllocating();
                return @unionInit(
                    Nbt,
                    @tagName(tag),
                    try .read(allocator, buffer),
                );
            },
        }
    }

    pub fn readWithName(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) ReadError!struct { name: ?[]const u8, nbt: Nbt } {
        switch (try Tag.read(buffer)) {
            .end => return .{ .name = null, .nbt = .end },

            inline else => |tag| {
                const name = try buffer.readJavaUtfAllocating(allocator);
                return .{
                    .name = name,
                    .nbt = @unionInit(
                        Nbt,
                        @tagName(tag),
                        try .read(allocator, buffer),
                    ),
                };
            },
        }
    }

    pub fn deepEquals(lhs: *const @This(), rhs: *const @This()) bool {
        if (@as(Tag, lhs.*) != @as(Tag, rhs.*)) return false;
        switch (lhs.*) {
            inline else => |known_lhs, tag| {
                return known_lhs.deepEquals(&@field(rhs, @tagName(tag)));
            },
        }
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        switch (self.*) {
            inline else => |*element| {
                element.deinit(allocator);
            },
        }
    }

    pub fn dupe(self: *const @This(), allocator: std.mem.Allocator) error{OutOfMemory}!@This() {
        switch (self.*) {
            inline else => |*element, tag| {
                return @unionInit(@This(), @tagName(tag), try element.dupe(allocator));
            },
        }
    }

    pub const End = struct {
        pub fn write(_: *const @This(), _: *C2S.WriteBuffer) WriteError!void {}

        pub fn read(_: std.mem.Allocator, _: *S2C.ReadBuffer) ReadError!@This() {
            return .{};
        }

        pub fn deepEquals(_: *const @This(), _: *const @This()) bool {
            return true;
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

            pub fn deepEquals(lhs: *const @This(), rhs: *const @This()) bool {
                return lhs.value == rhs.value;
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
        items: []const i8,

        pub fn write(self: *const @This(), buffer: *C2S.WriteBuffer) WriteError!void {
            try buffer.write(i32, @intCast(self.items.len));
            for (self.items) |item| {
                try buffer.write(i32, @intCast(item));
            }
        }

        pub fn read(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) ReadError!@This() {
            const len: usize = @intCast(try buffer.read(i32));
            const items = try allocator.alloc(i8, len);
            const bytes = try buffer.readBytesNonAllocating(len * @sizeOf(i8));

            @memcpy(items, @as([]const i8, @ptrCast(bytes)));

            return .{
                .items = items,
            };
        }

        pub fn deepEquals(lhs: *const @This(), rhs: *const @This()) bool {
            return std.mem.eql(i8, lhs.items, rhs.items);
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            allocator.free(self.items);
        }

        pub fn dupe(self: *const @This(), allocator: std.mem.Allocator) !@This() {
            return .{ .items = try allocator.dupe(i8, self.items) };
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

        pub fn deepEquals(lhs: *const @This(), rhs: *const @This()) bool {
            return std.mem.eql(u8, lhs.value, rhs.value);
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            allocator.free(self.value);
        }

        pub fn dupe(self: *const @This(), allocator: std.mem.Allocator) !@This() {
            return .{ .value = try allocator.dupe(u8, self.value) };
        }
    };

    pub const List = struct {
        bytes: [*]u8,
        len: usize,
        tag: Tag,

        pub fn init(
            allocator: std.mem.Allocator,
            comptime tag: Tag,
            init_items: []const @FieldType(Nbt, @tagName(tag)),
        ) !@This() {
            const _items = try allocator.alloc(@FieldType(Nbt, @tagName(tag)), init_items.len);
            @memcpy(_items, init_items);
            return .{
                .bytes = @ptrCast(_items.ptr),
                .len = _items.len,
                .tag = tag,
            };
        }

        pub fn write(self: *const @This(), buffer: *C2S.WriteBuffer) WriteError!void {
            try self.tag.write(buffer);
            try buffer.write(i32, @intCast(self.len));

            switch (self.tag) {
                inline else => |known_tag| {
                    for (self.items(known_tag)) |*item| {
                        try item.write(buffer);
                    }
                },
            }
        }

        pub fn read(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) ReadError!@This() {
            const tag: Tag = try .read(buffer);
            const len: usize = @intCast(try buffer.read(i32));

            if (tag == .end and len != 0) return error.BadListLength;

            switch (tag) {
                inline else => |known_tag| {
                    const Item = @FieldType(Nbt, @tagName(known_tag));
                    const _items = try allocator.alloc(Item, len);
                    for (_items) |*item| {
                        item.* = try .read(allocator, buffer);
                    }
                    return .{
                        .bytes = @ptrCast(_items),
                        .len = _items.len,
                        .tag = tag,
                    };
                },
            }
        }

        pub fn items(self: *const @This(), comptime tag: Tag) []@FieldType(Nbt, @tagName(tag)) {
            std.debug.assert(tag == self.tag);
            return @as(
                [*]@FieldType(Nbt, @tagName(tag)),
                @ptrCast(@alignCast(self.bytes)),
            )[0..self.len];
        }

        pub fn deepEquals(lhs: *const @This(), rhs: *const @This()) bool {
            if (lhs.len != rhs.len) return false;
            if (lhs.tag != rhs.tag) return false;
            switch (lhs.tag) {
                inline else => |tag| {
                    for (lhs.items(tag), rhs.items(tag)) |*i, *j| {
                        if (!i.deepEquals(j)) return false;
                    }
                    return true;
                },
            }
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            switch (self.tag) {
                inline else => |tag| {
                    for (self.items(tag)) |*item| {
                        item.deinit(allocator);
                    }
                    allocator.free(self.items(tag));
                },
            }
        }

        pub fn dupe(self: *const @This(), allocator: std.mem.Allocator) !@This() {
            switch (self.tag) {
                inline else => |tag| {
                    return try .init(allocator, tag, self.items(tag));
                },
            }
        }
    };

    pub const Compound = struct {
        items: std.StringHashMapUnmanaged(Nbt),

        pub fn init(
            allocator: std.mem.Allocator,
            initializer: anytype,
        ) !@This() {
            var items: std.StringHashMapUnmanaged(Nbt) = .empty;
            inline for (@typeInfo(@TypeOf(initializer)).@"struct".field_names) |field_name| {
                const name = try allocator.dupe(u8, field_name);
                try items.put(allocator, name, @field(initializer, field_name));
            }
            return .{ .items = items };
        }

        pub fn write(self: *const @This(), buffer: *C2S.WriteBuffer) WriteError!void {
            var entries = self.items.iterator();
            while (entries.next()) |entry| {
                const key = entry.key_ptr.*;
                const item = entry.value_ptr;
                try item.writeWithName(buffer, key);
            }

            try Tag.end.write(buffer);
        }

        pub fn read(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) ReadError!@This() {
            var items: std.StringHashMapUnmanaged(Nbt) = .empty;

            var read_result = try Nbt.readWithName(allocator, buffer);
            while (read_result.nbt != .end) : (read_result = try Nbt.readWithName(allocator, buffer)) {
                try items.put(allocator, read_result.name.?, read_result.nbt);
            }

            return .{ .items = items };
        }

        pub fn deepEquals(lhs: *const @This(), rhs: *const @This()) bool {
            if (lhs.items.size != rhs.items.size) return false;
            var lhs_entries = lhs.items.iterator();
            while (lhs_entries.next()) |lhs_entry| {
                const rhs_item = rhs.items.getPtr(lhs_entry.key_ptr.*) orelse return false;
                const lhs_item = lhs_entry.value_ptr;
                if (!lhs_item.deepEquals(rhs_item)) return false;
            }
            return true;
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            var entries = self.items.iterator();
            while (entries.next()) |*entry| {
                const name = entry.key_ptr.*;
                allocator.free(name);
                const item = entry.value_ptr;
                item.deinit(allocator);
            }
            self.items.deinit(allocator);
        }

        pub fn dupe(self: @This(), allocator: std.mem.Allocator) !@This() {
            var new_items: std.StringHashMapUnmanaged(Nbt) = .empty;
            try new_items.ensureTotalCapacity(allocator, self.items.size);

            var iterator = self.items.iterator();
            while (iterator.next()) |entry| {
                new_items.putAssumeCapacityNoClobber(
                    try allocator.dupe(u8, entry.key_ptr.*),
                    try entry.value_ptr.dupe(allocator),
                );
            }
            return .{ .items = new_items };
        }
    };

    pub const IntArray = struct {
        items: []const i32,

        pub fn init(
            allocator: std.mem.Allocator,
            values: []const i32,
        ) !@This() {
            return .{
                .items = try allocator.dupe(i32, values),
            };
        }

        pub fn write(self: *const @This(), buffer: *C2S.WriteBuffer) WriteError!void {
            try buffer.write(i32, @intCast(self.items.len));
            for (self.items) |item| {
                try buffer.write(i32, item);
            }
        }

        pub fn read(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) ReadError!@This() {
            const len: usize = @intCast(try buffer.read(i32));

            const items = try allocator.alloc(i32, len);
            for (items) |*item| {
                item.* = try buffer.read(i32);
            }
            return .{ .items = items };
        }

        pub fn deepEquals(lhs: *const @This(), rhs: *const @This()) bool {
            return std.mem.eql(i32, lhs.items, rhs.items);
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            allocator.free(self.items);
        }

        pub fn dupe(self: *const @This(), allocator: std.mem.Allocator) !@This() {
            return .{ .items = try allocator.dupe(i32, self.items) };
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
                    .list = try .init(std.testing.allocator, .double, &.{
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

    try std.testing.expectEqual(15, nbt.compound.items.getPtr("foobar").?.list.items(.double)[2].value);
}

test "dupe" {
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
                    .list = try .init(std.testing.allocator, .double, &.{
                        .{ .value = 1 },
                        .{ .value = 52 },
                        .{ .value = 15 },
                    }),
                },
            },
        ),
    };
    defer nbt.deinit(std.testing.allocator);

    var duped = try nbt.dupe(std.testing.allocator);
    defer duped.deinit(std.testing.allocator);

    duped.compound.items.getPtr("foobar").?.list.items(.double)[2].value = 0.2;
    try std.testing.expectEqual(15, nbt.compound.items.getPtr("foobar").?.list.items(.double)[2].value);

    duped.compound.items.getPtr("bar").?.deinit(std.testing.allocator);
    std.testing.allocator.free(duped.compound.items.fetchRemove("bar").?.key);
    duped.compound.items.getPtr("qux").?.deinit(std.testing.allocator);
    std.testing.allocator.free(duped.compound.items.fetchRemove("qux").?.key);

    try std.testing.expectEqual(4, nbt.compound.items.size);
}

const std = @import("std");

const main = @import("main");

const C2S = main.network.packet.C2S;
const S2C = main.network.packet.S2C;
