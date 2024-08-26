const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const Vector3 = @import("../../../../math/vector.zig").Vector3;
const RawBlockState = @import("../../../../block/block.zig").RawBlockState;
const ConcreteBlockState = @import("../../../../block/block.zig").ConcreteBlockState;

block_pos: Vector3(i32),
state: RawBlockState,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;

    return @This(){
        .block_pos = try buffer.readBlockPos(),
        .state = @bitCast(@as(u16, @intCast(try buffer.readVarInt()))),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    switch (game.*) {
        .Ingame => |*ingame| {
            try ingame.world.setBlockState(self.block_pos, self.state.toFiltered().toConcrete());
        },
        else => unreachable,
    }
}
