base: Entity.Base,

pub const gravity: f32 = 0.03;

pub const init = Entity.Generic(@This()).initThrown;
pub const tick = Entity.Generic(@This()).thrownTick;

const main = @import("main");

const Entity = main.Entity;
