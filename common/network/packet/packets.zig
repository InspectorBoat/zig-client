const std = @import("std");
const ReadPacketBuffer = @import("../../network/packet/ReadPacketBuffer.zig");
const WritePacketBuffer = @import("../../network/packet/WritePacketBuffer.zig");
const Game = @import("../../game.zig").Game;
const Connection = @import("../../network/connection.zig");
const recursisvelyFree = @import("../../util/recursivelyfree.zig").recursivelyFree;

pub const S2CPlayPacket = union(enum) {
    /// decodes a packet buffer into a type-erased packet
    pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
        // the amount of packet types in this union
        const PacketTypeCount = @typeInfo(@This()).Union.fields.len;

        // read the opcode of the packet from the buffer
        switch (try buffer.readVarInt()) {
            // opcode must be comptime known, thus inline is necessary
            inline 0...PacketTypeCount - 1 => |opcode| {
                // the packet type corresponding to the opcode
                const PacketType = typeFromOpcode(opcode);
                // the field name of the packet type corresponding to the opcode
                const PacketName = comptime nameFromOpcode(opcode);
                return @unionInit(
                    @This(),
                    PacketName,
                    // decode packet using decoder
                    try PacketType.decode(buffer, allocator),
                );
            },
            // error on invalid opcodes
            else => |opcode| {
                @import("log").invalid_opcode(.{opcode});
                return error.InvalidOpcode;
            },
        }
    }

    /// handles a type-erased packet
    pub fn handleOnMainThread(packet: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
        switch (packet.*) {
            // specific packet type must be comptime known, thus inline else is necessary
            inline else => |*specific_packet| {
                std.debug.assert(!specific_packet.handle_on_network_thread);
                // required to comptime prune other packets to prevent a compile error
                if (!specific_packet.handle_on_network_thread) {
                    try specific_packet.handleOnMainThread(game, allocator);
                }
            },
        }
    }
    // Of these, only CompressionThreshold, Keepalive, and Disconnect really need to be handled on the network thread
    // .CompressionThreshold, .TabList, .KeepAlive, .ResourcePack, .Disconnect,
    pub fn handleOnNetworkThread(packet: *@This(), server_connection: *Connection) !void {
        switch (packet) {
            inline else => |*specific_packet| {
                std.debug.assert(specific_packet.handle_on_network_thread);
                // required to comptime prune other packets to prevent a compile error
                if (specific_packet.handle_on_network_thread) {
                    specific_packet.handleOnNetworkThread(server_connection);
                }
            },
        }
    }

    pub fn nameFromOpcode(comptime opcode: i32) []const u8 {
        return @typeInfo(@This()).Union.fields[opcode].name;
    }
    pub fn typeFromOpcode(comptime opcode: i32) type {
        return @typeInfo(@This()).Union.fields[opcode].type;
    }

    KeepAlive: @import("../../network/packet/s2c/play/KeepAliveS2CPacket.zig"),
    Login: @import("../../network/packet/s2c/play/LoginS2CPacket.zig"),
    ChatMessage: @import("../../network/packet/s2c/play/ChatMessageS2CPacket.zig"),
    WorldTime: @import("../../network/packet/s2c/play/WorldTimeS2CPacket.zig"),
    EntityEquipment: @import("../../network/packet/s2c/play/EntityEquipmentS2CPacket.zig"),
    SpawnPoint: @import("../../network/packet/s2c/play/SpawnPointS2CPacket.zig"),
    PlayerHealth: @import("../../network/packet/s2c/play/PlayerHealthS2CPacket.zig"),
    PlayerRespawn: @import("../../network/packet/s2c/play/PlayerRespawnS2CPacket.zig"),
    PlayerMove: @import("../../network/packet/s2c/play/PlayerMoveS2CPacket.zig"),
    SelectSlot: @import("../../network/packet/s2c/play/SelectSlotS2CPacket.zig"),
    PlayerSleep: @import("../../network/packet/s2c/play/PlayerSleepS2CPacket.zig"),
    EntityAnimation: @import("../../network/packet/s2c/play/EntityAnimationS2CPacket.zig"),
    AddPlayer: @import("../../network/packet/s2c/play/AddPlayerS2CPacket.zig"),
    EntityPickup: @import("../../network/packet/s2c/play/EntityPickupS2CPacket.zig"),
    AddEntity: @import("../../network/packet/s2c/play/AddEntityS2CPacket.zig"),
    AddMob: @import("../../network/packet/s2c/play/AddMobS2CPacket.zig"),
    AddPainting: @import("../../network/packet/s2c/play/AddPaintingS2CPacket.zig"),
    AddXpOrb: @import("../../network/packet/s2c/play/AddXpOrbS2CPacket.zig"),
    EntityVelocity: @import("../../network/packet/s2c/play/EntityVelocityS2CPacket.zig"),
    RemoveEntities: @import("../../network/packet/s2c/play/RemoveEntitiesS2CPacket.zig"),
    EntityMove: @import("../../network/packet/s2c/play/EntityMoveS2CPacket.zig"),
    EntityMovePosition: @import("../../network/packet/s2c/play/EntityMoveS2CPacket.zig").Position,
    EntityMoveAngles: @import("../../network/packet/s2c/play/EntityMoveS2CPacket.zig").Angles,
    EntityMovePositionAngles: @import("../../network/packet/s2c/play/EntityMoveS2CPacket.zig").PositionAndAngles,
    EntityTeleport: @import("../../network/packet/s2c/play/EntityTeleportS2CPacket.zig"),
    EntityHeadAngles: @import("../../network/packet/s2c/play/EntityHeadAnglesS2CPacket.zig"),
    EntityEvent: @import("../../network/packet/s2c/play/EntityEventS2CPacket.zig"),
    EntityAttach: @import("../../network/packet/s2c/play/EntityAttachS2CPacket.zig"),
    EntityData: @import("../../network/packet/s2c/play/EntityDataS2CPacket.zig"),
    EntityStatusEffect: @import("../../network/packet/s2c/play/EntityStatusEffectS2CPacket.zig"),
    EntityRemoveStatusEffect: @import("../../network/packet/s2c/play/EntityRemoveStatusEffectS2CPacket.zig"),
    PlayerXp: @import("../../network/packet/s2c/play/PlayerXpS2CPacket.zig"),
    EntityAttributes: @import("../../network/packet/s2c/play/EntityAttributesS2CPacket.zig"),
    WorldChunk: @import("../../network/packet/s2c/play/WorldChunkS2CPacket.zig"),
    BlocksUpdate: @import("../../network/packet/s2c/play/BlocksUpdateS2CPacket.zig"),
    BlockUpdate: @import("../../network/packet/s2c/play/BlockUpdateS2CPacket.zig"),
    BlockEvent: @import("../../network/packet/s2c/play/BlockEventS2CPacket.zig"),
    BlockMiningProgress: @import("../../network/packet/s2c/play/BlockMiningProgressS2CPacket.zig"),
    WorldChunks: @import("../../network/packet/s2c/play/WorldChunksS2CPacket.zig"),
    Explosion: @import("../../network/packet/s2c/play/ExplosionS2CPacket.zig"),
    WorldEvent: @import("../../network/packet/s2c/play/WorldEventS2CPacket.zig"),
    SoundEvent: @import("../../network/packet/s2c/play/SoundEventS2CPacket.zig"),
    Particle: @import("../../network/packet/s2c/play/ParticleS2CPacket.zig"),
    GameEvent: @import("../../network/packet/s2c/play/GameEventS2CPacket.zig"),
    AddGlobalEntity: @import("../../network/packet/s2c/play/AddGlobalEntityS2CPacket.zig"),
    OpenMenu: @import("../../network/packet/s2c/play/OpenMenuS2CPacket.zig"),
    CloseMenu: @import("../../network/packet/s2c/play/CloseMenuS2CPacket.zig"),
    MenuSlotUpdate: @import("../../network/packet/s2c/play/MenuSlotUpdateS2CPacket.zig"),
    InventoryMenu: @import("../../network/packet/s2c/play/InventoryMenuS2CPacket.zig"),
    MenuData: @import("../../network/packet/s2c/play/MenuDataS2CPacket.zig"),
    ConfirmMenuAction: @import("../../network/packet/s2c/play/ConfirmMenuActionS2CPacket.zig"),
    SignUpdate: @import("../../network/packet/s2c/play/SignUpdateS2CPacket.zig"),
    MapData: @import("../../network/packet/s2c/play/MapDataS2CPacket.zig"),
    BlockEntityUpdate: @import("../../network/packet/s2c/play/BlockEntityUpdateS2CPacket.zig"),
    OpenSignEditor: @import("../../network/packet/s2c/play/OpenSignEditorS2CPacket.zig"),
    Statistics: @import("../../network/packet/s2c/play/StatisticsS2CPacket.zig"),
    PlayerInfo: @import("../../network/packet/s2c/play/PlayerInfoS2CPacket.zig"),
    PlayerAbilities: @import("../../network/packet/s2c/play/PlayerAbilitiesS2CPacket.zig"),
    CommandSuggestions: @import("../../network/packet/s2c/play/CommandSuggestionsS2CPacket.zig"),
    ScoreboardObjective: @import("../../network/packet/s2c/play/ScoreboardObjectiveS2CPacket.zig"),
    ScoreboardScore: @import("../../network/packet/s2c/play/ScoreboardScoreS2CPacket.zig"),
    ScoreboardDisplay: @import("../../network/packet/s2c/play/ScoreboardDisplayS2CPacket.zig"),
    Team: @import("../../network/packet/s2c/play/TeamS2CPacket.zig"),
    CustomPayload: @import("../../network/packet/s2c/play/CustomPayloadS2CPacket.zig"),
    Disconnect: @import("../../network/packet/s2c/play/DisconnectS2CPacket.zig"),
    Difficulty: @import("../../network/packet/s2c/play/DifficultyS2CPacket.zig"),
    PlayerCombat: @import("../../network/packet/s2c/play/PlayerCombatS2CPacket.zig"),
    Camera: @import("../../network/packet/s2c/play/CameraS2CPacket.zig"),
    WorldBorder: @import("../../network/packet/s2c/play/WorldBorderS2CPacket.zig"),
    Titles: @import("../../network/packet/s2c/play/TitlesS2CPacket.zig"),
    CompressionThreshold: @import("../../network/packet/s2c/play/CompressionThresholdS2CPacket.zig"),
    TabList: @import("../../network/packet/s2c/play/TabListS2CPacket.zig"),
    ResourcePack: @import("../../network/packet/s2c/play/ResourcePackS2CPacket.zig"),
    EntitySync: @import("../../network/packet/s2c/play/EntitySyncS2CPacket.zig"),
};

