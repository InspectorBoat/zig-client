const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const Vector2xz = @import("../../../../math/vector.zig").Vector2xz;
const WorldChunkS2CPacket = @import("../../../../network/packet/s2c/play/WorldChunkS2CPacket.zig");

chunk_positions: []const Vector2xz(i32),
chunk_datas: []ChunkData,
has_light: bool,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    const has_sky_light = try buffer.read(bool);
    const chunk_count: usize = @intCast(try buffer.readVarInt());
    std.debug.assert(chunk_count >= 0);
    const chunk_positions = try allocator.alloc(Vector2xz(i32), chunk_count);
    const chunk_datas = try allocator.alloc(ChunkData, chunk_count);

    // add chunk position and allocate chunk data slice
    for (chunk_positions, chunk_datas) |*chunk_pos, *chunk_data| {
        chunk_pos.* = .{
            .x = try buffer.read(i32),
            .z = try buffer.read(i32),
        };
        const section_bitfield: std.bit_set.IntegerBitSet(16) = .{ .mask = try buffer.read(u16) };
        chunk_data.* = ChunkData{
            .sections = section_bitfield,
            .buffer = try ReadPacketBuffer.initCapacity(allocator, findBufferSize(section_bitfield, has_sky_light)),
        };
    }

    // copy chunk data slice
    for (chunk_datas) |chunk_data| {
        const bytes = try buffer.readBytesNonAllocating(chunk_data.buffer.backer.len);
        @memcpy(@constCast(chunk_data.buffer.backer), bytes);
    }
    return @This(){
        .chunk_positions = chunk_positions,
        .chunk_datas = chunk_datas,
        .has_light = has_sky_light,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    switch (game.*) {
        .Ingame => |*ingame| {
            for (self.chunk_positions, self.chunk_datas) |chunk_pos, *chunk_data| {
                _ = try ingame.world.loadChunk(chunk_pos);
                try ingame.world.receiveChunk(chunk_pos, chunk_data, true, true, allocator);
            }
        },
        else => unreachable,
    }
}

pub fn findBufferSize(sections: std.bit_set.IntegerBitSet(16), has_sky_light: bool) usize {
    const section_count = @as(i32, @intCast(sections.count()));
    const block_states = section_count * 2 * 4096;
    const block_light = section_count * @divExact(4096, 2);
    const sky_light = if (has_sky_light) block_light else 0;
    const biomes = 256;
    return @intCast(block_states + block_light + sky_light + biomes);
}

pub const ChunkData = WorldChunkS2CPacket.ChunkData;
