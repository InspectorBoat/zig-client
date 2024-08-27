const std = @import("std");
const Vector2xz = @import("root").Vector2xz;
const Vector3 = @import("root").Vector3;

chunks: std.AutoHashMap(Vector2xz(i32), ChunkCompileStatus),

const ChunkCompileStatus = union(enum) {
    Waiting: MissingNeighbors,
    Rendering: [16]SectionCompileStatus,

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
        latest_sent_revision: ?u32 = null,
        /// Latest reviion of chunk (as mesh data) received from compile thread. Null if chunk has never been received from compile thread.
        latest_received_revision: ?u32 = null,

        pub fn needsRecompile(self: @This()) bool {
            return self.current_revision > self.latest_sent_revision orelse return true;
        }
        pub fn bumpRevision(self: *@This()) void {
            self.current_revision += 1;
        }
    };
};

pub fn init(allocator: std.mem.Allocator) @This() {
    return .{ .chunks = std.AutoHashMap(Vector2xz(i32), ChunkCompileStatus).init(allocator) };
}

pub fn markChunkPresent(self: *@This(), chunk_pos: Vector2xz(i32)) !void {
    if (self.chunks.contains(chunk_pos)) return error.ChunkAlreadyExists;

    var new_chunk_neighbors: ChunkCompileStatus.MissingNeighbors = .{};

    if (self.chunks.getPtr(chunk_pos.add(.{ .x = 0, .z = -1 }))) |north| {
        new_chunk_neighbors.north_present = true;
        switch (north.*) {
            .Waiting => |*neighbors| neighbors.south_present = true,
            .Rendering => |*sections| for (sections) |*section| section.bumpRevision(),
        }
    }
    if (self.chunks.getPtr(chunk_pos.add(.{ .x = 0, .z = 1 }))) |south| {
        new_chunk_neighbors.south_present = true;
        switch (south.*) {
            .Waiting => |*neighbors| neighbors.north_present = true,
            .Rendering => |*sections| for (sections) |*section| section.bumpRevision(),
        }
    }
    if (self.chunks.getPtr(chunk_pos.add(.{ .x = -1, .z = 0 }))) |west| {
        new_chunk_neighbors.west_present = true;
        switch (west.*) {
            .Waiting => |*neighbors| neighbors.east_present = true,
            .Rendering => |*sections| for (sections) |*section| section.bumpRevision(),
        }
    }
    if (self.chunks.getPtr(chunk_pos.add(.{ .x = 1, .z = 0 }))) |east| {
        new_chunk_neighbors.east_present = true;
        switch (east.*) {
            .Waiting => |*neighbors| neighbors.west_present = true,
            .Rendering => |*sections| for (sections) |*section| section.bumpRevision(),
        }
    }

    try self.chunks.put(chunk_pos, .{ .Waiting = new_chunk_neighbors });
}

pub fn markBlockPosDirty(self: *@This(), block_pos: Vector3(i32)) !void {
    _ = self;
    _ = block_pos;
}

pub fn removeChunk(self: *@This(), chunk_pos: Vector2xz(i32)) void {
    _ = self.chunks.remove(chunk_pos);
    if (self.chunks.getPtr(chunk_pos.add(.{ .x = 0, .z = -1 }))) |north| {
        if (north.* == .Waiting) north.Waiting.south_present = false;
    }
    if (self.chunks.getPtr(chunk_pos.add(.{ .x = 0, .z = 1 }))) |south| {
        if (south.* == .Waiting) south.Waiting.north_present = false;
    }
    if (self.chunks.getPtr(chunk_pos.add(.{ .x = -1, .z = 0 }))) |west| {
        if (west.* == .Waiting) west.Waiting.east_present = false;
    }
    if (self.chunks.getPtr(chunk_pos.add(.{ .x = 1, .z = 0 }))) |east| {
        if (east.* == .Waiting) east.Waiting.west_present = false;
    }
}
