suggestions: []const []const u8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const suggestion_count = try buffer.readVarInt();

    const suggestions: [][]const u8 = try allocator.alloc([]const u8, @intCast(suggestion_count));
    for (suggestions) |*suggestion| {
        suggestion.* = try buffer.readStringAllocating(allocator, 32767);
    }

    return .{
        .suggestions = suggestions,
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
const S2C = main.network.packet.S2C;
