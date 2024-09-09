const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

const Vector2xz = root.Vector2xz;
const Chunk = root.Chunk;
const Section = root.Section;
const RawBlockState = root.RawBlockState;
const FilteredBlockState = root.FilteredBlockState;

chunk_pos: Vector2xz(i32),
chunk_data: ChunkData,
full: bool,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    return .{
        .chunk_pos = .{
            .x = try buffer.read(i32),
            .z = try buffer.read(i32),
        },
        .full = try buffer.read(bool),
        .chunk_data = ChunkData{
            .sections = .{ .mask = try buffer.read(u16) },
            .buffer = .fromOwnedSlice(try buffer.readByteSliceAllocating(allocator)),
        },
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
    // if full:
    // unload existing chunk if count is 0
    // otherwise load new chunk
    if (self.full) {
        if (self.chunk_data.sections.count() == 0) {
            game.world.unloadChunk(self.chunk_pos, allocator) catch {}; // TODO: Figure out why this happens
            return;
        } else {
            _ = game.world.loadChunk(self.chunk_pos) catch {}; // TODO: Figure out why this happens
        }
    }
    try game.world.receiveChunk(self.chunk_pos, &self.chunk_data, self.full, true, allocator);
}

pub const ChunkData = struct {
    buffer: S2C.ReadBuffer,
    sections: std.bit_set.IntegerBitSet(16),
};
