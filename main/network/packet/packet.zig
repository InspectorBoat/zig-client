const std = @import("std");
const root = @import("root");
const Game = @import("../../game.zig").Game;
const Connection = @import("../../network/connection.zig");

pub const S2CPlayPacket = union(enum) {
    /// decodes a packet buffer into a type-erased packet
    pub fn decode(buffer: *s2c.ReadPacketBuffer, allocator: std.mem.Allocator) !@This() {
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

    KeepAlive: s2c.play.KeepAliveS2CPacket,
    Login: s2c.play.LoginS2CPacket,
    ChatMessage: s2c.play.ChatMessageS2CPacket,
    WorldTime: s2c.play.WorldTimeS2CPacket,
    EntityEquipment: s2c.play.EntityEquipmentS2CPacket,
    SpawnPoint: s2c.play.SpawnPointS2CPacket,
    PlayerHealth: s2c.play.PlayerHealthS2CPacket,
    PlayerRespawn: s2c.play.PlayerRespawnS2CPacket,
    PlayerMove: s2c.play.PlayerMoveS2CPacket,
    SelectSlot: s2c.play.SelectSlotS2CPacket,
    PlayerSleep: s2c.play.PlayerSleepS2CPacket,
    EntityAnimation: s2c.play.EntityAnimationS2CPacket,
    AddPlayer: s2c.play.AddPlayerS2CPacket,
    EntityPickup: s2c.play.EntityPickupS2CPacket,
    AddEntity: s2c.play.AddEntityS2CPacket,
    AddMob: s2c.play.AddMobS2CPacket,
    AddPainting: s2c.play.AddPaintingS2CPacket,
    AddXpOrb: s2c.play.AddXpOrbS2CPacket,
    EntityVelocity: s2c.play.EntityVelocityS2CPacket,
    RemoveEntities: s2c.play.RemoveEntitiesS2CPacket,
    EntityMove: s2c.play.EntityMoveS2CPacket,
    EntityMovePosition: s2c.play.EntityMovePositionS2CPacket,
    EntityMoveAngles: s2c.play.EntityMoveAnglesS2CPacket,
    EntityMovePositionAngles: s2c.play.EntityMovePositionAndAnglesS2CPacket,
    EntityTeleport: s2c.play.EntityTeleportS2CPacket,
    EntityHeadAngles: s2c.play.EntityHeadAnglesS2CPacket,
    EntityEvent: s2c.play.EntityEventS2CPacket,
    EntityAttach: s2c.play.EntityAttachS2CPacket,
    EntityData: s2c.play.EntityDataS2CPacket,
    EntityStatusEffect: s2c.play.EntityStatusEffectS2CPacket,
    EntityRemoveStatusEffect: s2c.play.EntityRemoveStatusEffectS2CPacket,
    PlayerXp: s2c.play.PlayerXpS2CPacket,
    EntityAttributes: s2c.play.EntityAttributesS2CPacket,
    WorldChunk: s2c.play.WorldChunkS2CPacket,
    BlocksUpdate: s2c.play.BlocksUpdateS2CPacket,
    BlockUpdate: s2c.play.BlockUpdateS2CPacket,
    BlockEvent: s2c.play.BlockEventS2CPacket,
    BlockMiningProgress: s2c.play.BlockMiningProgressS2CPacket,
    WorldChunks: s2c.play.WorldChunksS2CPacket,
    Explosion: s2c.play.ExplosionS2CPacket,
    WorldEvent: s2c.play.WorldEventS2CPacket,
    SoundEvent: s2c.play.SoundEventS2CPacket,
    Particle: s2c.play.ParticleS2CPacket,
    GameEvent: s2c.play.GameEventS2CPacket,
    AddGlobalEntity: s2c.play.AddGlobalEntityS2CPacket,
    OpenMenu: s2c.play.OpenMenuS2CPacket,
    CloseMenu: s2c.play.CloseMenuS2CPacket,
    MenuSlotUpdate: s2c.play.MenuSlotUpdateS2CPacket,
    InventoryMenu: s2c.play.InventoryMenuS2CPacket,
    MenuData: s2c.play.MenuDataS2CPacket,
    ConfirmMenuAction: s2c.play.ConfirmMenuActionS2CPacket,
    SignUpdate: s2c.play.SignUpdateS2CPacket,
    MapData: s2c.play.MapDataS2CPacket,
    BlockEntityUpdate: s2c.play.BlockEntityUpdateS2CPacket,
    OpenSignEditor: s2c.play.OpenSignEditorS2CPacket,
    Statistics: s2c.play.StatisticsS2CPacket,
    PlayerInfo: s2c.play.PlayerInfoS2CPacket,
    PlayerAbilities: s2c.play.PlayerAbilitiesS2CPacket,
    CommandSuggestions: s2c.play.CommandSuggestionsS2CPacket,
    ScoreboardObjective: s2c.play.ScoreboardObjectiveS2CPacket,
    ScoreboardScore: s2c.play.ScoreboardScoreS2CPacket,
    ScoreboardDisplay: s2c.play.ScoreboardDisplayS2CPacket,
    Team: s2c.play.TeamS2CPacket,
    CustomPayload: s2c.play.CustomPayloadS2CPacket,
    Disconnect: s2c.play.DisconnectS2CPacket,
    Difficulty: s2c.play.DifficultyS2CPacket,
    PlayerCombat: s2c.play.PlayerCombatS2CPacket,
    Camera: s2c.play.CameraS2CPacket,
    WorldBorder: s2c.play.WorldBorderS2CPacket,
    Titles: s2c.play.TitlesS2CPacket,
    CompressionThreshold: s2c.play.CompressionThresholdS2CPacket,
    TabList: s2c.play.TabListS2CPacket,
    ResourcePack: s2c.play.ResourcePackS2CPacket,
    EntitySync: s2c.play.EntitySyncS2CPacket,
};

pub const S2CLoginPacket = union(enum) {
    /// decodes a packet buffer into a type-erased packet
    pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
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

    LoginFail: s2c.login.LoginFailS2CPacket,
    Hello: s2c.login.HelloS2CPacket,
    LoginSuccess: s2c.login.LoginSuccessS2CPacket,
    CompressionThreshold: s2c.login.CompressionThresholdS2CPacket,
};

pub const C2SHandshakePacket = union(enum) {
    /// writes a type-erased packet
    pub fn write(packet: @This(), buffer: *c2s.WriteBuffer) !void {
        try buffer.writeVarInt(@intFromEnum(packet));
        switch (packet) {
            // specific packet type must be comptime known, thus inline else is necessary
            inline else => |specific_packet| {
                try specific_packet.write(buffer);
            },
        }
    }

    Handshake: c2s.handshake.HandshakeC2SPacket,
};

pub const C2SLoginPacket = union(enum) {
    /// writes a type-erased packet
    pub fn write(packet: @This(), buffer: *c2s.WriteBuffer) !void {
        try buffer.writeVarInt(@intFromEnum(packet));
        switch (packet) {
            // specific packet type must be comptime known, thus inline else is necessary
            inline else => |specific_packet| {
                try specific_packet.write(buffer);
            },
        }
    }

    Hello: c2s.login.HelloC2SPacket,
    Key: c2s.login.KeyC2SPacket,
};

pub const C2SPlayPacket = union(enum) {
    /// writes a type-erased packet
    pub fn write(packet: @This(), buffer: *c2s.WriteBuffer) !void {
        try buffer.writeVarInt(@intFromEnum(packet));
        switch (packet) {
            // specific packet type must be comptime known, thus inline else is necessary
            inline else => |specific_packet| {
                try specific_packet.write(buffer);
            },
        }
    }

    KeepAlive: c2s.play.KeepAliveC2SPacket,
    ChatMessage: c2s.play.ChatMessageC2SPacket,
    PlayerInteractEntity: c2s.play.PlayerInteractEntityC2SPacket,
    PlayerMove: c2s.play.PlayerMoveC2SPacket,
    PlayerMovePosition: c2s.play.PlayerMovePositionC2SPacket,
    PlayerMoveAngles: c2s.play.PlayerMoveAnglesC2SPacket,
    PlayerMovePositionAndAngles: c2s.play.PlayerMovePositionAndAnglesC2SPacket,
    PlayerHandAction: c2s.play.PlayerHandActionC2SPacket,
    PlayerUse: c2s.play.PlayerUseC2SPacket,
    SelectSlot: c2s.play.SelectSlotC2SPacket,
    HandSwing: c2s.play.HandSwingC2SPacket,
    PlayerMovementAction: c2s.play.PlayerMovementActionC2SPacket,
    PlayerInput: c2s.play.PlayerInputC2SPacket,
    CloseMenu: c2s.play.CloseMenuC2SPacket,
    MenuClickSlot: c2s.play.MenuClickSlotC2SPacket,
    ConfirmMenuAction: c2s.play.ConfirmMenuActionC2SPacket,
    CreativeMenuSlot: c2s.play.CreativeMenuSlotC2SPacket,
    MenuClickButton: c2s.play.MenuClickButtonC2SPacket,
    SignUpdate: c2s.play.SignUpdateC2SPacket,
    PlayerAbilities: c2s.play.PlayerAbilitiesC2SPacket,
    CommandSuggestions: c2s.play.CommandSuggestionsC2SPacket,
    ClientSettings: c2s.play.ClientSettingsC2SPacket,
    ClientStatus: c2s.play.ClientStatusC2SPacket,
    CustomPayload: c2s.play.CustomPayloadC2SPacket,
    PlayerSpectate: c2s.play.PlayerSpectateC2SPacket,
    ResourcePack: c2s.play.ResourcePackC2SPacket,
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

pub const c2s = opaque {
    pub const WriteBuffer = @import("c2s/WriteBuffer.zig");
    pub const handshake = opaque {
        pub const HandshakeC2SPacket = @import("c2s/handshake/HandshakeC2SPacket.zig");
    };
    pub const login = opaque {
        pub const HelloC2SPacket = @import("c2s/login/HelloC2SPacket.zig");
        pub const KeyC2SPacket = @import("c2s/login/KeyC2SPacket.zig");
    };
    pub const play = opaque {
        pub const KeepAliveC2SPacket = @import("c2s/play/KeepAliveC2SPacket.zig");
        pub const ChatMessageC2SPacket = @import("c2s/play/ChatMessageC2SPacket.zig");
        pub const PlayerInteractEntityC2SPacket = @import("c2s/play/PlayerInteractEntityC2SPacket.zig");
        pub const PlayerMoveC2SPacket = @import("c2s/play/PlayerMoveC2SPacket.zig");
        pub const PlayerMovePositionC2SPacket = @import("c2s/play/PlayerMoveC2SPacket.zig").Position;
        pub const PlayerMoveAnglesC2SPacket = @import("c2s/play/PlayerMoveC2SPacket.zig").Angles;
        pub const PlayerMovePositionAndAnglesC2SPacket = @import("c2s/play/PlayerMoveC2SPacket.zig").PositionAndAngles;
        pub const PlayerHandActionC2SPacket = @import("c2s/play/PlayerHandActionC2SPacket.zig");
        pub const PlayerUseC2SPacket = @import("c2s/play/PlayerUseC2SPacket.zig");
        pub const SelectSlotC2SPacket = @import("c2s/play/SelectSlotC2SPacket.zig");
        pub const HandSwingC2SPacket = @import("c2s/play/HandSwingC2SPacket.zig");
        pub const PlayerMovementActionC2SPacket = @import("c2s/play/PlayerMovementActionC2SPacket.zig");
        pub const PlayerInputC2SPacket = @import("c2s/play/PlayerInputC2SPacket.zig");
        pub const CloseMenuC2SPacket = @import("c2s/play/CloseMenuC2SPacket.zig");
        pub const MenuClickSlotC2SPacket = @import("c2s/play/MenuClickSlotC2SPacket.zig");
        pub const ConfirmMenuActionC2SPacket = @import("c2s/play/ConfirmMenuActionC2SPacket.zig");
        pub const CreativeMenuSlotC2SPacket = @import("c2s/play/CreativeMenuSlotC2SPacket.zig");
        pub const MenuClickButtonC2SPacket = @import("c2s/play/MenuClickButtonC2SPacket.zig");
        pub const SignUpdateC2SPacket = @import("c2s/play/SignUpdateC2SPacket.zig");
        pub const PlayerAbilitiesC2SPacket = @import("c2s/play/PlayerAbilitiesC2SPacket.zig");
        pub const CommandSuggestionsC2SPacket = @import("c2s/play/CommandSuggestionsC2SPacket.zig");
        pub const ClientSettingsC2SPacket = @import("c2s/play/ClientSettingsC2SPacket.zig");
        pub const ClientStatusC2SPacket = @import("c2s/play/ClientStatusC2SPacket.zig");
        pub const CustomPayloadC2SPacket = @import("c2s/play/CustomPayloadC2SPacket.zig");
        pub const PlayerSpectateC2SPacket = @import("c2s/play/PlayerSpectateC2SPacket.zig");
        pub const ResourcePackC2SPacket = @import("c2s/play/ResourcePackC2SPacket.zig");
    };
    pub const status = opaque {
        pub const PingC2SPacket = @import("c2s/status/PingC2SPacket.zig");
        pub const ServerStatusC2SPacket = @import("c2s/status/ServerStatusC2SPacket.zig");
    };
};

pub const s2c = opaque {
    pub const ReadBuffer = @import("s2c/ReadBuffer.zig");
    pub const login = opaque {
        pub const CompressionThresholdS2CPacket = @import("s2c/login/CompressionThresholdS2CPacket.zig");
        pub const HelloS2CPacket = @import("s2c/login/HelloS2CPacket.zig");
        pub const LoginFailS2CPacket = @import("s2c/login/LoginFailS2CPacket.zig");
        pub const LoginSuccessS2CPacket = @import("s2c/login/LoginSuccessS2CPacket.zig");
    };
    pub const play = opaque {
        pub const KeepAliveS2CPacket = @import("s2c/play/KeepAliveS2CPacket.zig");
        pub const LoginS2CPacket = @import("s2c/play/LoginS2CPacket.zig");
        pub const ChatMessageS2CPacket = @import("s2c/play/ChatMessageS2CPacket.zig");
        pub const WorldTimeS2CPacket = @import("s2c/play/WorldTimeS2CPacket.zig");
        pub const EntityEquipmentS2CPacket = @import("s2c/play/EntityEquipmentS2CPacket.zig");
        pub const SpawnPointS2CPacket = @import("s2c/play/SpawnPointS2CPacket.zig");
        pub const PlayerHealthS2CPacket = @import("s2c/play/PlayerHealthS2CPacket.zig");
        pub const PlayerRespawnS2CPacket = @import("s2c/play/PlayerRespawnS2CPacket.zig");
        pub const PlayerMoveS2CPacket = @import("s2c/play/PlayerMoveS2CPacket.zig");
        pub const SelectSlotS2CPacket = @import("s2c/play/SelectSlotS2CPacket.zig");
        pub const PlayerSleepS2CPacket = @import("s2c/play/PlayerSleepS2CPacket.zig");
        pub const EntityAnimationS2CPacket = @import("s2c/play/EntityAnimationS2CPacket.zig");
        pub const AddPlayerS2CPacket = @import("s2c/play/AddPlayerS2CPacket.zig");
        pub const EntityPickupS2CPacket = @import("s2c/play/EntityPickupS2CPacket.zig");
        pub const AddEntityS2CPacket = @import("s2c/play/AddEntityS2CPacket.zig");
        pub const AddMobS2CPacket = @import("s2c/play/AddMobS2CPacket.zig");
        pub const AddPaintingS2CPacket = @import("s2c/play/AddPaintingS2CPacket.zig");
        pub const AddXpOrbS2CPacket = @import("s2c/play/AddXpOrbS2CPacket.zig");
        pub const EntityVelocityS2CPacket = @import("s2c/play/EntityVelocityS2CPacket.zig");
        pub const RemoveEntitiesS2CPacket = @import("s2c/play/RemoveEntitiesS2CPacket.zig");
        pub const EntityMoveS2CPacket = @import("s2c/play/EntityMoveS2CPacket.zig");
        pub const EntityMovePositionS2CPacket = @import("s2c/play/EntityMoveS2CPacket.zig").Position;
        pub const EntityMoveAnglesS2CPacket = @import("s2c/play/EntityMoveS2CPacket.zig").Angles;
        pub const EntityMovePositionAndAnglesS2CPacket = @import("s2c/play/EntityMoveS2CPacket.zig").PositionAndAngles;
        pub const EntityTeleportS2CPacket = @import("s2c/play/EntityTeleportS2CPacket.zig");
        pub const EntityHeadAnglesS2CPacket = @import("s2c/play/EntityHeadAnglesS2CPacket.zig");
        pub const EntityEventS2CPacket = @import("s2c/play/EntityEventS2CPacket.zig");
        pub const EntityAttachS2CPacket = @import("s2c/play/EntityAttachS2CPacket.zig");
        pub const EntityDataS2CPacket = @import("s2c/play/EntityDataS2CPacket.zig");
        pub const EntityStatusEffectS2CPacket = @import("s2c/play/EntityStatusEffectS2CPacket.zig");
        pub const EntityRemoveStatusEffectS2CPacket = @import("s2c/play/EntityRemoveStatusEffectS2CPacket.zig");
        pub const PlayerXpS2CPacket = @import("s2c/play/PlayerXpS2CPacket.zig");
        pub const EntityAttributesS2CPacket = @import("s2c/play/EntityAttributesS2CPacket.zig");
        pub const WorldChunkS2CPacket = @import("s2c/play/WorldChunkS2CPacket.zig");
        pub const BlocksUpdateS2CPacket = @import("s2c/play/BlocksUpdateS2CPacket.zig");
        pub const BlockUpdateS2CPacket = @import("s2c/play/BlockUpdateS2CPacket.zig");
        pub const BlockEventS2CPacket = @import("s2c/play/BlockEventS2CPacket.zig");
        pub const BlockMiningProgressS2CPacket = @import("s2c/play/BlockMiningProgressS2CPacket.zig");
        pub const WorldChunksS2CPacket = @import("s2c/play/WorldChunksS2CPacket.zig");
        pub const ExplosionS2CPacket = @import("s2c/play/ExplosionS2CPacket.zig");
        pub const WorldEventS2CPacket = @import("s2c/play/WorldEventS2CPacket.zig");
        pub const SoundEventS2CPacket = @import("s2c/play/SoundEventS2CPacket.zig");
        pub const ParticleS2CPacket = @import("s2c/play/ParticleS2CPacket.zig");
        pub const GameEventS2CPacket = @import("s2c/play/GameEventS2CPacket.zig");
        pub const AddGlobalEntityS2CPacket = @import("s2c/play/AddGlobalEntityS2CPacket.zig");
        pub const OpenMenuS2CPacket = @import("s2c/play/OpenMenuS2CPacket.zig");
        pub const CloseMenuS2CPacket = @import("s2c/play/CloseMenuS2CPacket.zig");
        pub const MenuSlotUpdateS2CPacket = @import("s2c/play/MenuSlotUpdateS2CPacket.zig");
        pub const InventoryMenuS2CPacket = @import("s2c/play/InventoryMenuS2CPacket.zig");
        pub const MenuDataS2CPacket = @import("s2c/play/MenuDataS2CPacket.zig");
        pub const ConfirmMenuActionS2CPacket = @import("s2c/play/ConfirmMenuActionS2CPacket.zig");
        pub const SignUpdateS2CPacket = @import("s2c/play/SignUpdateS2CPacket.zig");
        pub const MapDataS2CPacket = @import("s2c/play/MapDataS2CPacket.zig");
        pub const BlockEntityUpdateS2CPacket = @import("s2c/play/BlockEntityUpdateS2CPacket.zig");
        pub const OpenSignEditorS2CPacket = @import("s2c/play/OpenSignEditorS2CPacket.zig");
        pub const StatisticsS2CPacket = @import("s2c/play/StatisticsS2CPacket.zig");
        pub const PlayerInfoS2CPacket = @import("s2c/play/PlayerInfoS2CPacket.zig");
        pub const PlayerAbilitiesS2CPacket = @import("s2c/play/PlayerAbilitiesS2CPacket.zig");
        pub const CommandSuggestionsS2CPacket = @import("s2c/play/CommandSuggestionsS2CPacket.zig");
        pub const ScoreboardObjectiveS2CPacket = @import("s2c/play/ScoreboardObjectiveS2CPacket.zig");
        pub const ScoreboardScoreS2CPacket = @import("s2c/play/ScoreboardScoreS2CPacket.zig");
        pub const ScoreboardDisplayS2CPacket = @import("s2c/play/ScoreboardDisplayS2CPacket.zig");
        pub const TeamS2CPacket = @import("s2c/play/TeamS2CPacket.zig");
        pub const CustomPayloadS2CPacket = @import("s2c/play/CustomPayloadS2CPacket.zig");
        pub const DisconnectS2CPacket = @import("s2c/play/DisconnectS2CPacket.zig");
        pub const DifficultyS2CPacket = @import("s2c/play/DifficultyS2CPacket.zig");
        pub const PlayerCombatS2CPacket = @import("s2c/play/PlayerCombatS2CPacket.zig");
        pub const CameraS2CPacket = @import("s2c/play/CameraS2CPacket.zig");
        pub const WorldBorderS2CPacket = @import("s2c/play/WorldBorderS2CPacket.zig");
        pub const TitlesS2CPacket = @import("s2c/play/TitlesS2CPacket.zig");
        pub const CompressionThresholdS2CPacket = @import("s2c/play/CompressionThresholdS2CPacket.zig");
        pub const TabListS2CPacket = @import("s2c/play/TabListS2CPacket.zig");
        pub const ResourcePackS2CPacket = @import("s2c/play/ResourcePackS2CPacket.zig");
        pub const EntitySyncS2CPacket = @import("s2c/play/EntitySyncS2CPacket.zig");
    };
    pub const status = opaque {
        pub const PingS2CPacket = @import("s2c/status/PingS2CPacket.zig");
        pub const ServerStatusS2CPacket = @import("s2c/status/ServerStatusS2CPacket.zig");
    };
};
