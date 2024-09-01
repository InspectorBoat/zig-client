const root = @import("root");
const Entity = root.Entity;
const Vector3 = root.Vector3;

base: Entity.Base,
painting_type: PaintingType,

pub fn init(network_id: i32, pos: Vector3(f64)) @This() {
    return .{ .base = Entity.Base.init(network_id, pos) };
}

pub const PaintingType = enum {
    Kebab,
    Aztec,
    Alban,
    Aztec2,
    Bomb,
    Plant,
    Wasteland,
    Pool,
    Courbet,
    Sea,
    Sunset,
    Creebet,
    Wanderer,
    Graham,
    Match,
    Bust,
    Stage,
    Void,
    SkullAndRoses,
    Wtiher,
    Fighters,
    Pointer,
    Pigscene,
    BurningSkull,
    Skeleton,
    DonkeyKong,
};
