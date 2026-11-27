pos: Vector3(i32),
lines: [4][]const u8,

comptime handle_on_network_thread: bool = false,
comptime required_client_state: Client.State = .game,

pub fn decode(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) !@This() {
    const pos = try buffer.readBlockPos();

    var lines: [4][]const u8 = undefined;
    for (&lines) |*line| {
        line.* = try parseText(allocator, try buffer.allocString(allocator, 32767));
    }

    return .{
        .pos = pos,
        .lines = lines,
    };
}

pub fn handleOnMainThread(self: *@This(), io: std.Io, allocator: std.mem.Allocator, game: *Client.Game) !void {
    _ = io;

    _ = allocator;
    if (game.world.sign_editor) |*editor| {
        if (std.meta.eql(editor.pos, self.pos)) {
            for (self.lines, 0..) |line, i| {
                const n = @min(line.len, editor.lines[i].len);
                @memcpy(editor.lines[i][0..n], line[0..n]);
                editor.lens[i] = n;
            }
        }
    }
}

/// Vanilla sends Text components; unwrap the common literal form to plain text.
fn parseText(allocator: std.mem.Allocator, raw: []const u8) ![]const u8 {
    const prefix = "{\"text\":\"";
    if (!std.mem.startsWith(u8, raw, prefix) or !std.mem.endsWith(u8, raw, "\"}")) return raw;
    const inner = raw[prefix.len .. raw.len - 2];
    var out: std.ArrayList(u8) = try .initCapacity(allocator, inner.len);
    var i: usize = 0;
    while (i < inner.len) : (i += 1) {
        if (inner[i] == '\\' and i + 1 < inner.len) {
            i += 1;
            const escaped: u8 = switch (inner[i]) {
                'n' => '\n',
                'r' => '\r',
                't' => '\t',
                else => inner[i],
            };
            try out.append(allocator, escaped);
        } else try out.append(allocator, inner[i]);
    }
    return try out.toOwnedSlice(allocator);
}

const std = @import("std");

const main = @import("main");

const Client = main.Client;
const Vector3 = main.Vector3;
const S2C = main.network.packet.S2C;
