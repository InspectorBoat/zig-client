const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

const GameMode = root.World.GameMode;
const GameProfile = root.network.GameProfile;

action: Action,
entries: []const Entry,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    const action = try buffer.readEnum(Action) orelse return error.InvalidPlayerInfo;
    const entry_count = try buffer.readVarInt();
    var entries: std.ArrayList(Entry) = .empty;
    for (0..@intCast(entry_count)) |_| {
        const entry: Entry = switch (action) {
            .AddPlayer => .{
                .game_profile = .{
                    .uuid = try buffer.readUuid(),
                    .name = try buffer.readStringAllocating(16, allocator),
                    .properties = get_properties: {
                        var properties: std.StringHashMapUnmanaged(GameProfile.Property) = .empty;

                        const property_count = try buffer.readVarInt();
                        for (0..@intCast(property_count)) |_| {
                            const name = try buffer.readStringAllocating(32767, allocator);

                            try properties.put(allocator, name, .{
                                .name = name,
                                .value = try buffer.readStringAllocating(32767, allocator),
                                .signature = if (try buffer.read(bool)) try buffer.readStringAllocating(32767, allocator) else null,
                            });
                        }

                        break :get_properties properties;
                    },
                },
                .game_mode = try buffer.readEnum(GameMode) orelse .Survival,
                .ping = try buffer.readVarInt(),
                .display_name = if (try buffer.read(bool)) try buffer.readStringAllocating(32767, allocator) else null,
            },
            .UpdateGameMode => .{
                .game_profile = .{
                    .uuid = try buffer.readUuid(),
                },
                .game_mode = try buffer.readEnum(GameMode) orelse .Survival,
            },
            .UpdatePing => .{
                .game_profile = .{
                    .uuid = try buffer.readUuid(),
                },
                .game_mode = try buffer.readEnum(GameMode) orelse .Survival,
            },
            .UpdateDisplayName => .{
                .game_profile = .{
                    .uuid = try buffer.readUuid(),
                },
                .display_name = if (try buffer.read(bool)) try buffer.readStringAllocating(32767, allocator) else null,
            },
            .RemovePlayer => .{
                .game_profile = .{
                    .uuid = try buffer.readUuid(),
                },
            },
        };
        try entries.append(allocator, entry);
    }
    return .{
        .action = action,
        .entries = entries.items,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, io: std.Io, allocator: std.mem.Allocator) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}

pub const Action = enum(i32) {
    AddPlayer,
    UpdateGameMode,
    UpdatePing,
    UpdateDisplayName,
    RemovePlayer,
};

pub const Entry = struct {
    ping: ?i32 = null,
    game_mode: ?GameMode = null,
    game_profile: ?GameProfile = null,
    display_name: ?[]const u8 = null,
};
