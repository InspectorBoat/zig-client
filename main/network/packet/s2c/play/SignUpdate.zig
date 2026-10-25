pos: Vector3(i32),
lines: [4][]const u8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const pos = try buffer.readBlockPos();

    var lines: [4][]const u8 = undefined;
    for (&lines) |*line| {
        line.* = try buffer.readStringAllocating(allocator, 32767);
    }

    return .{
        .pos = pos,
        .lines = lines,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}

const std = @import("std");

const main = @import("main");

const Client = main.Client;
const Vector3 = main.Vector3;
const S2C = main.network.packet.S2C;
