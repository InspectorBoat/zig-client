const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;
const Vector3 = root.Vector3;

event: i32,
block_pos: Vector3(i32),
data: i32,
global: bool,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = buffer; // autofix
    _ = allocator;
    // return .{
    //     .event = try buffer.read(i32),
    //     .pos = try buffer.readBlockPos(),
    //     .data = try buffer.read(i32),
    //     .global = try buffer.read(bool),
    // };
    return undefined;
}

pub fn handleOnMainThread(self: *@This(), client: *Client, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = client;
    _ = self;
}
