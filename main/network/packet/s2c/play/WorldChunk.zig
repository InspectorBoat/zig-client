const std = @import("std");

const main = @import("main");

const Client = main.Client;
const Vector2xz = main.Vector2xz;
const S2C = main.network.packet.S2C;

chunk_pos: Vector2xz(i32),
chunk_data: ChunkData,
full: bool,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    return .{
        .chunk_pos = .{
            .x = try buffer.read(i32),
            .z = try buffer.read(i32),
        },
        .full = try buffer.read(bool),
        .chunk_data = .{
            .sections = .{ .mask = try buffer.read(u16) },
            .buffer = .fromOwnedSlice(try buffer.readByteSliceAllocating(allocator)),
        },
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    // if full:
    // unload existing chunk if count is 0
    // otherwise load new chunk
    if (self.full) {
        if (self.chunk_data.sections.count() == 0) {
            game.world.unloadChunk(allocator, self.chunk_pos) catch {}; // TODO: Figure out why this happens
            return;
        } else {
            _ = game.world.loadChunk(allocator, self.chunk_pos) catch {}; // TODO: Figure out why this happens
        }
    }
    try game.world.receiveChunk(allocator, self.chunk_pos, &self.chunk_data, self.full, true);
}

pub const ChunkData = struct {
    buffer: S2C.ReadBuffer,
    sections: std.bit_set.Integer(16),
};
