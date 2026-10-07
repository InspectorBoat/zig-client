const std = @import("std");

pub fn EnumBoolArray(comptime Enum: type) type {
    return struct {
        set: std.EnumSet(Enum),

        pub fn get(self: @This(), key: Enum) bool {
            return self.set.contains(key);
        }

        pub fn init(entries: std.enums.EnumFieldStruct(Enum, bool, null)) @This() {
            @setEvalBranchQuota(100000);
            var set: std.EnumSet(Enum) = .empty;
            inline for (@typeInfo(@TypeOf(entries)).@"struct".field_names) |struct_field_name| {
                if (@field(entries, struct_field_name)) {
                    inline for (@typeInfo(Enum).@"enum".field_names, @typeInfo(Enum).@"enum".field_values) |enum_field_name, enum_field_value| {
                        if (comptime std.mem.eql(u8, enum_field_name, struct_field_name)) {
                            set.insert(@fromBackingInt(@intCast(enum_field_value)));
                        }
                    }
                }
            }
            return .{ .set = set };
        }
    };
}
