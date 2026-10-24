chunks: std.AutoHashMapUnmanaged(Vector2xz(i32), ChunkCompileStatus) = .empty,

pub const init: @This() = .{};

pub const ChunkCompileStatus = union(enum) {
    waiting: MissingNeighbors,
    rendering: [16]SectionCompileStatus,
};

pub const MissingNeighbors = struct {
    north_present: bool = true,
    south_present: bool = true,
    west_present: bool = true,
    east_present: bool = true,

    pub fn isReady(self: @This()) bool {
        return self.north_present and
            self.south_present and
            self.west_present and
            self.east_present;
    }
};

pub const SectionCompileStatus = struct {
    /// Current revision of chunk.
    current_revision: u32 = 0,
    /// Latest revision of chunk sent to compile thread(s). Null if chunk has never been sent to compile threads.
    /// This can lag behind current_revision if the section is empty
    latest_sent_revision: ?u32 = null,
    /// Latest revision of chunk (as mesh data) received from compile thread. Null if chunk has never been received from compile thread.
    latest_received_revision: ?u32 = null,
    /// Segment of memory uploaded into VRAM
    render_info: ?SectionRenderInfo = null,

    pub fn markDirty(self: *@This()) void {
        self.current_revision += 1;
    }
    pub fn alertCompilationRecieved(self: *@This(), revision: u32) error{ DuplicateRevision, OutdatedRevision }!void {
        if (revision == self.latest_received_revision) {
            std.debug.print(
                "current: {} sent: {?}  recieved: {?} new: {}\n",
                .{ self.current_revision, self.latest_sent_revision, self.latest_received_revision, revision },
            );
            return error.DuplicateRevision;
        }
        if (revision != self.latest_sent_revision) return error.OutdatedRevision;
        self.latest_received_revision = revision;
    }
    pub fn needsRecompile(self: @This()) bool {
        if (self.latest_sent_revision == null) return true;
        return self.current_revision > self.latest_sent_revision.?;
    }
    pub fn alertCompilationDispatch(self: *@This()) void {
        std.debug.assert(self.latest_sent_revision != self.current_revision);
        self.latest_sent_revision = self.current_revision;
    }
    pub fn replaceRenderInfo(self: *@This(), new_render_info: ?SectionRenderInfo, gpu_memory_allocator: *GpuMemoryAllocator) !void {
        if (self.render_info) |old_render_info| {
            try gpu_memory_allocator.free(old_render_info.segment);
        }
        self.render_info = new_render_info;
    }
};

pub const SectionRenderInfo = struct {
    segment: GpuMemoryAllocator.Segment,
    quads: usize,
};

pub fn markChunkPresent(self: *@This(), allocator: std.mem.Allocator, chunk_pos: Vector2xz(i32)) !void {
    if (self.chunks.contains(chunk_pos)) return error.ChunkAlreadyExists;

    var new_chunk_neighbors: MissingNeighbors = .{};

    if (self.chunks.getPtr(chunk_pos.add(.{ .x = 0, .z = -1 }))) |north| {
        new_chunk_neighbors.north_present = true;
        switch (north.*) {
            .waiting => |*neighbors| neighbors.south_present = true,
            .rendering => |*sections| for (sections) |*section| section.markDirty(),
        }
    }
    if (self.chunks.getPtr(chunk_pos.add(.{ .x = 0, .z = 1 }))) |south| {
        new_chunk_neighbors.south_present = true;
        switch (south.*) {
            .waiting => |*neighbors| neighbors.north_present = true,
            .rendering => |*sections| for (sections) |*section| section.markDirty(),
        }
    }
    if (self.chunks.getPtr(chunk_pos.add(.{ .x = -1, .z = 0 }))) |west| {
        new_chunk_neighbors.west_present = true;
        switch (west.*) {
            .waiting => |*neighbors| neighbors.east_present = true,
            .rendering => |*sections| for (sections) |*section| section.markDirty(),
        }
    }
    if (self.chunks.getPtr(chunk_pos.add(.{ .x = 1, .z = 0 }))) |east| {
        new_chunk_neighbors.east_present = true;
        switch (east.*) {
            .waiting => |*neighbors| neighbors.west_present = true,
            .rendering => |*sections| for (sections) |*section| section.markDirty(),
        }
    }

    try self.chunks.put(allocator, chunk_pos, .{ .waiting = new_chunk_neighbors });
}

pub fn markBlockPosDirty(self: *@This(), block_pos: Vector3(i32)) !void {
    const chunk = self.chunks.getPtr(.{ .x = @divFloor(block_pos.x, 16), .z = @divFloor(block_pos.z, 16) }) orelse return;
    switch (chunk.*) {
        .rendering => |*sections| {
            sections[@intCast(@divFloor(block_pos.y, 16))].markDirty();
        },
        .waiting => return,
    }
}

pub fn markAreaDirty(self: *@This(), block_pos_min: Vector3(i32), block_pos_max: Vector3(i32)) !void {
    const min_section_pos: Vector3(i32) = .sub(.divFloor(block_pos_min, .splat(16)), .splat(1));
    const max_section_pos: Vector3(i32) = .add(.divFloor(block_pos_max, .splat(16)), .splat(1));

    var x: i32 = min_section_pos.x;
    while (x <= max_section_pos.x) : (x += 1) {
        var y: i32 = @max(min_section_pos.y, 0);
        while (y <= @min(max_section_pos.y, 15)) : (y += 1) {
            var z: i32 = min_section_pos.z;
            while (z <= max_section_pos.z) : (z += 1) {
                const chunk = self.chunks.getPtr(.{ .x = x, .z = z }) orelse continue;
                switch (chunk.*) {
                    .rendering => |*sections| {
                        sections[@intCast(y)].markDirty();
                    },
                    .waiting => continue,
                }
            }
        }
    }
}

pub fn removeChunk(self: *@This(), chunk_pos: Vector2xz(i32)) void {
    std.debug.assert(self.chunks.remove(chunk_pos));
    if (self.chunks.getPtr(chunk_pos.add(.{ .x = 0, .z = -1 }))) |north| {
        if (north.* == .waiting) north.waiting.south_present = false;
    }
    if (self.chunks.getPtr(chunk_pos.add(.{ .x = 0, .z = 1 }))) |south| {
        if (south.* == .waiting) south.waiting.north_present = false;
    }
    if (self.chunks.getPtr(chunk_pos.add(.{ .x = -1, .z = 0 }))) |west| {
        if (west.* == .waiting) west.waiting.east_present = false;
    }
    if (self.chunks.getPtr(chunk_pos.add(.{ .x = 1, .z = 0 }))) |east| {
        if (east.* == .waiting) east.waiting.west_present = false;
    }
}

const std = @import("std");

const Vector2xz = @import("main").Vector2xz;
const Vector3 = @import("main").Vector3;

const GpuMemoryAllocator = @import("../GpuMemoryAllocator.zig");
