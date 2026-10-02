const root = @import("root");
const Entity = root.Entity;
const Client = root.Client;
const Vector3 = root.Vector3;
const Rotation2 = root.Rotation2;

base: Entity.Base = .{ .width = 1.3, .height = 0.9 },
living: Entity.LivingBase,
interpolate: Entity.InterpolatedBase = .{},

pub fn init(network_id: i32, pos: Vector3(f64)) @This() {
    return .{ .base = .init(network_id, pos) };
}

pub fn initLiving(network_id: i32, pos: Vector3(f64), rotation: Rotation2(f32)) @This() {
    return .{ .base = .initRotation(network_id, pos, rotation), .living = .{} };
}

pub fn tick(self: *@This(), game: *Client.Game) !void {
    _ = game;

    self.base.tick();

    self.interpolate.tick(&self.base);

    if (@abs(self.base.velocity.x) < 0.005) self.base.velocity.x = 0;
    if (@abs(self.base.velocity.y) < 0.005) self.base.velocity.y = 0;
    if (@abs(self.base.velocity.z) < 0.005) self.base.velocity.z = 0;
}
