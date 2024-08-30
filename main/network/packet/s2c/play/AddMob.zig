const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Game = root.Game;
const ScaledVector = root.network.ScaledVector;
const ScaledRotation2 = root.network.ScaledRotation2;
const ScaledRotation1 = root.network.ScaledRotation1;
const DataTracker = root.Entity.DataTracker;

network_id: i32,
entity_type: i32,
pos: ScaledVector(i32, 32.0),
velocity: ScaledVector(i32, 8000.0),
rotation: ScaledRotation2(i8, 256.0 / 360.0),
head_yaw: ScaledRotation1(i8, 256.0 / 360.0),
datatracker_entries: []const S2C.Play.EntityData.DataTrackerEntry,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    const network_id = try buffer.readVarInt();
    const entity_type = try buffer.read(i8);
    const pos: ScaledVector(i32, 32.0) = .{
        .x = try buffer.read(i32),
        .y = try buffer.read(i32),
        .z = try buffer.read(i32),
    };
    const rotation: ScaledRotation2(i8, 256.0 / 360.0) = .{
        .pitch = try buffer.read(i8),
        .yaw = try buffer.read(i8),
    };
    const head_yaw: ScaledRotation1(i8, 256.0 / 360.0) = .{
        .head_yaw = try buffer.read(i8),
    };
    const velocity: ScaledVector(i32, 8000) = .{
        .x = try buffer.read(i16),
        .y = try buffer.read(i16),
        .z = try buffer.read(i16),
    };
    const datatracker_entries = undefined;

    return .{
        .network_id = network_id,
        .entity_type = entity_type,
        .pos = pos,
        .rotation = rotation,
        .head_yaw = head_yaw,
        .velocity = velocity,
        .datatracker_entries = datatracker_entries,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
