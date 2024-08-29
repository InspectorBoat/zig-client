const std = @import("std");

pub fn EnumBoolArray(comptime Enum: type) type {
    return struct {
        set: std.EnumSet(Enum),

        pub fn get(self: @This(), key: Enum) bool {
            return self.set.contains(key);
        }

        pub fn init(entries: std.enums.EnumFieldStruct(Enum, bool, null)) @This() {
            @setEvalBranchQuota(100000);
            var set = std.EnumSet(Enum).initEmpty();
            inline for (@typeInfo(@TypeOf(entries)).@"struct".fields) |struct_field| {
                if (@field(entries, struct_field.name)) {
                    inline for (@typeInfo(Enum).@"enum".fields) |enum_field| {
                        if (comptime std.mem.eql(u8, enum_field.name, struct_field.name)) {
                            set.insert(@enumFromInt(enum_field.value));
                        }
                    }
                }
            }
            return .{ .set = set };
        }
    };
}
