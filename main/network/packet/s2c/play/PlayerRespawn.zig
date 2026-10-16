const main = @import("main");
const std = @import("std");

const S2C = main.network.packet.S2C;
const Client = main.Client;

const Difficulty = main.World.Difficulty;
const GameMode = main.World.GameMode;
const GeneratorType = main.World.GeneratorType;

dimension_id: i32,
difficulty: Difficulty,
game_mode: GameMode,
generator_type: GeneratorType,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;

    return .{
        .dimension_id = try buffer.read(i32),
        .difficulty = (try buffer.readPacked(packed struct { difficulty: Difficulty, _: u6 })).difficulty,
        .game_mode = std.enums.fromInt(GameMode, try buffer.read(u8)) orelse .Survival,
        .generator_type = GeneratorType.keys.get(try buffer.readStringNonAllocating(16)) orelse .Default,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
