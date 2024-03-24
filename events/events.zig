const std = @import("std");

Events: type,
modules: []const type,

pub fn make(comptime Events: type, comptime imports: []const type) @This() {
    // for (imports) |import| {
    //     validate(Events, import);
    // }
    return .{ .Events = Events, .modules = imports };
}
pub fn dispatch(comptime self: @This(), comptime EventType: enumFromDecls(self.Events), event: declFromEnumTag(self.Events, EventType)) !void {
    inline for (self.modules) |module| {
        const listeners = module.event_listeners;
        inline for (listeners) |listener| {
            if (@typeInfo(@TypeOf(listener)).Fn.params[0].type == @TypeOf(event)) {
                if (@typeInfo(@typeInfo(@TypeOf(listener)).Fn.return_type.?) == .ErrorUnion) {
                    try listener(event);
                } else {
                    listener(event);
                }
            }
        }
    }
}
fn declFromEnumTag(comptime Container: type, comptime tag: anytype) type {
    return @field(Container, @tagName(tag));
}
fn enumFromDecls(comptime Container: type) type {
    var fields: []const std.builtin.Type.EnumField = &.{};
    for (std.meta.declarations(Container), 0..) |declaration, i| {
        fields = fields ++ .{@as(std.builtin.Type.EnumField, .{
            .name = declaration.name,
            .value = i,
        })};
    }
    return @Type(.{ .Enum = .{
        .tag_type = std.math.IntFittingRange(0, fields.len - 1),
        .fields = fields,
        .decls = &.{},
        .is_exhaustive = true,
    } });
}
fn validate(comptime Events: type, comptime import: type) void {
    comptime {
        if (!@hasDecl(import, "event_listeners")) @compileError(@typeName(import) ++ " does not have an event_listeners struct!");
        for (import.event_listeners) |listener| {
            // validate event listener types
            const info = @typeInfo(@TypeOf(listener));
            if (info != .Fn) @compileError("Event listener must be function, found " ++ @typeName(@TypeOf(listener)));
            if (info.Fn.is_generic) @compileError("Event listener cannot be generic, found " ++ @typeName(@TypeOf(listener)));
            if (info.Fn.is_var_args) @compileError("Event listener cannot be varargs, found " ++ @typeName(@TypeOf(listener)));
            if (info.Fn.return_type == null or (info.Fn.return_type.? != void and !isVoidErrorUnion(info.Fn.return_type.?))) {
                @compileError("Event listener must return void or !void, found " ++ @typeName(@TypeOf(listener)));
            }
            if (info.Fn.params.len != 1) @compileError("Event listener must have exactly 1 parameter, found " ++ @typeName(@TypeOf(listener)));
            if (info.Fn.params[0].is_generic) @compileError("Event listener parameter cannot be generic, found " ++ @typeName(@TypeOf(listener)));
            for (std.meta.declList(Events, type)) |EventType| {
                if (info.Fn.params[0].type.? == EventType.*) break;
            } else @compileError("Event listener parameter must take Event, found " ++ @typeName(@TypeOf(listener)));
        }
    }
}
fn declList(comptime Namespace: type, comptime Decl: type) []const Decl {
    comptime {
        const decls = std.meta.declarations(Namespace);
        var array: [decls.len]*const Decl = undefined;
        for (decls, 0..) |decl, i| {
            array[i] = @field(Namespace, decl.name);
        }
        return &array;
    }
}
fn isVoidErrorUnion(comptime @"type": type) bool {
    const info = @typeInfo(@"type");
    if (info != .ErrorUnion) return false;
    return info.ErrorUnion.payload == void;
}
