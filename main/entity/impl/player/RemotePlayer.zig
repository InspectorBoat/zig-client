base: Entity.Base,
living: Entity.LivingBase = .{},
player: Entity.PlayerBase = .{},
interpolate: Entity.InterpolatedBase = .{},

pub fn tick(self: *@This(), game: *Client.Game) !void {
    _ = game;

    self.base.tick();

    self.interpolate.tick(&self.base);

    if (@abs(self.base.velocity.x) < 0.005) self.base.velocity.x = 0;
    if (@abs(self.base.velocity.y) < 0.005) self.base.velocity.y = 0;
    if (@abs(self.base.velocity.z) < 0.005) self.base.velocity.z = 0;
}

const main = @import("main");

const Client = main.Client;
const Entity = main.Entity;
