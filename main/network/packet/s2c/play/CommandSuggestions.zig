const std = @import("std");

const main = @import("main");

const Client = main.Client;
const S2C = main.network.packet.S2C;

suggestions: []const []const u8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const suggestion_count = try buffer.readVarInt();

    var suggestions: std.ArrayList([]const u8) = .empty;
    try suggestions.ensureTotalCapacity(allocator, @intCast(suggestion_count));
    for (0..@intCast(suggestion_count)) |_| {
        try suggestions.append(allocator, try buffer.readStringAllocating(allocator, 32767));
    }

    return .{
        .suggestions = suggestions.items,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
