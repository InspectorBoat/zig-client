const main = @import("main");
const std = @import("std");

const C2S = main.network.packet.C2S;

message: []const u8,

pub fn write(self: @This(), buffer: *C2S.WriteBuffer) !void {
    const message_view: std.unicode.Utf8View = try .init(self.message);
    var iterator = message_view.iterator();
    try buffer.writeString(iterator.peek(100));
}
