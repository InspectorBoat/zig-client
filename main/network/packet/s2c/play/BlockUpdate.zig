const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Game = root.Game;
const Vector3 = @import("../../../../math/vector.zig").Vector3;
const RawBlockState = @import("../../../../block/block.zig").RawBlockState;
const ConcreteBlockState = @import("../../../../block/block.zig").ConcreteBlockState;

block_pos: Vector3(i32),
state: RawBlockState,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;

    return .{
        .block_pos = try buffer.readBlockPos(),
        .state = @bitCast(@as(u16, @intCast(try buffer.readVarInt()))),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    switch (game.*) {
        .Ingame => |*ingame| {
            try ingame.world.setBlockState(
                self.block_pos,
                self.state.toFiltered().toConcrete(),
                allocator,
            );
        },
        else => unreachable,
    }
}
