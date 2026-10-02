const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

const ScaledVector = root.network.ScaledVector;
const ScaledRotation2 = root.network.ScaledRotation2;

network_id: i32,
pos: ScaledVector(i32, 32.0),
rotation: ScaledRotation2(i32, 256.0 / 360.0),

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;

    const network_id = try buffer.readVarInt();
    const pos: ScaledVector(i32, 32.0) = .{ .raw = .{
        .x = try buffer.read(i32),
        .y = try buffer.read(i32),
        .z = try buffer.read(i32),
    } };
    const rotation: ScaledRotation2(i32, 256.0 / 360.0) = .{
        .yaw = try buffer.read(i8),
        .pitch = try buffer.read(i8),
    };

    _ = try buffer.read(bool);

    return .{
        .network_id = network_id,
        .pos = pos,
        .rotation = rotation,
    };
}
pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
    const entity = game.world.getEntityByNetworkId(self.network_id) orelse return;
    switch (entity.*) {
        .removed => {},
        inline else => |*specific_entity| {
            specific_entity.base.server_tracked_pos = self.pos;
            try entity.interpolateOrSnap(specific_entity.base.server_tracked_pos.normalize(), self.rotation.normalize(), 3, &game.world, allocator);
        },
    }
}
