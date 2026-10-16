const std = @import("std");

const main = @import("main");

const Client = main.Client;
const S2C = main.network.packet.S2C;

type: Type,
text: []const u8,
fade_in: i32,
duration: i32,
fade_out: i32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    var packet: @This() = .{
        .type = .Clear,
        .text = "",
        .fade_in = 0,
        .duration = 0,
        .fade_out = 0,
    };

    packet.type = try buffer.readEnum(Type) orelse return error.InvalidTitleType;
    switch (packet.type) {
        .Title, .Subtitle => packet.text = try buffer.readStringAllocating(allocator, 32767),
        .Times => {
            packet.fade_in = try buffer.read(i32);
            packet.duration = try buffer.read(i32);
            packet.fade_out = try buffer.read(i32);
        },
        .Clear, .Reset => {},
    }

    return packet;
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}

pub const Type = enum(i32) {
    Title,
    Subtitle,
    Times,
    Clear,
    Reset,
};
