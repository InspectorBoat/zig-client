const std = @import("std");
const root = @import("root");
const C2S = root.network.packet.C2S;

menu_network_id: i8,
button_id: i8,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    try buffer.write(i8, self.menu_network_id);
    try buffer.write(i8, self.button_id);
}
