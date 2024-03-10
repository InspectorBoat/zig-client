const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const Vector3 = @import("../../../../type/vector.zig").Vector3;
const RawBlockState = @import("../../../../block/block.zig").RawBlockState;
const FilteredBlockState = @import("../../../../block/block.zig").FilteredBlockState;

block_pos: Vector3(i32),
state: FilteredBlockState,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return @This(){
        .block_pos = try buffer.readBlockPos(),
        .state = RawBlockState.from_u16(@intCast(try buffer.readVarInt())).toFiltered(),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    switch (game.*) {
        .Ingame => |*ingame| {
            ingame.world.setBlockState(self.block_pos, self.state);
        },
        else => unreachable,
    }
}
