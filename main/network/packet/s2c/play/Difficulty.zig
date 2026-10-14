const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

const Difficulty = root.World.Difficulty;

difficulty: Difficulty,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;
    return .{
        .difficulty = (try buffer.readPacked(packed struct { difficulty: Difficulty, _: u6 })).difficulty,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    game.world.difficulty = self.difficulty;
}
