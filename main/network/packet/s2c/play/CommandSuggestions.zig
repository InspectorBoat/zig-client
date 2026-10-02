const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

suggestions: []const []const u8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    const suggestion_count = try buffer.readVarInt();

    var suggestions: std.ArrayList([]const u8) = .empty;
    try suggestions.ensureTotalCapacity(allocator, @intCast(suggestion_count));
    for (0..@intCast(suggestion_count)) |_| {
        try suggestions.append(allocator, try buffer.readStringAllocating(32767, allocator));
    }

    return .{
        .suggestions = suggestions.items,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
