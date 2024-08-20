const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const ScaledVector = @import("../../../../network/type/scaled_vector.zig").ScaledVector;
const ScaledRotation = @import("../../../../network/type/scaled_rotation.zig").ScaledRotation;
const DataTracker = @import("../../../../entity/datatracker/DataTracker.zig");
const EntityDataS2CPacket = @import("EntityDataS2CPacket.zig");

network_id: i32,
type: i32,
pos: ScaledVector(i32, 32.0),
velocity: ScaledVector(i32, 8000.0),
rotation: ScaledRotation(u8, 256.0 / 360.0),
head_yaw: u8,
datatracker_entries: []const EntityDataS2CPacket.DataTrackerEntry,

data: i32,

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
