pub const block = @import("block/block.zig");

pub const Block = block.Block;
pub const RawBlockState = block.RawBlockState;
pub const FilteredState = block.FilteredBlockState;
pub const ConcreteBlock = block.ConcreteBlock;
pub const ConcreteBlockState = block.ConcreteBlockState;
pub const StoredBlockProperties = block.StoredBlockProperties;

pub const Entity = @import("entity/entity.zig").Entity;
pub const EntityType = @import("entity/entity.zig").EntityType;

pub const Menu = @import("menu/Menu.zig");

pub const item = @import("item/item.zig");

pub const Item = item.Item;
pub const ItemStack = item.ItemStack;

pub const math = @import("math/math.zig");
pub const Box = math.Box;
pub const Direction = math.Direction;
pub const HitType = math.HitType;
pub const HitResult = math.HitResult;
pub const Rotation2 = math.Rotation2;
pub const Rotation3 = math.Rotation3;
pub const Vector3 = math.Vector3;
pub const Vector2xz = math.Vector2xz;
pub const Vector2xy = math.Vector2xy;

pub const nbt = @import("nbt/nbt.zig");

pub const NbtElementTag = nbt.NbtElementTag;
pub const NbtReadError = nbt.NbtReadError;
pub const NbtWriteError = nbt.NbtWriteError;
pub const NbtElement = nbt.NbtElement;
pub const NbtEnd = nbt.NbtEnd;
pub const NbtByte = nbt.NbtByte;
pub const NbtShort = nbt.NbtShort;
pub const NbtInt = nbt.NbtInt;
pub const NbtLong = nbt.NbtLong;
pub const NbtFloat = nbt.NbtFloat;
pub const NbtDouble = nbt.NbtDouble;
pub const NbtByteArray = nbt.NbtByteArray;
pub const NbtString = nbt.NbtString;
pub const NbtList = nbt.NbtList;
pub const NbtCompound = nbt.NbtCompound;
pub const NbtIntArray = nbt.NbtIntArray;

pub const network = @import("network/network.zig");

pub const World = @import("world/World.zig");

pub const Chunk = World.Chunk;
pub const Section = World.Section;

pub const Client = @import("client.zig").Client;

const EnumBoolArray = @import("util").EnumBoolArray;
const std = @import("std");
const network_lib = @import("network");
const render = @import("render");

pub const opengl_error_handling = .assert;

pub fn main() !void {
    std.debug.print("\n---------------------\n", .{});

    try EventHandler.dispatch(Events.Startup, .{});

    var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_impl.allocator();

    try network_lib.init();
    defer network_lib.deinit();

    var client: Client = .{ .idle = .{ .gpa = gpa } };

    var c2s_packet_alloc_impl = std.heap.GeneralPurposeAllocator(.{}){};
    const c2s_packet_alloc = c2s_packet_alloc_impl.allocator();

    try client.initConnection("127.0.0.1", 25565, gpa, c2s_packet_alloc);
    try client.initLoginSequence("baz");

    while (true) {
        if (client == .game) try client.advanceTimer();

        if (client != .idle) try client.tickConnection();
        if (client == .game) try client.tickWorld();
        if (client != .idle) client.checkConnection();

        try EventHandler.dispatch(Events.Frame, .{ .client = &client });
        if (done) break;
    }

    if (client == .game or client == .connecting) {
        client.disconnect();
    }
    std.debug.print("leaks: {}\n", .{gpa_impl.detectLeaks()});
}

var done = false;
pub fn exit(_: Events.Exit) void {
    done = true;
}

pub const Events = struct {
    pub const Startup = struct {};
    pub const ChunkUpdate = struct { chunk_pos: Vector2xz(i32), chunk: *Chunk, world: *World };
    pub const BlockUpdate = struct { block_pos: Vector3(i32), world: *World };
    pub const UnloadChunk = struct { chunk_pos: Vector2xz(i32) };
    pub const Frame = struct { client: *Client };
    pub const Exit = struct {};
};

pub const EventHandler = struct {
    pub const listeners = .{exit} ++ @import("render").event_listeners;

    pub const dispatch = @import("util").events.getDispatcher(Events, listeners).dispatch;
};

test {
    _ = @import("world/ChunkMap.zig");
    _ = @import("block/metadata_conversion_table.zig");
}
