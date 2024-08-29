const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const World = @import("../../../../world/World.zig");
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const GameMode = @import("../../../../world/gamemode.zig").GameMode;
const Difficulty = @import("../../../../world/difficulty.zig").Difficulty;
const GeneratorType = @import("../../../../world/generatortype.zig").GeneratorType;
const CustomPayloadC2SPacket = @import("../../../../network/packet/c2s/play/CustomPayloadC2SPacket.zig");
const LocalPlayerEntity = @import("../../../../entity/impl/player/LocalPlayerEntity.zig");

/// the network id of the player
network_id: i32,
hardcore: bool,
game_mode: GameMode,
dimension: i8,
difficulty: Difficulty,
max_player_count: u8,
generator_type: GeneratorType,
reduced_debug_info: bool,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    const network_id = try buffer.read(i32);
    const i = try buffer.read(u8);
    const hardcore = i & 8 == 8;
    const game_mode = std.meta.intToEnum(GameMode, i & ~@as(u8, 8)) catch .Survival;
    const dimension = try buffer.read(i8);
    const difficulty = (try buffer.readPacked(packed struct { difficulty: Difficulty, _: u6 })).difficulty;
    const max_player_count = try buffer.read(u8);
    const generator_type = GeneratorType.keys.get(try buffer.readStringNonAllocating(16)) orelse .Default;
    const reduced_debug_info = try buffer.read(bool);
    return .{
        .network_id = network_id,
        .hardcore = hardcore,
        .game_mode = game_mode,
        .dimension = dimension,
        .difficulty = difficulty,
        .max_player_count = max_player_count,
        .generator_type = generator_type,
        .reduced_debug_info = reduced_debug_info,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    switch (game.*) {
        .Connecting => |*connecting| {
            var world = try World.init(
                .{
                    .difficulty = self.difficulty,
                    .dimension = self.dimension,
                    .hardcore = self.hardcore,
                },
                LocalPlayerEntity{
                    .base = .{
                        .network_id = self.network_id,
                    },
                    .abilities = undefined,
                },
                allocator,
            );
            errdefer world.deinit(allocator);

            // send brand packet
            try connecting.connection_handle.sendPlayPacket(.{ .CustomPayload = .{
                .channel = "MC|Brand",
                .data = "vanilla",
            } });

            game.* = .{ .Ingame = .{
                .connection_handle = connecting.connection_handle,
                .gpa = connecting.gpa,
                .world = world,
            } };
        },
        else => unreachable,
    }
}
