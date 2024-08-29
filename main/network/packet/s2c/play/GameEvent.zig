const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Game = root.Game;

event: Event,
data: f32,

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
};
