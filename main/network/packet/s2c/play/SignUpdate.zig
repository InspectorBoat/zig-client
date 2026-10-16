const main = @import("main");
const std = @import("std");

const S2C = main.network.packet.S2C;
const Client = main.Client;

const Vector3 = main.Vector3;

pos: Vector3(i32),
lines: []const []const u8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const pos = try buffer.readBlockPos();

    var lines: std.ArrayList([]const u8) = .empty;
    try lines.ensureTotalCapacity(allocator, 4);
    for (0..4) |_| {
        try lines.append(allocator, try buffer.readStringAllocating(allocator, 32767));
    }

    return .{
        .pos = pos,
        .lines = lines.items,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
