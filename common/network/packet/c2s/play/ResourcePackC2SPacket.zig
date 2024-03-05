const std = @import("std");
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");

hash: []const u8,
reponse: Response,

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    try buffer.writeString(self.hash);
    try buffer.writeEnum(Response, self.reponse);
}

pub const Response = enum(i32) {
    SuccessfullyLoaded = 0,
    Declined = 1,
    FailedDownload = 2,
    Accepted = 3,
};
