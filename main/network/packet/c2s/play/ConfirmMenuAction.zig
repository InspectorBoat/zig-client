const std = @import("std");
const root = @import("root");
const c2s = root.network.packet.c2s;

menu_network_id: i8,
action_id: i16,
accepted: bool,

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
    try buffer.write(i8, self.menu_network_id);
    try buffer.write(i16, self.action_id);
    try buffer.write(bool, self.accepted);
}
