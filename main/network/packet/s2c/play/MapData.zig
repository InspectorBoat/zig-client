map_id: i32,
scale: i8,
decorations: []const MapDecoration,
dirty_min_pos: Vector2xy(i32),
dirty_size: Vector2xy(i32),
colors: []const u8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;
    _ = buffer;
    return undefined;
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}

const std = @import("std");

const main = @import("main");

const MapDecoration = @import("../../../../world/MapDecoration.zig");

const Client = main.Client;
const Vector2xy = main.Vector2xy;
const S2C = main.network.packet.S2C;
