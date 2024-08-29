const std = @import("std");
const root = @import("root");
const c2s = root.network.packet.c2s;

hash: []const u8,
reponse: Response,

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
    try buffer.writeString(self.hash);
    try buffer.writeEnum(Response, self.reponse);
}

pub const Response = enum(i32) {
    SuccessfullyLoaded = 0,
    Declined = 1,
    FailedDownload = 2,
    Accepted = 3,
};
