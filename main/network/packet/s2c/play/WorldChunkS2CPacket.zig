const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const Vector2xz = @import("../../../../math/vector.zig").Vector2xz;
const Chunk = @import("../../../../world/Chunk.zig");
const Section = @import("../../../../world/Section.zig");
const RawBlockState = @import("../../../../block/block.zig").RawBlockState;
const FilteredBlockState = @import("../../../../block/block.zig").FilteredBlockState;

chunk_pos: Vector2xz(i32),
chunk_data: ChunkData,
full: bool,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    return @This(){
        .chunk_pos = .{
            .x = try buffer.read(i32),
            .z = try buffer.read(i32),
        },
        .full = try buffer.read(bool),
        .chunk_data = ChunkData{
            .sections = .{ .mask = try buffer.read(u16) },
            .buffer = ReadPacketBuffer.fromOwnedSlice(try buffer.readByteSliceAllocating(allocator)),
        },
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    switch (game.*) {
        .Ingame => |*ingame| {
            // if full:
            // unload existing chunk if count is 0
            // otherwise load new chunk
            if (self.full) {
                if (self.chunk_data.sections.count() == 0) {
                    try ingame.world.unloadChunk(self.chunk_pos, allocator);
                    return;
                } else {
                    _ = try ingame.world.loadChunk(self.chunk_pos);
                }
            }
            try ingame.world.receiveChunk(self.chunk_pos, &self.chunk_data, self.full, true, allocator);
        },
        else => unreachable,
    }
}

pub const ChunkData = struct {
    buffer: ReadPacketBuffer,
    sections: std.bit_set.IntegerBitSet(16),
};
