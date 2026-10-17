const std = @import("std");

const build_options = @import("build_options");
const render = @import("render");
const util = @import("util");

pub const block = @import("block/block.zig");
pub const item = @import("item/item.zig");
pub const math = @import("math/math.zig");
pub const Menu = @import("inventory/Menu.zig");
pub const Inventory = @import("inventory/Inventory.zig");
pub const network = @import("network/network.zig");
pub const World = @import("world/World.zig");
pub const Client = @import("client/client.zig").Client;
pub const Entity = @import("entity/entity.zig").Entity;
pub const EntityType = @import("entity/entity.zig").EntityType;
pub const Nbt = @import("nbt/nbt.zig").Nbt;

pub const Block = block.Block;
pub const Item = item.Item;
pub const ItemStack = item.ItemStack;
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
pub const Chunk = World.Chunk;
pub const Section = World.Section;

pub const opengl_error_handling = .assert;

pub const std_options: std.Options = .{
    .log_scope_levels = &.{
        .{ .scope = .tick_late, .level = .warn },
        .{ .scope = .tick_on_time, .level = .warn },
        .{ .scope = .handle_packet_main, .level = .warn },
        .{ .scope = .handle_packet_net, .level = .warn },
        .{ .scope = .world, .level = .warn },
        .{ .scope = .decode_packet, .level = .warn },
        .{ .scope = .send_packet, .level = .warn },
        .{ .scope = .entity, .level = .warn },
        .{ .scope = .local_player_moved, .level = .warn },
        .{ .scope = .player, .level = .warn },
        .{ .scope = .net, .level = .info },
        .{ .scope = .resource_pack_states, .level = .err },
        .{ .scope = .resource_pack, .level = .info },
        .{ .scope = .section_revision, .level = .warn },
        .{ .scope = .ring_buffer, .level = .warn },
    },
};

pub fn main(init: std.process.Init) !void {
    // var gpa_impl: std.heap.SafeAllocator = .init(std.heap.page_allocator, .{
    //     .stack_trace_frames = 15,
    // });
    // const gpa = gpa_impl.allocator();
    // defer _ = gpa_impl.deinit();
    const gpa = init.gpa;

    try EventHandler.dispatch(Events.Startup, .{ .gpa = gpa, .io = init.io });

    var client: Client = .{ .idle = .{
        .gpa = gpa,
    } };

    var c2s_packet_alloc_impl: std.heap.DebugAllocator(.{}) = .{};
    const c2s_packet_alloc = c2s_packet_alloc_impl.allocator();

    try client.idle.initConnection(init.io, gpa, c2s_packet_alloc, "127.0.0.1", 25565, "baz");

    defer {
        if (client != .idle) client.disconnect(init.io);
    }

    while (true) {
        try EventHandler.dispatch(Events.Frame, .{
            .client = &client,
            .input_queue = if (client == .game) &client.game.input_queue else null,
            .io = init.io,
        });

        if (client != .idle) try client.tickConnection(init.io);
        if (client == .game) try client.updateGame(init.io);

        if (done) break;
    }
}

var done = false;
pub fn exit(_: Events.Exit) void {
    done = true;
}

pub const Events = struct {
    pub const Startup = struct { gpa: std.mem.Allocator, io: std.Io };
    pub const ChunkUpdate = struct { chunk_pos: Vector2xz(i32), chunk: *const Chunk, world: *const World };
    pub const BlockUpdate = struct { block_pos: Vector3(i32), world: *const World };
    pub const UnloadChunk = struct { chunk_pos: Vector2xz(i32) };
    pub const Frame = struct { client: *const Client, input_queue: ?*Client.InputQueue, io: std.Io };
    pub const Exit = struct { io: std.Io };
};

pub const EventHandler = struct {
    pub const listeners = if (build_options.headless)
        .{exit}
    else
        .{exit} ++ render.event_listeners;

    pub const dispatch = util.events.getDispatcher(Events, listeners).dispatch;
};

test {
    _ = World.ChunkMap;
    _ = Nbt;
    _ = network.packet.C2S.WriteBuffer;
    _ = network.packet.S2C.ReadBuffer;
}
