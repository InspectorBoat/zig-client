const std = @import("std");
const root = @import("root");
const s2c = root.network.packet.s2c;
const Game = root.Game;
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

pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    _ = buffer;
    return undefined;
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
