const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Game = root.Game;
const ScaledVector = root.network.ScaledVector;
const ScaledRotation = root.network.ScaledRotation;
const DataTracker = root.Entity.DataTracker;

network_id: i32,
type: i32,
pos: ScaledVector(i32, 32.0),
velocity: ScaledVector(i32, 8000.0),
rotation: ScaledRotation(u8, 256.0 / 360.0),
head_yaw: u8,
datatracker_entries: []const S2C.Play.EntityData.DataTrackerEntry,

data: i32,

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
