const std = @import("std");
const Game = @import("../../../../game.zig").Game;
const ReadPacketBuffer = @import("../../../../network/packet/ReadPacketBuffer.zig");
const DataTracker = @import("../../../../entity/datatracker/DataTracker.zig");

network_id: i32,
entries: []const DataTrackerEntry,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
    const network_id = try buffer.readVarInt();
    return .{
        .network_id = network_id,
        .entries = try readDataEntries(buffer, allocator),
    };
}

pub fn readDataEntries(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) ![]const DataTrackerEntry {
    var entries = std.ArrayList(DataTrackerEntry).init(allocator);
    var entry_info = try buffer.readPacked(DataTrackerEntryInfo);
    while (@as(u8, @bitCast(entry_info)) != DataTrackerEntryInfo.Stop) {
        try entries.append(.{
            .id = entry_info.id,
            .value = switch (entry_info.type) {
                .i8 => .{ .i8 = try buffer.read(i8) },
                .i16 => .{ .i16 = try buffer.read(i16) },
                .i32 => .{ .i32 = try buffer.read(i32) },
                .f32 => .{ .f32 = try buffer.read(f32) },
                .String => .{ .String = try buffer.readStringAllocating(32767, allocator) },
                .ItemStack => .{ .ItemStack = try buffer.readItemStackAllocating(allocator) },
                .BlockPos => .{ .BlockPos = .{ .x = try buffer.read(i32), .y = try buffer.read(i32), .z = try buffer.read(i32) } },
                .Rotation => .{ .Rotation = .{ .yaw = try buffer.read(f32), .pitch = try buffer.read(f32), .roll = try buffer.read(f32) } },
            },
        });
        entry_info = try buffer.readPacked(DataTrackerEntryInfo);
    }
    return entries.toOwnedSlice();
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

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
