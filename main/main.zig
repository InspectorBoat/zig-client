pub const block = @import("block/block.zig");

pub const Block = block.Block;
pub const RawBlockState = block.RawBlockState;
pub const FilteredState = block.FilteredBlockState;
pub const ConcreteBlock = block.ConcreteBlock;
pub const ConcreteBlockState = block.ConcreteBlockState;
pub const StoredBlockProperties = block.StoredBlockProperties;

pub const entity = @import("entity/entity.zig");

pub const EnderDragonEntity = entity.EnderDragonEntity;
pub const WitherEntity = entity.WitherEntity;
pub const BlazeEntity = entity.BlazeEntity;
pub const CaveSpiderEntity = entity.CaveSpiderEntity;
pub const CreeperEntity = entity.CreeperEntity;
pub const EndermiteEntity = entity.EndermiteEntity;
pub const GiantEntity = entity.GiantEntity;
pub const GuardianEntity = entity.GuardianEntity;
pub const SilverfishEntity = entity.SilverfishEntity;
pub const SkeletonEntity = entity.SkeletonEntity;
pub const SpiderEntity = entity.SpiderEntity;
pub const WitchEntity = entity.WitchEntity;
pub const ZombieEntity = entity.ZombieEntity;
pub const EndermanEntity = entity.EndermanEntity;
pub const IronGolemEntity = entity.IronGolemEntity;
pub const ZombiePigmanEntity = entity.ZombiePigmanEntity;
pub const ChickenEntity = entity.ChickenEntity;
pub const CowEntity = entity.CowEntity;
pub const EquineEntity = entity.EquineEntity;
pub const MooshroomEntity = entity.MooshroomEntity;
pub const OcelotEntity = entity.OcelotEntity;
pub const PigEntity = entity.PigEntity;
pub const RabbitEntity = entity.RabbitEntity;
pub const SheepEntity = entity.SheepEntity;
pub const SnowGolemEntity = entity.SnowGolemEntity;
pub const VillagerEntity = entity.VillagerEntity;
pub const WolfEntity = entity.WolfEntity;
pub const ArmorStandEntity = entity.ArmorStandEntity;
pub const EnderCrystalEntity = entity.EnderCrystalEntity;
pub const FallingBlockEntity = entity.FallingBlockEntity;
pub const FireworksEntity = entity.FireworksEntity;
pub const FishingBobberEntity = entity.FishingBobberEntity;
pub const ItemEntity = entity.ItemEntity;
pub const PrimedTntEntity = entity.PrimedTntEntity;
pub const XpOrbEntity = entity.XpOrbEntity;
pub const LocalPlayerEntity = entity.LocalPlayerEntity;
pub const RemotePlayerEntity = entity.RemotePlayerEntity;
pub const ArrowEntity = entity.ArrowEntity;
pub const EggEntity = entity.EggEntity;
pub const EnderPearlEntity = entity.EnderPearlEntity;
pub const ExperienceBottleEntity = entity.ExperienceBottleEntity;
pub const FireballEntity = entity.FireballEntity;
pub const PotionEntity = entity.PotionEntity;
pub const SmallFireballEntity = entity.SmallFireballEntity;
pub const SnowballEntity = entity.SnowballEntity;
pub const WitherSkullEntity = entity.WitherSkullEntity;
pub const BoatEntity = entity.BoatEntity;
pub const MinecartEntity = entity.MinecartEntity;
pub const LightningEntity = entity.LightningEntity;
pub const Entity = entity.Entity;

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

pub const Game = @import("game.zig").Game;

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

    var game: Game = .{ .Idle = .{ .gpa = gpa } };

    var c2s_packet_alloc_impl = std.heap.GeneralPurposeAllocator(.{}){};
    const c2s_packet_alloc = c2s_packet_alloc_impl.allocator();

    try game.initConnection("127.0.0.1", 25565, gpa, c2s_packet_alloc);
    try game.initLoginSequence("baz");

    while (true) {
        if (game == .Ingame) try game.advanceTimer();

        if (game != .Idle) try game.handleIncomingPackets();
        if (game == .Ingame) try game.tickWorld();
        if (game == .Ingame or game == .Connecting) game.checkConnection();

        try EventHandler.dispatch(Events.Frame, .{ .game = &game });
        if (done) break;
    }

    if (game == .Ingame or game == .Connecting) {
        game.disconnect();
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
    pub const Frame = struct { game: *Game };
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
