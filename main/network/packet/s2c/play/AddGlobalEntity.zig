const std = @import("std");
const root = @import("root");
const S2C = root.network.packet.S2C;
const Client = root.Client;

const ScaledVector = root.network.ScaledVector;

network_id: i32,
pos: ScaledVector(i32, 32.0),
type: i32,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !@This() {
    _ = allocator;

    const network_id = try buffer.readVarInt();
    const entity_type = try buffer.read(i8);
    const pos: ScaledVector(i32, 32.0) = .{ .raw = .{
        .x = try buffer.read(i32),
        .y = try buffer.read(i32),
        .z = try buffer.read(i32),
    } };

    return .{
        .network_id = network_id,
        .pos = pos,
        .type = entity_type,
    };
}

pub fn handleOnMainThread(self: *@This(), game: *Client.Game, allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = game;
    _ = self;
}
