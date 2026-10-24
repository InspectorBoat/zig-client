base: Entity.Base,

pub fn init(network_id: i32, pos: Vector3(f64)) @This() {
    var cart: @This() = .{ .base = .init(network_id, pos) };
    cart.base.setSize(0.98, 0.7);
    return cart;
}

const main = @import("main");

const Entity = main.Entity;
const Vector3 = main.Vector3;
