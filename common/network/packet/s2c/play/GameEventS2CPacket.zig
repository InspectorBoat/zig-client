const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");

event: Event,
data: f32,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
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
