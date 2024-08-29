const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Game = root.Game;
const Difficulty = root.World.Difficulty;
const GameMode = root.World.GameMode;
const GeneratorType = root.World.GeneratorType;

world_height: i32,
difficulty: Difficulty,
game_mode: GameMode,
generator_type: GeneratorType,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    _ = buffer;
    return undefined;
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
