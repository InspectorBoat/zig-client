const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Game = root.Game;
const Vector3 = root.Vector3;
const RawBlockState = root.RawBlockState;
const ConcreteBlockState = root.ConcreteBlockState;

block_pos: Vector3(i32),
state: RawBlockState,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
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
