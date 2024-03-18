const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");

const Vector2 = @import("../../../../type/vector.zig").Vector2;
const Vector3 = @import("../../../../type/vector.zig").Vector3;
const RawBlockState = @import("../../../../block/block.zig").RawBlockState;
const FilteredBlockState = @import("../../../../block/block.zig").FilteredBlockState;

chunk_pos: Vector2(i32),
updates: []const BlockUpdate,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    const chunk_pos = Vector2(i32){ .x = try buffer.read(i32), .z = try buffer.read(i32) };
    const updates = try allocator.alloc(BlockUpdate, @intCast(try buffer.readVarInt()));
    errdefer allocator.free(updates);

    for (updates) |*update| {
        const pos = try buffer.readPacked(packed struct { y: u8, z: u4, x: u4 });
        update.pos = .{ .x = pos.x, .y = pos.y, .z = pos.z };
        const raw: RawBlockState = @bitCast(@as(u16, @intCast(try buffer.readVarInt())));
        update.state = raw.toFiltered();
    }

    return @This(){
        .chunk_pos = chunk_pos,
        .updates = updates,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    switch (game.*) {
        .Ingame => |*ingame| {
            for (self.updates) |update| {
                ingame.world.setBlockState(.{
                    .x = self.chunk_pos.x * 16 + update.pos.x,
                    .y = update.pos.y,
                    .z = self.chunk_pos.z * 16 + update.pos.z,
                }, update.state);
            }
        },
        else => unreachable,
    }
    _ = allocator;
}

pub const BlockUpdate = struct {
    pos: Vector3(i32),
    state: FilteredBlockState,
};
