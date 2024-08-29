const std = @import("std");
const root = @import("root");
const c2s = root.network.packet.c2s;

message: []const u8,

pub fn write(self: @This(), buffer: *c2s.WriteBuffer) !void {
    const message_view = try std.unicode.Utf8View.init(self.message);
    var iterator = message_view.iterator();
    try buffer.writeString(iterator.peek(100));
}
