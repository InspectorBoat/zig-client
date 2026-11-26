pub const Protocol = enum(i32) {
    handshake = -1,
    play = 0,
    status = 1,
    login = 2,
};
