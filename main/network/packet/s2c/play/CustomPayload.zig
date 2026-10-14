const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

channel: []const u8,
data: S2C.ReadBuffer,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const channel = try buffer.readStringAllocating(allocator, 20);
    const remaining_bytes = buffer.remainingBytes();
    if (remaining_bytes > 1048576) return error.CustomPayloadTooLarge;
    const data = try buffer.readRemainingBytesAllocating(allocator);
    return .{
        .channel = channel,
        .data = .fromOwnedSlice(data),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = self;
    _ = game;
    _ = allocator;
}
