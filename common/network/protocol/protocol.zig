const std = @import("std");

pub const Protocol = enum(i32) {
    Handshake = -1,
    Play = 0,
    Status = 1,
    Login = 2,
};
