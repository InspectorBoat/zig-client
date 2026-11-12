pub fn main(_: std.process.Init) !void {
    _ = try network.Session.parseFromPrismLauncher(
        undefined,
        undefined,
        undefined,
    );

    @import("render").onStartup(undefined) catch {};
    defer @import("render").onExit(undefined) catch {};
    try @import("render").onFrame(undefined);

    while (true) {
        while (true) {
            var p: network.packet.S2C.Play = undefined;
            switch (p) {
                inline else => |*p2| {
                    if (p2.handle_on_network_thread) continue;
                    try p2.handleOnMainThread(undefined, undefined, undefined);
                },
            }
        }
    }
}

pub const Events = struct {
    pub const Startup = struct { gpa: std.mem.Allocator, io: std.Io };
    pub const ChunkUpdate = struct { gpa: std.mem.Allocator, chunk_pos: Vector2xz(i32), chunk: *const World.Chunk, world: *const World };
    pub const UnloadChunk = struct { chunk_pos: Vector2xz(i32) };
    pub const Frame = struct { client: *const Client, input_queue: ?*Client.InputQueue, io: std.Io, allocator: std.mem.Allocator };
    pub const Exit = struct { io: std.Io, gpa: std.mem.Allocator };
};

pub const EventHandler = struct {
    pub const listeners = if (build_options.graphics == .headless) .{} else render.event_listeners;

    pub const dispatch = util.events.getDispatcher(Events, listeners).dispatch;
};

const builtin = @import("builtin");
const std = @import("std");

const build_options = @import("build_options");
const render = @import("render");
const util = @import("util");

pub const block = @import("block/block.zig");
pub const Inventory = @import("inventory/Inventory.zig");
pub const Menu = @import("inventory/Menu.zig");
pub const math = @import("math/math.zig");
pub const network = @import("network/network.zig");
pub const World = @import("world/World.zig");
pub const Client = @import("client/client.zig").Client;
pub const Entity = @import("entity/entity.zig").Entity;
pub const Item = @import("item/item.zig").Item;
pub const Nbt = @import("nbt/nbt.zig").Nbt;

pub const Block = block.Block;
pub const Box = math.Box;
pub const Direction = math.Direction;
pub const HitResult = math.HitResult;
pub const HitType = math.HitType;
pub const MathHelper = math.MathHelper;
pub const Rotation2 = math.Rotation2;
pub const Rotation3 = math.Rotation3;
pub const Vector2xy = math.Vector2xy;
pub const Vector2xz = math.Vector2xz;
pub const Vector3 = math.Vector3;
