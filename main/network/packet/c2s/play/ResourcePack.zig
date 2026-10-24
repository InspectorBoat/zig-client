hash: []const u8,
reponse: Response,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeString(self.hash);
    try buffer.writeEnum(Response, self.reponse);
}

pub const Response = enum(i32) {
    SuccessfullyLoaded = 0,
    Declined = 1,
    FailedDownload = 2,
    Accepted = 3,
};

const main = @import("main");

const C2S = main.network.packet.C2S;
