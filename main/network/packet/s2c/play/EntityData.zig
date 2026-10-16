const main = @import("main");
const std = @import("std");

const S2C = main.network.packet.S2C;
const Client = main.Client;

const DataTracker = main.Entity.DataTracker;

network_id: i32,
entries: []const DataTrackerEntry,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const network_id = try buffer.readVarInt();
    return .{
        .network_id = network_id,
        .entries = try readDataEntries(allocator, buffer),
    };
}

pub fn readDataEntries(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) ![]const DataTrackerEntry {
    var entries: std.ArrayList(DataTrackerEntry) = .empty;
    var entry_info = try buffer.readPacked(DataTrackerEntryInfo);
    while (@as(u8, @bitCast(entry_info)) != DataTrackerEntryInfo.Stop) {
        try entries.append(allocator, .{
            .id = entry_info.id,
            .value = switch (entry_info.type) {
                .i8 => .{ .i8 = try buffer.read(i8) },
                .i16 => .{ .i16 = try buffer.read(i16) },
                .i32 => .{ .i32 = try buffer.read(i32) },
                .f32 => .{ .f32 = try buffer.read(f32) },
                .String => .{ .String = try buffer.readStringAllocating(allocator, 32767) },
                .ItemStack => .{ .ItemStack = try buffer.readItemStackAllocating(allocator) },
                .BlockPos => .{ .BlockPos = .{ .x = try buffer.read(i32), .y = try buffer.read(i32), .z = try buffer.read(i32) } },
                .Rotation => .{ .Rotation = .{ .yaw = try buffer.read(f32), .pitch = try buffer.read(f32), .roll = try buffer.read(f32) } },
            },
        });
        entry_info = try buffer.readPacked(DataTrackerEntryInfo);
    }
    return entries.items;
}

pub const DataTrackerEntryInfo = packed struct {
    id: u5,
    type: DataTracker.DataTypes,

    pub const Stop: u8 = 0b01111111;
};

pub const DataTrackerEntry = struct {
    id: u5,
    value: DataTracker.DataValue,
};

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}
