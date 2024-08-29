const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Game = root.Game;
const Vector3 = root.Vector3;
const Rotation2 = root.Rotation2;

pos: Vector3(f64),
rotation: Rotation2(f32),
relative_arguments: RelativeArguments,

comptime handle_on_network_thread: bool = false,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;
    return .{
        .pos = Vector3(f64){
            .x = try buffer.read(f64),
            .y = try buffer.read(f64),
            .z = try buffer.read(f64),
        },
        .rotation = Rotation2(f32){
            .yaw = try buffer.read(f32),
            .pitch = try buffer.read(f32),
        },
        .relative_arguments = try buffer.readPacked(RelativeArguments),
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    @import("log").recieve_teleport_packet(.{ self.pos, self.rotation, self.relative_arguments });

    switch (game.*) {
        .Ingame => |*ingame| {
            const player = &ingame.world.player;

            if (self.relative_arguments.x == .Absolute) player.base.velocity.x = 0;
            if (self.relative_arguments.y == .Absolute) player.base.velocity.y = 0;
            if (self.relative_arguments.z == .Absolute) player.base.velocity.z = 0;

            player.base.teleport(
                Vector3(f64){
                    .x = switch (self.relative_arguments.x) {
                        .Absolute => self.pos.x,
                        .Relative => self.pos.x + player.base.pos.x,
                    },
                    .y = switch (self.relative_arguments.y) {
                        .Absolute => self.pos.y,
                        .Relative => self.pos.y + player.base.pos.y,
                    },
                    .z = switch (self.relative_arguments.z) {
                        .Absolute => self.pos.z,
                        .Relative => self.pos.z + player.base.pos.z,
                    },
                },
                Rotation2(f32){
                    .yaw = switch (self.relative_arguments.yaw) {
                        .Absolute => self.rotation.yaw,
                        .Relative => self.rotation.yaw + player.base.rotation.yaw,
                    },
                    .pitch = switch (self.relative_arguments.pitch) {
                        .Absolute => self.rotation.pitch,
                        .Relative => self.rotation.pitch + player.base.rotation.pitch,
                    },
                },
            );
            try ingame.connection_handle.sendPlayPacket(
                .{ .player_move_position_and_angles = .{
                    .on_ground = false,
                    .pos = player.base.pos,
                    .rotation = player.base.rotation,
                } },
            );
            // Temporary hack for respawning
            try ingame.connection_handle.sendPlayPacket(
                .{ .client_status = .{
                    .status = .PerformRespawn,
                } },
            );
        },
        else => unreachable,
    }
}

pub const RelativeArguments = packed struct {
    x: RelativeMode,
    y: RelativeMode,
    z: RelativeMode,
    yaw: RelativeMode,
    pitch: RelativeMode,
    _: u3,
    pub const RelativeMode = enum(u1) {
        Absolute,
        Relative,
    };

    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("{{ x: {s} y: {s} z: {s} yaw: {s} pitch: {s} }}", .{
            if (self.x == .Absolute) "abs" else "rel",
            if (self.y == .Absolute) "abs" else "rel",
            if (self.z == .Absolute) "abs" else "rel",
            if (self.yaw == .Absolute) "abs" else "rel",
            if (self.pitch == .Absolute) "abs" else "rel",
        });
    }
};
