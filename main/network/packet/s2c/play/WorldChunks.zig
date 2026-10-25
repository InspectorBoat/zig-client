chunk_positions: []const Vector2xz(i32),
chunk_datas: []ChunkData,
has_light: bool,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const has_sky_light = try buffer.read(bool);
    const chunk_count: usize = @intCast(try buffer.readVarInt());

    const chunk_positions = try allocator.alloc(Vector2xz(i32), chunk_count);
    const chunk_datas = try allocator.alloc(ChunkData, chunk_count);

    // add chunk position and allocate chunk data slice
    for (chunk_positions, chunk_datas) |*chunk_pos, *chunk_data| {
        chunk_pos.* = .{
            .x = try buffer.read(i32),
            .z = try buffer.read(i32),
        };
        const section_bitfield: std.bit_set.IntegerBitSet(16) = .{ .mask = try buffer.read(u16) };
        chunk_data.* = .{
            .sections = section_bitfield,
            .buffer = try allocator.alloc(u8, findBufferSize(section_bitfield, has_sky_light)),
        };
    }

    // copy chunk data slice
    for (chunk_datas) |chunk_data| {
        const bytes = try buffer.readBytesNonAllocating(chunk_data.buffer.len);
        @memcpy(chunk_data.buffer, bytes);
    }
    return .{
        .chunk_positions = chunk_positions,
        .chunk_datas = chunk_datas,
        .has_light = has_sky_light,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    for (self.chunk_positions, self.chunk_datas) |chunk_pos, chunk_data| {
        _ = try game.world.loadChunk(allocator, chunk_pos);
        try game.world.receiveChunk(allocator, chunk_pos, chunk_data, true, true);
    }
}

pub fn findBufferSize(sections: std.bit_set.IntegerBitSet(16), has_sky_light: bool) usize {
    const section_count = sections.count();

    const block_states = section_count * (16 * 16 * 16) * @sizeOf(Block.PhysicalState);
    const block_light = section_count * (16 * 16 * 16) / 2;
    const sky_light = if (has_sky_light) block_light else 0;
    const biomes = 16 * 16;
    return block_states + block_light + sky_light + biomes;
}

const std = @import("std");

const main = @import("main");

const Block = main.Block;
const Client = main.Client;
const Vector2xz = main.Vector2xz;
const S2C = main.network.packet.S2C;
pub const ChunkData = S2C.Play.WorldChunk.ChunkData;
