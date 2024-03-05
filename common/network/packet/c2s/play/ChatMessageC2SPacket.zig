const std = @import("std");
const WritePacketBuffer = @import("../../../../network/packet/WritePacketBuffer.zig");

message: []const u8,

pub fn write(self: @This(), buffer: *WritePacketBuffer) !void {
    const message_view = try std.unicode.Utf8View.init(self.message);
    var iterator = message_view.iterator();
    try buffer.writeString(iterator.peek(100));
}
