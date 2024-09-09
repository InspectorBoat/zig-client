const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

const Difficulty = root.World.Difficulty;

difficulty: Difficulty,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return .{
        .difficulty = (try buffer.readPacked(packed struct { difficulty: Difficulty, _: u6 })).difficulty,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    game.world.difficulty = self.difficulty;
}
