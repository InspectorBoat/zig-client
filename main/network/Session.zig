username: []u8,
uuid: []u8,
access_token: []u8,

const PrismLauncher = struct {
    accounts: []Account,
    const Account = struct {
        profile: struct {
            id: []u8,
            name: []u8,
        },
        ygg: struct {
            token: []u8,
        },
    };
};

pub fn parseFromPrismLauncher(io: std.Io, gpa: std.mem.Allocator, file: std.Io.File) !@This() {
    defer file.close(io);

    var buffer: [1024]u8 = undefined;
    var file_reader = file.reader(io, &buffer);
    var reader: std.json.Reader = .init(gpa, &file_reader.interface);

    const json = std.json.parseFromTokenSource(PrismLauncher, gpa, &reader, .{ .ignore_unknown_fields = true }) catch |e| {
        std.log.err("failed to parse accounts.json", .{});
        return e;
    };
    defer json.deinit();

    const account = if (json.value.accounts.len > 0) json.value.accounts[0] else return error.NoAccounts;
    return .{
        .access_token = try gpa.dupe(u8, account.ygg.token),
        .uuid = try gpa.dupe(u8, account.profile.id),
        .username = try gpa.dupe(u8, account.profile.name),
    };
}

const std = @import("std");
