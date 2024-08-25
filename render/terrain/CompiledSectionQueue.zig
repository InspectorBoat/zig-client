const std = @import("std");
const CompiledSection = @import("SectionCompileTask.zig").CompiledSection;

sections: std.SinglyLinkedList(CompiledSection) = .{},
mutex: std.Thread.Mutex = .{},
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) @This() {
    return .{ .allocator = allocator };
}

pub fn add(self: *@This(), section: CompiledSection) !void {
    const node = try self.allocator.create(std.SinglyLinkedList(CompiledSection).Node);

    self.mutex.lock();
    defer self.mutex.unlock();

    node.* = .{
        .data = section,
    };
    self.sections.prepend(node);
}

pub fn pop(self: *@This()) ?CompiledSection {
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
