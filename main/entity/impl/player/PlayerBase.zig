const root = @import("root");
const GameMode = root.World.GameMode;
const Game = root.Game;

game_mode: GameMode = .NotSet,
hunger: struct {
    food_level: i32 = 20,
    saturation_level: f32 = 0,
    exhaustion: f32 = 0,
    starvation_timer: i32 = 0,
} = .{},
sleeping: bool = false,

pub fn isSpectator(self: *const @This(), game: *const Game.IngameGame) bool {
    _ = self;
    _ = game;
    return false;
}
