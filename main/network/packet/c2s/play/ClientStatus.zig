status: Status,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeEnum(Status, self.status);
}

pub const Status = enum(i32) {
    PerformRespawn = 0,
    RequestStats = 1,
    OpenInventoryAchievement = 2,
};

const main = @import("main");

const C2S = main.network.packet.C2S;
