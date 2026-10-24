type: Type,
max_size: i32,
center_pos: Vector2xz(f64),
size_lerp_target: f64,
lerp_size: f64,
lerp_time: i64,
warning_time: i32,
warning_blocks: i32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    _ = allocator;

    const border_type = try buffer.readEnum(Type) orelse return error.InvalidWorldBorderType;

    var packet: @This() = .{
        .type = border_type,
        .max_size = 0,
        .center_pos = .origin,
        .size_lerp_target = 0,
        .lerp_size = 0,
        .lerp_time = 0,
        .warning_time = 0,
        .warning_blocks = 0,
    };

    switch (border_type) {
        .SetSize => {
            packet.size_lerp_target = try buffer.read(f64);
        },
        .LerpSize => {
            packet.lerp_size = try buffer.read(f64);
            packet.size_lerp_target = try buffer.read(f64);
            packet.lerp_time = try readVarLong(buffer);
        },
        .SetCenter => packet.center_pos = .{
            .x = try buffer.read(f64),
            .z = try buffer.read(f64),
        },
        .SetWarningTime => packet.warning_time = try buffer.readVarInt(),
        .SetWarningBlocks => packet.warning_blocks = try buffer.readVarInt(),
        .Initialize => {
            packet.center_pos = .{
                .x = try buffer.read(f64),
                .z = try buffer.read(f64),
            };
            packet.lerp_size = try buffer.read(f64);
            packet.size_lerp_target = try buffer.read(f64);
            packet.lerp_time = try readVarLong(buffer);
            packet.max_size = try buffer.readVarInt();
            packet.warning_blocks = try buffer.readVarInt();
            packet.warning_time = try buffer.readVarInt();
        },
    }

    return packet;
}

fn readVarLong(buffer: *S2C.ReadBuffer) !i64 {
    var result: u64 = 0;
    for (0..10) |i| {
        const byte = try buffer.read(u8);
        result |= @as(u64, byte & 0x7f) << @intCast(i * 7);
        if (byte & 0x80 == 0) break;
    } else return error.VarLongTooBig;
    return @bitCast(result);
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    _ = game;
    _ = self;
}

pub const Type = enum(i32) {
    SetSize,
    LerpSize,
    SetCenter,
    Initialize,
    SetWarningTime,
    SetWarningBlocks,
};

const std = @import("std");

const main = @import("main");

const Client = main.Client;
const Vector2xz = main.Vector2xz;
const S2C = main.network.packet.S2C;
