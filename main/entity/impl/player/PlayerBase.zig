const root = @import("root");
const GameMode = root.World.GameMode;
const Client = root.Client;

game_mode: GameMode = .NotSet,
hunger: struct {
    food_level: i32 = 20,
    saturation_level: f32 = 0,
    exhaustion: f32 = 0,
    starvation_timer: i32 = 0,
} = .{},
sleeping: bool = false,

pub fn isSpectator(self: *const @This(), game: *const Client.Game) bool {
    _ = self;
    _ = game;
    return false;
}
