username: []u8,
uuid: []u8,
access_token: []u8,

const Foo = struct {
    baz: []Bar,
    const Bar = struct {
        qux: struct {
            id: u8,
        },
    };
};

pub noinline fn parseFromPrismLauncher(io: std.Io, gpa: std.mem.Allocator, file: std.Io.File) !@This() {
    var buffer: [1024]u8 = undefined;
    var file_reader = file.reader(io, &buffer);

    var reader: std.json.Reader = .init(gpa, &file_reader.interface);

    const json = try std.json.parseFromTokenSource(Foo, undefined, &reader, .{});
    std.mem.doNotOptimizeAway(json.value.baz[0]);
    _ = try gpa.dupe(u8, &.{});

    return undefined;
}

const std = @import("std");
