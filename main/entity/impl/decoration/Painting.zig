base: Entity.Base,
painting_type: PaintingType,

pub fn init(network_id: i32, pos: Vector3(f64)) @This() {
    return .{ .base = .init(network_id, pos) };
}

pub const PaintingType = enum {
    kebab,
    aztec,
    alban,
    aztec2,
    bomb,
    plant,
    wasteland,
    pool,
    courbet,
    sea,
    sunset,
    creebet,
    wanderer,
    graham,
    match,
    bust,
    stage,
    void,
    skull_and_roses,
    wtiher,
    fighters,
    pointer,
    pigscene,
    burning_skull,
    skeleton,
    donkey_kong,
};

const main = @import("main");

const Entity = main.Entity;
const Vector3 = main.Vector3;
