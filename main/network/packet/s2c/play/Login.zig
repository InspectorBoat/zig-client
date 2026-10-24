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
comptime required_client_state: Client.State = .connecting,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;
    const network_id = try buffer.read(i32);
    const i = try buffer.read(u8);
    const hardcore = i & 8 == 8;
    const game_mode = std.enums.fromInt(GameMode, i & ~@as(u8, 8)) orelse .Survival;
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

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, connecting: *Client.Connecting) !void {
    const gpa = connecting.gpa;

    const connection_handle = connecting.connection_handle;

    var world: World = try .init(
        io,
        allocator,
        .{
            .difficulty = self.difficulty,
            .game_mode = self.game_mode,
            .dimension = self.dimension,
            .hardcore = self.hardcore,
        },
        .{
            .base = .{
                .network_id = self.network_id,
                .step_height = 0.6,
            },
            .abilities = undefined,
        },
    );
    errdefer world.deinit(allocator);

    // send brand packet
    const brand = comptime blk: {
        var buf: [9]u8 = undefined;
        var scratch: main.network.packet.C2S.WriteBuffer = .initBuffer(&buf);
        scratch.writeJavaUtf("vanilla") catch unreachable;
        break :blk scratch.backer.items.*;
    };
    try connecting.connection_handle.sendPlayPacket(io, .{
        .custom_payload = .{
            .channel = "MC|Brand",
            .data = &brand,
        },
    });

    try connecting.connection_handle.sendPlayPacket(io, .{ .client_settings = .{
        .language = "English",
        .view_distance = 2,
        .chat_visibility = .Full,
        .chat_colors = true,
        .skin_layers = .{},
    } });

    const client: *Client = @alignCast(@fieldParentPtr("connecting", connecting));
    client.* = .{ .game = .{
        .gpa = gpa,

        .connection_handle = connection_handle,

        .world = world,
    } };
}

const std = @import("std");

const main = @import("main");

const Client = main.Client;
const World = main.World;
const Difficulty = World.Difficulty;
const GameMode = World.GameMode;
const GeneratorType = World.GeneratorType;
const S2C = main.network.packet.S2C;
