const std = @import("std");
const CompilationResult = @import("CompilationTask.zig").CompilationResult;

const SectionNode = struct {
    node: std.SinglyLinkedList.Node,
    section: CompilationResult,
};

fn listEntry(node: *std.SinglyLinkedList.Node) *SectionNode {
    return @fieldParentPtr("node", node);
}

sections: std.SinglyLinkedList = .{},
mutex: @import("llm-code-quarantine").Mutex = .{},
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) @This() {
    return .{ .allocator = allocator };
}

pub fn add(self: *@This(), section: CompilationResult) !void {
    const entry = try self.allocator.create(SectionNode);
    entry.* = .{
        .node = .{ .next = null },
        .section = section,
    };

    self.mutex.lock();
    defer self.mutex.unlock();

    self.sections.prepend(&entry.node);
}

pub fn pop(self: *@This()) ?CompilationResult {
    const maybe_node = blk: {
        self.mutex.lock();
        defer self.mutex.unlock();

        break :blk self.sections.popFirst();
    };

    if (maybe_node) |node| {
        const entry = listEntry(node);
        defer self.allocator.destroy(entry);
        return entry.section;
    } else return null;
}
