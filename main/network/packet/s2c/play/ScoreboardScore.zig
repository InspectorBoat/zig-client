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

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    const owner = try buffer.readStringAllocating(40, allocator);
    const action = try buffer.readEnum(Action) orelse return error.InvalidScoreboardScoreAction;
    const objective = try buffer.readStringAllocating(16, allocator);
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

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}

pub const Action = enum(i32) {
    Change,
    Remove,
};
