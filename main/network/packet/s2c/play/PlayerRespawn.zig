const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

const Difficulty = root.World.Difficulty;
const GameMode = root.World.GameMode;
const GeneratorType = root.World.GeneratorType;

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