pub const S2CLoginPacket = union(enum) {
    /// decodes a packet buffer into a type-erased packet
    pub fn decode(buffer: *ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
        // the amount of packet types in this union
        const PacketTypeCount = @typeInfo(@This()).Union.fields.len;

        // read the opcode of the packet from the buffer
        switch (try buffer.readVarInt()) {
            // opcode must be comptime known, thus inline is necessary
            inline 0...PacketTypeCount - 1 => |opcode| {
                // the packet type corresponding to the opcode
                const PacketType = typeFromOpcode(opcode);
                // the field name of the packet type corresponding to the opcode
                const PacketName = comptime nameFromOpcode(opcode);
                return @unionInit(
                    @This(),
                    PacketName,
                    // decode packet using decoder
                    try PacketType.decode(buffer, allocator),
                );
            },
            // error on invalid opcodes
            else => |opcode| {
                @import("log").invalid_opcode(.{opcode});
                return error.InvalidOpcode;
            },
        }
    }

    /// handles a type-erased packet
    pub fn handleOnMainThread(packet: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
        switch (packet.*) {
            // specific packet type must be comptime known, thus inline else is necessary
            inline else => |*specific_packet| {
                std.debug.assert(!specific_packet.handle_on_network_thread);
                // required to comptime prune other packets to prevent a compile error
                if (!specific_packet.handle_on_network_thread) {
                    try specific_packet.handleOnMainThread(game, allocator);
                }
            },
        }
    }
    // Of these, only CompressionThreshold, Keepalive, and Disconnect really need to be handled on the network thread
    // .CompressionThreshold, .TabList, .KeepAlive, .ResourcePack, .Disconnect,
    pub fn handleOnNetworkThread(packet: *@This(), server_connection: *Connection) !void {
        switch (packet) {
            inline else => |*specific_packet| {
                std.debug.assert(specific_packet.handle_on_network_thread);
                // required to comptime prune other packets to prevent a compile error
                if (specific_packet.handle_on_network_thread) {
                    specific_packet.handleOnNetworkThread(server_connection);
                }
            },
        }
    }

    pub fn nameFromOpcode(comptime opcode: i32) []const u8 {
        return @typeInfo(@This()).Union.fields[opcode].name;
    }
    pub fn typeFromOpcode(comptime opcode: i32) type {
        return @typeInfo(@This()).Union.fields[opcode].type;
    }

    LoginFail: @import("../../network/packet/s2c/login/LoginFailS2CPacket.zig"),
    Hello: @import("../../network/packet/s2c/login/HelloS2CPacket.zig"),
    LoginSuccess: @import("../../network/packet/s2c/login/LoginSuccessS2CPacket.zig"),
    CompressionThreshold: @import("../../network/packet/s2c/login/CompressionThresholdS2CPacket.zig"),
};

