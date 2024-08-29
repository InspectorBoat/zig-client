const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Game = root.Game;
const ScaledVector = root.network.ScaledVector;
const ScaledRotation = root.network.ScaledRotation;
const DataTracker = root.entity.DataTracker;

network_id: i32,
type: i32,
pos: ScaledVector(i32, 32.0),
velocity: ScaledVector(i32, 8000.0),
rotation: ScaledRotation(u8, 256.0 / 360.0),
head_yaw: u8,
datatracker_entries: []const s2c.play.EntityData.DataTrackerEntry,

data: i32,

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
