const std = @import("std");

bytes: [16]u8,
///                                0         10        20        30
///                                012345678901234567890123456789012345
/// expects a string in the format xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx, where x is a ascii hex digit
pub fn fromAscii(string: []const u8) !@This() {
    if (string.len != 36) return error.BadStringLength;
    for (string, 0..36) |char, i| {
        if (!std.ascii.isASCII(char)) return error.NotAscii;
        if (i == 8 or i == 13 or i == 18 or i == 23) {
            if (char != '-') return error.ExpectedDash;
            continue;
        }

        if (!std.ascii.isHex(char)) {
            return error.ExpectedHex;
        }
    }
    const without_dashes = string[0..8] ++ string[9..13] ++ string[14..18] ++ string[19..23] ++ string[24..36];
    const parsed_int = try std.fmt.parseInt(u128, without_dashes, 16);
    return .{ .bytes = std.mem.toBytes(parsed_int) };
}
