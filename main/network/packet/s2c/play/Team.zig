const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;
const NametagVisibility = @import("../../../../team/Team.zig").NametagVisibility;

name: []const u8,
display_name: []const u8,
prefix: []const u8,
suffix: []const u8,
members: []const []const u8,
name_tag_visibility: NametagVisibility,
color: i8,
action: i8,
flags: i8,

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
