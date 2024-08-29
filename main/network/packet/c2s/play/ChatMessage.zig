const std = @import("std");
const root = @import("root");
const C2S = root.network.packet.C2S;

message: []const u8,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    const message_view = try std.unicode.Utf8View.init(self.message);
    var iterator = message_view.iterator();
    try buffer.writeString(iterator.peek(100));
}
