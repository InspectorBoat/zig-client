base: Entity.Base,
living: Entity.LivingBase,
interpolate: Entity.InterpolatedBase,

pub const width = 1.4;
pub const height = 1.6;

pub const initLiving = Entity.Generic(@This()).initLiving;
pub const tick = Entity.Generic(@This()).interpolatedTick;

const main = @import("main");

const Entity = main.Entity;
