const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

const Vector3 = root.Vector3;

block_pos: Vector3(i32),
state: u16,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;

    return .{
        .block_pos = try buffer.readBlockPos(),
        .state = @bitCast(@as(u16, @intCast(try buffer.readVarInt()))),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    try game.world.setBlockState(
        allocator,
        self.block_pos,
        .validateRaw(self.state),
    );
}
