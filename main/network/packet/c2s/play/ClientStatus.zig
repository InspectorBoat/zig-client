status: Status,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.writeEnum(Status, self.status);
}

pub const Status = enum(i32) {
    perform_respawn = 0,
    request_stats = 1,
    open_inventory_achievement = 2,
};

const main = @import("main");

const C2S = main.network.packet.C2S;
