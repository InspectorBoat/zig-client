base: Entity.Base,

pub fn init(network_id: i32, pos: Vector3(f64)) @This() {
    return .{ .base = .init(network_id, pos) };
}

pub fn tick(self: *@This(), game: *Client.Game) !void {
    _ = game;
    _ = self;
}

const main = @import("main");

const Client = main.Client;
const Entity = main.Entity;
const Vector3 = main.Vector3;
