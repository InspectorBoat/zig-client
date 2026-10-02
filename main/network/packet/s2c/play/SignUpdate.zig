const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

const Vector3 = root.Vector3;

pos: Vector3(i32),
lines: []const []const u8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    const pos = try buffer.readBlockPos();

    var lines: std.ArrayList([]const u8) = .empty;
    try lines.ensureTotalCapacity(allocator, 4);
    for (0..4) |_| {
        try lines.append(allocator, try buffer.readStringAllocating(32767, allocator));
    }

    return .{
        .pos = pos,
        .lines = lines.items,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
