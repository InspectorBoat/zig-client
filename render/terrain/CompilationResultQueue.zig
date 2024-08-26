const std = @import("std");
const CompilationResult = @import("SectionCompileTask.zig").CompilationResult;

sections: std.SinglyLinkedList(CompilationResult) = .{},
mutex: std.Thread.Mutex = .{},
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) @This() {
    return .{ .allocator = allocator };
}

pub fn add(self: *@This(), section: CompilationResult) !void {
    const node = try self.allocator.create(std.SinglyLinkedList(CompilationResult).Node);

    self.mutex.lock();
    defer self.mutex.unlock();

    node.* = .{
        .data = section,
    };
    self.sections.prepend(node);
}

pub fn pop(self: *@This()) ?CompilationResult {
    const maybe_node = blk: {
        self.mutex.lock();
        defer self.mutex.unlock();

        break :blk self.sections.popFirst();
    };

    if (maybe_node) |node| {
        defer self.allocator.destroy(node);
        return node.data;
    } else return null;
}
