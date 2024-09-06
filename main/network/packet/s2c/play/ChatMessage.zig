const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

message: []const u8,
type: i8,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    return .{
        .message = try buffer.readStringAllocating(32767, allocator),
        .type = try buffer.read(i8),
    };
}

pub fn handleOnMainThread(self: *@This(), client: *Client, allocator: std.mem.Allocator) !void {
    std.debug.print("message: {s} type: {}\n", .{ self.message, self.type });
    _ = allocator;
    _ = client;
}
