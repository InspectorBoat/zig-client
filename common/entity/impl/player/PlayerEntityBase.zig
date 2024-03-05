const GameMode = @import("../../../world/gamemode.zig").GameMode;
const Game = @import("../../../game.zig").Game;

game_mode: GameMode = .NotSet,
hunger: struct {
    food_level: i32 = 20,
    saturation_level: f32 = 0,
    exhaustion: f32 = 0,
    starvation_timer: i32 = 0,
} = .{},

pub fn isSpectator(self: *const @This(), game: *const Game.IngameState) bool {
    _ = self;
    _ = game;
    return false;
}