pub const C2SHandshakePacket = union(enum) {
    /// writes a type-erased packet
    pub fn write(packet: @This(), buffer: *WritePacketBuffer) !void {
        try buffer.writeVarInt(@intFromEnum(packet));
        switch (packet) {
            // specific packet type must be comptime known, thus inline else is necessary
            inline else => |specific_packet| {
                try specific_packet.write(buffer);
            },
        }
    }

    Handshake: @import("../../network/packet/c2s/handshake/HandshakeC2SPacket.zig"),
};

pub const C2SLoginPacket = union(enum) {
    /// writes a type-erased packet
    pub fn write(packet: @This(), buffer: *WritePacketBuffer) !void {
        try buffer.writeVarInt(@intFromEnum(packet));
        switch (packet) {
            // specific packet type must be comptime known, thus inline else is necessary
            inline else => |specific_packet| {
                try specific_packet.write(buffer);
            },
        }
    }

    Hello: @import("../../network/packet/c2s/login/HelloC2SPacket.zig"),
    Key: @import("../../network/packet/c2s/login/KeyC2SPacket.zig"),
};

pub const C2SPlayPacket = union(enum) {
    /// writes a type-erased packet
    pub fn write(packet: @This(), buffer: *WritePacketBuffer) !void {
        try buffer.writeVarInt(@intFromEnum(packet));
        switch (packet) {
            // specific packet type must be comptime known, thus inline else is necessary
            inline else => |specific_packet| {
                try specific_packet.write(buffer);
            },
        }
    }

    KeepAlive: @import("../../network/packet/c2s/play/KeepAliveC2SPacket.zig"),
    ChatMessage: @import("../../network/packet/c2s/play/ChatMessageC2SPacket.zig"),
    PlayerInteractEntity: @import("../../network/packet/c2s/play/PlayerInteractEntityC2SPacket.zig"),
    PlayerMove: @import("../../network/packet/c2s/play/PlayerMoveC2SPacket.zig"),
    PlayerMovePosition: @import("../../network/packet/c2s/play/PlayerMoveC2SPacket.zig").Position,
    PlayerMoveAngles: @import("../../network/packet/c2s/play/PlayerMoveC2SPacket.zig").Angles,
    PlayerMovePositionAndAngles: @import("../../network/packet/c2s/play/PlayerMoveC2SPacket.zig").PositionAndAngles,
    PlayerHandAction: @import("../../network/packet/c2s/play/PlayerHandActionC2SPacket.zig"),
    PlayerUse: @import("../../network/packet/c2s/play/PlayerUseC2SPacket.zig"),
    SelectSlot: @import("../../network/packet/c2s/play/SelectSlotC2SPacket.zig"),
    HandSwing: @import("../../network/packet/c2s/play/HandSwingC2SPacket.zig"),
    PlayerMovementAction: @import("../../network/packet/c2s/play/PlayerMovementActionC2SPacket.zig"),
    PlayerInput: @import("../../network/packet/c2s/play/PlayerInputC2SPacket.zig"),
    CloseMenu: @import("../../network/packet/c2s/play/CloseMenuC2SPacket.zig"),
    MenuClickSlot: @import("../../network/packet/c2s/play/MenuClickSlotC2SPacket.zig"),
    ConfirmMenuAction: @import("../../network/packet/c2s/play/ConfirmMenuActionC2SPacket.zig"),
    CreativeMenuSlot: @import("../../network/packet/c2s/play/CreativeMenuSlotC2SPacket.zig"),
    MenuClickButton: @import("../../network/packet/c2s/play/MenuClickButtonC2SPacket.zig"),
    SignUpdate: @import("../../network/packet/c2s/play/SignUpdateC2SPacket.zig"),
    PlayerAbilities: @import("../../network/packet/c2s/play/PlayerAbilitiesC2SPacket.zig"),
    CommandSuggestions: @import("../../network/packet/c2s/play/CommandSuggestionsC2SPacket.zig"),
    ClientSettings: @import("../../network/packet/c2s/play/ClientSettingsC2SPacket.zig"),
    ClientStatus: @import("../../network/packet/c2s/play/ClientStatusC2SPacket.zig"),
    CustomPayload: @import("../../network/packet/c2s/play/CustomPayloadC2SPacket.zig"),
    PlayerSpectate: @import("../../network/packet/c2s/play/PlayerSpectateC2SPacket.zig"),
    ResourcePack: @import("../../network/packet/c2s/play/ResourcePackC2SPacket.zig"),
};

pub const C2SPacket = union(enum) {
    Handshake: C2SHandshakePacket,
    Login: C2SLoginPacket,
    Play: C2SPlayPacket,
};

pub const S2CPacket = union(enum) {
    // only the client ever sends packets in the handshake protocol
    Login: S2CLoginPacket,
    Play: S2CPlayPacket,

    pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
        switch (self.*) {
            .Login => |*login_packet| try login_packet.handleOnMainThread(game, allocator),
            .Play => |*play_packet| try play_packet.handleOnMainThread(game, allocator),
        }
    }
};
