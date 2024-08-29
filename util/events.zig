const std = @import("std");

pub fn getDispatcher(comptime Events: type, comptime listeners: anytype) type {
    comptime {
        validate(Events, listeners);
    }
    return struct {
        pub inline fn dispatch(comptime Event: type, event: Event) !void {
            inline for (listeners) |listener| {
                const listener_info = @typeInfo(@TypeOf(listener)).@"fn";
                if (listener_info.params[0].type == Event) {
                    if (@typeInfo(listener_info.return_type.?) == .error_union) {
                        try listener(event);
                    } else {
                        listener(event);
                    }
                }
            }
        }
    };
}

/// Validate event listener types
fn validate(comptime Events: type, comptime listeners: anytype) void {
    for (listeners) |listener| {
        const info = switch (@typeInfo(@TypeOf(listener))) {
            .@"fn" => |@"fn"| @"fn",
            else => @compileError("Event listener must be function, found " ++ @typeName(@TypeOf(listener))),
        };
        if (info.is_generic) @compileError("Event listener cannot be generic, found " ++ @typeName(@TypeOf(listener)));
        if (info.is_var_args) @compileError("Event listener cannot be varargs, found " ++ @typeName(@TypeOf(listener)));
        if (info.return_type == null or (info.return_type.? != void and !isVoidErrorUnion(info.return_type.?))) {
            @compileError("Event listener must return void or !void, found " ++ @typeName(@TypeOf(listener)));
        }
        if (info.params.len != 1) @compileError("Event listener must have exactly 1 parameter, found " ++ @typeName(@TypeOf(listener)));
        if (info.params[0].is_generic) @compileError("Event listener parameter cannot be generic, found " ++ @typeName(@TypeOf(listener)));
        for (declList(Events, type)) |EventType| {
            if (info.params[0].type.? == EventType) break;
        } else @compileError("Event listener parameter must take Event, found " ++ @typeName(@TypeOf(listener)));
    }
}

fn declList(comptime Container: type, comptime Decl: type) []const Decl {
    const decl_names = @typeInfo(Container).@"struct".decls;
    var decls: [decl_names.len]Decl = undefined;
    for (decl_names, &decls) |decl_name, *decl| {
        decl.* = @field(Container, decl_name.name);
    }
    return &decls;
}

fn isVoidErrorUnion(comptime @"type": type) bool {
    const info = @typeInfo(@"type");
    if (info != .error_union) return false;
    return info.error_union.payload == void;
}
