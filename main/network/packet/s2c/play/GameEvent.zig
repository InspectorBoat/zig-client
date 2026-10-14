const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

event: i32,
data: f32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;

    return .{
        .event = try buffer.read(u8),
        .data = try buffer.read(f32),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}

/// Ids handleGameEvent acts on; unknown ids are ignored, so the packet stores
/// the raw value rather than an enum.
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
