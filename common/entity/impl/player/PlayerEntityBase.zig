const GameMode = @import("../../../world/gamemode.zig").GameMode;
const Game = @import("../../../game.zig").Game;

game_mode: GameMode = .NotSet,

pub fn isSpectator(self: *const @This(), game: *const Game.IngameState) bool {
    _ = self;
    _ = game;
    return false;
}
