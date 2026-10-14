const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

// this packet is useless

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;

    const event = try buffer.readVarInt();
    switch (event) {
        1 => {
            _ = try buffer.readVarInt();
            _ = try buffer.read(i32);
        },
        2 => {
            _ = try buffer.readVarInt();
            _ = try buffer.read(i32);
            _ = try buffer.readStringNonAllocating(32767);
        },
        else => {},
    }

    return .{};
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
