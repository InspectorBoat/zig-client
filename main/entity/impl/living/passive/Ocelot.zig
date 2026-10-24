const main = @import("main");

const Client = main.Client;
const Entity = main.Entity;
const Rotation2 = main.Rotation2;
const Vector3 = main.Vector3;

base: Entity.Base,
living: Entity.LivingBase,
interpolate: Entity.InterpolatedBase = .{},

pub fn init(network_id: i32, pos: Vector3(f64)) @This() {
    return .{ .base = .init(network_id, pos) };
}

pub fn initLiving(network_id: i32, pos: Vector3(f64), rotation: Rotation2(f32)) @This() {
    var ocelot: @This() = .{ .base = .initRotation(network_id, pos, rotation), .living = .{} };
    ocelot.base.setSize(0.6, 0.7);
    return ocelot;
}

pub fn tick(self: *@This(), game: *Client.Game) !void {
    _ = game;

    self.base.tick();

    self.interpolate.tick(&self.base);

    if (@abs(self.base.velocity.x) < 0.005) self.base.velocity.x = 0;
    if (@abs(self.base.velocity.y) < 0.005) self.base.velocity.y = 0;
    if (@abs(self.base.velocity.z) < 0.005) self.base.velocity.z = 0;
}
