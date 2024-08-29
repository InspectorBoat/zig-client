const root = @import("root");
const c2s = root.network.packet.c2s;

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
    _ = self;
    _ = buffer;
}
