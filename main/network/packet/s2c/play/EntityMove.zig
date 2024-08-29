const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Game = root.Game;
const ScaledVector = root.network.ScaledVector;
const ScaledRotation = root.network.ScaledRotation;

network_id: i32,

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

pub const Position = struct {
    network_id: i32,
    delta_pos: ScaledVector(i8, 32.0),
    on_ground: bool,

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
};

pub const Angles = struct {
    network_id: i32,
    rotation: ScaledRotation(i8, 256.0 / 360.0),
    on_ground: bool,

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
};

pub const PositionAndAngles = struct {
    network_id: i32,
    delta_pos: ScaledVector(i8, 32.0),
    rotation: ScaledRotation(i8, 256.0 / 360.0),
    on_ground: bool,

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
};
