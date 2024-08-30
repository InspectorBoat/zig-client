const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Game = root.Game;
const ScaledVector = root.network.ScaledVector;
const ScaledRotation2 = root.network.ScaledRotation2;

network_id: i32,

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

pub const Position = struct {
    network_id: i32,
    delta_pos: ScaledVector(i8, 32.0),
    on_ground: bool,

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
};

pub const Angles = struct {
    network_id: i32,
    rotation: ScaledRotation2(i8, 256.0 / 360.0),
    on_ground: bool,

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
};

pub const PositionAndAngles = struct {
    network_id: i32,
    delta_pos: ScaledVector(i8, 32.0),
    rotation: ScaledRotation2(i8, 256.0 / 360.0),
    on_ground: bool,

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
};
