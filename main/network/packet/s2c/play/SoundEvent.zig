const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

name: []const u8,
x: i32,
y: i32,
z: i32,
volume: f32,
pitch: i32,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    _ = buffer;
    return undefined;
}

pub fn handleOnMainThread(self: *@This(), client: *Client, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = client;
    _ = self;
}
