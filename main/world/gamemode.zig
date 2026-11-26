pub const GameMode = enum(i32) {
    not_set = -1,
    survival = 0,
    creative = 1,
    adventure = 2,
    spectator = 3,

    pub fn restrictsWorldModification(self: @This()) bool {
        return self == .adventure or self == .spectator;
    }
};
