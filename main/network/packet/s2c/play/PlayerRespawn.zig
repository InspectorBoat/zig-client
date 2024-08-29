const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Game = root.Game;
const Difficulty = @import("../../../../world/difficulty.zig").Difficulty;
const GameMode = @import("../../../../world/gamemode.zig").GameMode;
const GeneratorType = @import("../../../../world/generatortype.zig").GeneratorType;

world_height: i32,
difficulty: Difficulty,
game_mode: GameMode,
generator_type: GeneratorType,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    _ = buffer;
    return undefined;
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
