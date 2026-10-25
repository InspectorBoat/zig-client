event: Event,
data: f32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;

    return .{
        .event = @fromBackingInt(try buffer.read(u8)),
        .data = try buffer.read(f32),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;
    _ = allocator;

    switch (self.event) {
        .InvalidBed => {},
        .BeginRaining => {},
        .StopRaining => {},
        .SetGameMode => {
            // TODO: THIS IS FUCKED
            // use MathHelper.floor when it gets added
            game.world.game_mode = std.enums.fromInt(World.GameMode, @as(i32, @trunc(self.data))) orelse .Survival;
        },
        .OpenCredits => {},
        .DemoMessage => {},
        .PlayArrowHitSound => {},
        .SetRainDuration => {},
        .SetThunderDuration => {},
        .PlayElderGuardianJumpscare => {},
        _ => {},
    }
}

pub const Event = enum(i32) {
    InvalidBed = 0,
    BeginRaining = 1,
    StopRaining = 2,
    SetGameMode = 3,
    OpenCredits = 4,
    DemoMessage = 5,
    PlayArrowHitSound = 6,
    SetRainDuration = 7,
    SetThunderDuration = 8,
    PlayElderGuardianJumpscare = 10,
    _,
};

const std = @import("std");

const main = @import("main");

const Client = main.Client;
const World = main.World;
const S2C = main.network.packet.S2C;
