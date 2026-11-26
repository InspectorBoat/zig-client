event: Event,
data: f32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;

    return .{
        .event = @fromBackingInt(try buffer.read(u8)),
        .data = try buffer.read(f32),
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;
    _ = allocator;

    switch (self.event) {
        .invalid_bed => {},
        .begin_raining => {},
        .stop_raining => {},
        .set_game_mode => {
            // TODO: THIS IS FUCKED
            // use MathHelper.floor when it gets added
            game.world.game_mode = std.enums.fromInt(World.GameMode, @as(i32, @trunc(self.data))) orelse .survival;
        },
        .open_credits => {},
        .demo_message => {},
        .play_arrow_hit_sound => {},
        .set_rain_duration => {},
        .set_thunder_duration => {},
        .play_elder_guardian_jumpscare => {},
        _ => {},
    }
}

pub const Event = enum(i32) {
    invalid_bed = 0,
    begin_raining = 1,
    stop_raining = 2,
    set_game_mode = 3,
    open_credits = 4,
    demo_message = 5,
    play_arrow_hit_sound = 6,
    set_rain_duration = 7,
    set_thunder_duration = 8,
    play_elder_guardian_jumpscare = 10,
    _,
};

const std = @import("std");

const main = @import("main");

const Client = main.Client;
const World = main.World;
const S2C = main.network.packet.S2C;
