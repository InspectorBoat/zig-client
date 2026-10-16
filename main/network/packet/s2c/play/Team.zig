const main = @import("main");
const std = @import("std");

const S2C = main.network.packet.S2C;
const Client = main.Client;

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
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    var packet: @This() = .{
        .name = try buffer.readStringAllocating(allocator, 16),
        .action = try buffer.read(i8),
        .display_name = "",
        .prefix = "",
        .suffix = "",
        .members = &.{},
        .name_tag_visibility = .Always,
        .color = -1,
        .flags = 0,
    };

    if (packet.action == 0 or packet.action == 2) {
        packet.display_name = try buffer.readStringAllocating(allocator, 32);
        packet.prefix = try buffer.readStringAllocating(allocator, 16);
        packet.suffix = try buffer.readStringAllocating(allocator, 16);
        packet.flags = try buffer.read(i8);
        packet.name_tag_visibility = visibilityFromKey(try buffer.readStringNonAllocating(32));
        packet.color = try buffer.read(i8);
    }

    if (packet.action == 0 or packet.action == 3 or packet.action == 4) {
        const member_count = try buffer.readVarInt();
        var members: std.ArrayList([]const u8) = .empty;
        try members.ensureTotalCapacity(allocator, @intCast(member_count));
        for (0..@intCast(member_count)) |_| {
            try members.append(allocator, try buffer.readStringAllocating(allocator, 40));
        }
        packet.members = members.items;
    }

    return packet;
}

// AbstractTeam.Visibility keys; an unknown key falls back to the default, always
fn visibilityFromKey(key: []const u8) NametagVisibility {
    if (std.mem.eql(u8, key, "never")) return .Never;
    if (std.mem.eql(u8, key, "hideForOtherTeams")) return .HideForOtherTeams;
    if (std.mem.eql(u8, key, "hideForOwnTeam")) return .HideForOwnTeam;
    return .Always;
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
