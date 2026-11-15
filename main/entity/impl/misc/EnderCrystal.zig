base: Entity.Base,

pub const width = 2.0;
pub const height = 2.0;

pub fn init(network_id: i32, pos: Vector3(f64)) @This() {
    var self: @This() = .{ .base = .init(network_id, pos) };
    self.base.setSize(width, height);
    return self;
}

const main = @import("main");

const Entity = main.Entity;
const Vector3 = main.Vector3;
