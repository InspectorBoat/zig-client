pub const GameMode = enum(i32) {
    NotSet = -1,
    Survival = 0,
    Creative = 1,
    Adventure = 2,
    Spectator = 3,

    pub fn restrictsWorldModification(self: @This()) bool {
        return self == .Adventure or self == .Spectator;
    }
};
