const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const Vector2 = @import("../../../../math/vector.zig").Vector2;
const Chunk = @import("../../../../world/Chunk.zig");
const Section = @import("../../../../world/Section.zig");
const RawBlockState = @import("../../../../block/block.zig").RawBlockState;
const FilteredBlockState = @import("../../../../block/block.zig").FilteredBlockState;

chunk_pos: Vector2(i32),
chunk_data: ChunkData,
full: bool,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    return @This(){
        .chunk_pos = Vector2(i32){
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
            // if full, load new chunk, otherwise fetch existing chunk
            // if not full,
            const chunk = if (self.full) chunk: {
                // create or destroy the chunk
                if (self.chunk_data.sections.count() == 0) {
                    ingame.world.unloadChunk(self.chunk_pos, allocator);
                    return;
                } else {
                    break :chunk try ingame.world.loadChunk(self.chunk_pos);
                }
            } else chunk: {
                break :chunk ingame.world.chunks.getPtr(self.chunk_pos).?;
            };
            @import("log").update_chunk(.{self.chunk_pos});
            try updateChunk(self.chunk_pos, chunk, &self.chunk_data, self.full, true, allocator);
        },
        else => unreachable,
    }
}

pub fn updateChunk(
    pos: Vector2(i32),
    chunk: *Chunk,
    chunk_data: *ChunkData,
    full: bool,
    has_sky_light: bool,
    allocator: std.mem.Allocator,
) !void {
    const start = try std.time.Instant.now();
    // copy block state data
    for (0..16) |section_y| {
        if (chunk_data.sections.isSet(@intCast(section_y))) {
            if (chunk.sections[section_y] == null) {
                chunk.sections[section_y] = try allocator.create(Section);
            }
            const section = chunk.sections[section_y].?;

            const raw_block_states = @as(*align(1) const [4096]RawBlockState, @ptrCast(try chunk_data.buffer.readArrayNonAllocating(4096 * 2)));
            for (raw_block_states, &section.block_states) |raw_block_state, *concrete_block_state| {
                concrete_block_state.* = raw_block_state.toFiltered().toConcrete();
            }
        } else {
            if (full) {
                if (chunk.sections[section_y]) |section| {
                    allocator.destroy(section);
                    chunk.sections[section_y] = null;
                }
            }
        }
    }
    // copy block light data
    for (0..16) |section_y| {
        if (chunk_data.sections.isSet(@intCast(section_y))) {
            const section = chunk.sections[section_y].?;
            @memcpy(&section.block_light.bytes, try chunk_data.buffer.readArrayNonAllocating(2048));
        }
    }
    // copy sky light data
    if (has_sky_light) {
        for (0..16) |section_y| {
            if (chunk_data.sections.isSet(@intCast(section_y))) {
                const section = chunk.sections[section_y].?;
                @memcpy(&section.sky_light.bytes, try chunk_data.buffer.readBytesNonAllocating(2048));
            }
        }
    }
    // copy biome data
    if (full) {
        @memcpy(&chunk.biomes, try chunk_data.buffer.readBytesNonAllocating(256));
    }

    @import("log").recieved_chunk(.{@as(f64, @floatFromInt((try std.time.Instant.now()).since(start))) / @as(f64, std.time.ns_per_ms)});
    try @import("render").onChunkUpdate(pos, chunk);
}

pub const ChunkData = struct {
    buffer: ReadPacketBuffer,
    sections: std.bit_set.IntegerBitSet(16),
};
