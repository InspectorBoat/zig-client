const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

owner: []const u8,
objective: []const u8,
score: ?i32,
action: Action,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const owner = try buffer.readStringAllocating(allocator, 40);
    const action = try buffer.readEnum(Action) orelse return error.InvalidScoreboardScoreAction;
    const objective = try buffer.readStringAllocating(allocator, 16);
    const score = if (action == .Change)
        try buffer.readVarInt()
    else
        null;

    return .{
        .owner = owner,
        .objective = objective,
        .score = score,
        .action = action,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}

pub const Action = enum(i32) {
    Change,
    Remove,
};
