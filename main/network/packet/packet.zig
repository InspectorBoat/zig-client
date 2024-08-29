const std = @import("std");
const root = @import("root");
const Game = root.Game;
const Connection = root.network.Connection;

pub const c2s = opaque {
    pub const WriteBuffer = @import("c2s/WriteBuffer.zig");

    pub const handshake = opaque {
        pub const Handshake = @import("c2s/handshake/Handshake.zig");

        pub const Packet = union(enum) {
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

            Handshake: Handshake,
        };
    };
    pub const login = opaque {
        pub const Hello = @import("c2s/login/Hello.zig");
        pub const Key = @import("c2s/login/Key.zig");

        pub const Packet = union(enum) {
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

            Hello: Hello,
            Key: Key,
        };
    };
    pub const play = opaque {
        pub const KeepAlive = @import("c2s/play/KeepAlive.zig");
        pub const ChatMessage = @import("c2s/play/ChatMessage.zig");
        pub const PlayerInteractEntity = @import("c2s/play/PlayerInteractEntity.zig");
        pub const PlayerMove = @import("c2s/play/PlayerMove.zig");
        pub const PlayerMovePosition = @import("c2s/play/PlayerMove.zig").Position;
        pub const PlayerMoveAngles = @import("c2s/play/PlayerMove.zig").Angles;
        pub const PlayerMovePositionAndAngles = @import("c2s/play/PlayerMove.zig").PositionAndAngles;
        pub const PlayerHandAction = @import("c2s/play/PlayerHandAction.zig");
        pub const PlayerUse = @import("c2s/play/PlayerUse.zig");
        pub const SelectSlot = @import("c2s/play/SelectSlot.zig");
        pub const HandSwing = @import("c2s/play/HandSwing.zig");
        pub const PlayerMovementAction = @import("c2s/play/PlayerMovementAction.zig");
        pub const PlayerInput = @import("c2s/play/PlayerInput.zig");
        pub const CloseMenu = @import("c2s/play/CloseMenu.zig");
        pub const MenuClickSlot = @import("c2s/play/MenuClickSlot.zig");
        pub const ConfirmMenuAction = @import("c2s/play/ConfirmMenuAction.zig");
        pub const CreativeMenuSlot = @import("c2s/play/CreativeMenuSlot.zig");
        pub const MenuClickButton = @import("c2s/play/MenuClickButton.zig");
        pub const SignUpdate = @import("c2s/play/SignUpdate.zig");
        pub const PlayerAbilities = @import("c2s/play/PlayerAbilities.zig");
        pub const CommandSuggestions = @import("c2s/play/CommandSuggestions.zig");
        pub const ClientSettings = @import("c2s/play/ClientSettings.zig");
        pub const ClientStatus = @import("c2s/play/ClientStatus.zig");
        pub const CustomPayload = @import("c2s/play/CustomPayload.zig");
        pub const PlayerSpectate = @import("c2s/play/PlayerSpectate.zig");
        pub const ResourcePack = @import("c2s/play/ResourcePack.zig");

        pub const Packet = union(enum) {
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

            KeepAlive: KeepAlive,
            ChatMessage: ChatMessage,
            PlayerInteractEntity: PlayerInteractEntity,
            PlayerMove: PlayerMove,
            PlayerMovePosition: PlayerMovePosition,
            PlayerMoveAngles: PlayerMoveAngles,
            PlayerMovePositionAndAngles: PlayerMovePositionAndAngles,
            PlayerHandAction: PlayerHandAction,
            PlayerUse: PlayerUse,
            SelectSlot: SelectSlot,
            HandSwing: HandSwing,
            PlayerMovementAction: PlayerMovementAction,
            PlayerInput: PlayerInput,
            CloseMenu: CloseMenu,
            MenuClickSlot: MenuClickSlot,
            ConfirmMenuAction: ConfirmMenuAction,
            CreativeMenuSlot: CreativeMenuSlot,
            MenuClickButton: MenuClickButton,
            SignUpdate: SignUpdate,
            PlayerAbilities: PlayerAbilities,
            CommandSuggestions: CommandSuggestions,
            ClientSettings: ClientSettings,
            ClientStatus: ClientStatus,
            CustomPayload: CustomPayload,
            PlayerSpectate: PlayerSpectate,
            ResourcePack: ResourcePack,
        };
    };
    pub const status = opaque {
        pub const Ping = @import("c2s/status/Ping.zig");
        pub const ServerStatus = @import("c2s/status/ServerStatus.zig");
    };

    pub const Packet = union(enum) {
        Handshake: handshake.Packet,
        Login: login.Packet,
        Play: play.Packet,
    };
};

pub const s2c = opaque {
    pub const ReadBuffer = @import("s2c/ReadBuffer.zig");

    pub const login = opaque {
        pub const CompressionThreshold = @import("s2c/login/CompressionThreshold.zig");
        pub const Hello = @import("s2c/login/Hello.zig");
        pub const LoginFail = @import("s2c/login/LoginFail.zig");
        pub const LoginSuccess = @import("s2c/login/LoginSuccess.zig");

        pub const Packet = union(enum) {
            /// decodes a packet buffer into a type-erased packet
            pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
                // the amount of packet types in this union
                const PacketTypeCount = @typeInfo(@This()).@"union".fields.len;

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
                return @typeInfo(@This()).@"union".fields[opcode].name;
            }
            pub fn typeFromOpcode(comptime opcode: i32) type {
                return @typeInfo(@This()).@"union".fields[opcode].type;
            }

            LoginFail: LoginFail,
            Hello: Hello,
            LoginSuccess: LoginSuccess,
            CompressionThreshold: CompressionThreshold,
        };
    };
    pub const play = opaque {
        pub const KeepAlive = @import("s2c/play/KeepAlive.zig");
        pub const Login = @import("s2c/play/Login.zig");
        pub const ChatMessage = @import("s2c/play/ChatMessage.zig");
        pub const WorldTime = @import("s2c/play/WorldTime.zig");
        pub const EntityEquipment = @import("s2c/play/EntityEquipment.zig");
        pub const SpawnPoint = @import("s2c/play/SpawnPoint.zig");
        pub const PlayerHealth = @import("s2c/play/PlayerHealth.zig");
        pub const PlayerRespawn = @import("s2c/play/PlayerRespawn.zig");
        pub const PlayerMove = @import("s2c/play/PlayerMove.zig");
        pub const SelectSlot = @import("s2c/play/SelectSlot.zig");
        pub const PlayerSleep = @import("s2c/play/PlayerSleep.zig");
        pub const EntityAnimation = @import("s2c/play/EntityAnimation.zig");
        pub const AddPlayer = @import("s2c/play/AddPlayer.zig");
        pub const EntityPickup = @import("s2c/play/EntityPickup.zig");
        pub const AddEntity = @import("s2c/play/AddEntity.zig");
        pub const AddMob = @import("s2c/play/AddMob.zig");
        pub const AddPainting = @import("s2c/play/AddPainting.zig");
        pub const AddXpOrb = @import("s2c/play/AddXpOrb.zig");
        pub const EntityVelocity = @import("s2c/play/EntityVelocity.zig");
        pub const RemoveEntities = @import("s2c/play/RemoveEntities.zig");
        pub const EntityMove = @import("s2c/play/EntityMove.zig");
        pub const EntityMovePosition = @import("s2c/play/EntityMove.zig").Position;
        pub const EntityMoveAngles = @import("s2c/play/EntityMove.zig").Angles;
        pub const EntityMovePositionAndAngles = @import("s2c/play/EntityMove.zig").PositionAndAngles;
        pub const EntityTeleport = @import("s2c/play/EntityTeleport.zig");
        pub const EntityHeadAngles = @import("s2c/play/EntityHeadAngles.zig");
        pub const EntityEvent = @import("s2c/play/EntityEvent.zig");
        pub const EntityAttach = @import("s2c/play/EntityAttach.zig");
        pub const EntityData = @import("s2c/play/EntityData.zig");
        pub const EntityStatusEffect = @import("s2c/play/EntityStatusEffect.zig");
        pub const EntityRemoveStatusEffect = @import("s2c/play/EntityRemoveStatusEffect.zig");
        pub const PlayerXp = @import("s2c/play/PlayerXp.zig");
        pub const EntityAttributes = @import("s2c/play/EntityAttributes.zig");
        pub const WorldChunk = @import("s2c/play/WorldChunk.zig");
        pub const BlocksUpdate = @import("s2c/play/BlocksUpdate.zig");
        pub const BlockUpdate = @import("s2c/play/BlockUpdate.zig");
        pub const BlockEvent = @import("s2c/play/BlockEvent.zig");
        pub const BlockMiningProgress = @import("s2c/play/BlockMiningProgress.zig");
        pub const WorldChunks = @import("s2c/play/WorldChunks.zig");
        pub const Explosion = @import("s2c/play/Explosion.zig");
        pub const WorldEvent = @import("s2c/play/WorldEvent.zig");
        pub const SoundEvent = @import("s2c/play/SoundEvent.zig");
        pub const Particle = @import("s2c/play/Particle.zig");
        pub const GameEvent = @import("s2c/play/GameEvent.zig");
        pub const AddGlobalEntity = @import("s2c/play/AddGlobalEntity.zig");
        pub const OpenMenu = @import("s2c/play/OpenMenu.zig");
        pub const CloseMenu = @import("s2c/play/CloseMenu.zig");
        pub const MenuSlotUpdate = @import("s2c/play/MenuSlotUpdate.zig");
        pub const InventoryMenu = @import("s2c/play/InventoryMenu.zig");
        pub const MenuData = @import("s2c/play/MenuData.zig");
        pub const ConfirmMenuAction = @import("s2c/play/ConfirmMenuAction.zig");
        pub const SignUpdate = @import("s2c/play/SignUpdate.zig");
        pub const MapData = @import("s2c/play/MapData.zig");
        pub const BlockEntityUpdate = @import("s2c/play/BlockEntityUpdate.zig");
        pub const OpenSignEditor = @import("s2c/play/OpenSignEditor.zig");
        pub const Statistics = @import("s2c/play/Statistics.zig");
        pub const PlayerInfo = @import("s2c/play/PlayerInfo.zig");
        pub const PlayerAbilities = @import("s2c/play/PlayerAbilities.zig");
        pub const CommandSuggestions = @import("s2c/play/CommandSuggestions.zig");
        pub const ScoreboardObjective = @import("s2c/play/ScoreboardObjective.zig");
        pub const ScoreboardScore = @import("s2c/play/ScoreboardScore.zig");
        pub const ScoreboardDisplay = @import("s2c/play/ScoreboardDisplay.zig");
        pub const Team = @import("s2c/play/Team.zig");
        pub const CustomPayload = @import("s2c/play/CustomPayload.zig");
        pub const Disconnect = @import("s2c/play/Disconnect.zig");
        pub const Difficulty = @import("s2c/play/Difficulty.zig");
        pub const PlayerCombat = @import("s2c/play/PlayerCombat.zig");
        pub const Camera = @import("s2c/play/Camera.zig");
        pub const WorldBorder = @import("s2c/play/WorldBorder.zig");
        pub const Titles = @import("s2c/play/Titles.zig");
        pub const CompressionThreshold = @import("s2c/play/CompressionThreshold.zig");
        pub const TabList = @import("s2c/play/TabList.zig");
        pub const ResourcePack = @import("s2c/play/ResourcePack.zig");
        pub const EntitySync = @import("s2c/play/EntitySync.zig");

        pub const Packet = union(enum) {
            /// decodes a packet buffer into a type-erased packet
            pub fn decode(buffer: *s2c.ReadBuffer, allocator: std.mem.Allocator) !@This() {
                // the amount of packet types in this union
                const PacketTypeCount = @typeInfo(@This()).@"union".fields.len;

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
                return @typeInfo(@This()).@"union".fields[opcode].name;
            }
            pub fn typeFromOpcode(comptime opcode: i32) type {
                return @typeInfo(@This()).@"union".fields[opcode].type;
            }

            KeepAlive: KeepAlive,
            Login: Login,
            ChatMessage: ChatMessage,
            WorldTime: WorldTime,
            EntityEquipment: EntityEquipment,
            SpawnPoint: SpawnPoint,
            PlayerHealth: PlayerHealth,
            PlayerRespawn: PlayerRespawn,
            PlayerMove: PlayerMove,
            SelectSlot: SelectSlot,
            PlayerSleep: PlayerSleep,
            EntityAnimation: EntityAnimation,
            AddPlayer: AddPlayer,
            EntityPickup: EntityPickup,
            AddEntity: AddEntity,
            AddMob: AddMob,
            AddPainting: AddPainting,
            AddXpOrb: AddXpOrb,
            EntityVelocity: EntityVelocity,
            RemoveEntities: RemoveEntities,
            EntityMove: EntityMove,
            EntityMovePosition: EntityMovePosition,
            EntityMoveAngles: EntityMoveAngles,
            EntityMovePositionAngles: EntityMovePositionAndAngles,
            EntityTeleport: EntityTeleport,
            EntityHeadAngles: EntityHeadAngles,
            EntityEvent: EntityEvent,
            EntityAttach: EntityAttach,
            EntityData: EntityData,
            EntityStatusEffect: EntityStatusEffect,
            EntityRemoveStatusEffect: EntityRemoveStatusEffect,
            PlayerXp: PlayerXp,
            EntityAttributes: EntityAttributes,
            WorldChunk: WorldChunk,
            BlocksUpdate: BlocksUpdate,
            BlockUpdate: BlockUpdate,
            BlockEvent: BlockEvent,
            BlockMiningProgress: BlockMiningProgress,
            WorldChunks: WorldChunks,
            Explosion: Explosion,
            WorldEvent: WorldEvent,
            SoundEvent: SoundEvent,
            Particle: Particle,
            GameEvent: GameEvent,
            AddGlobalEntity: AddGlobalEntity,
            OpenMenu: OpenMenu,
            CloseMenu: CloseMenu,
            MenuSlotUpdate: MenuSlotUpdate,
            InventoryMenu: InventoryMenu,
            MenuData: MenuData,
            ConfirmMenuAction: ConfirmMenuAction,
            SignUpdate: SignUpdate,
            MapData: MapData,
            BlockEntityUpdate: BlockEntityUpdate,
            OpenSignEditor: OpenSignEditor,
            Statistics: Statistics,
            PlayerInfo: PlayerInfo,
            PlayerAbilities: PlayerAbilities,
            CommandSuggestions: CommandSuggestions,
            ScoreboardObjective: ScoreboardObjective,
            ScoreboardScore: ScoreboardScore,
            ScoreboardDisplay: ScoreboardDisplay,
            Team: Team,
            CustomPayload: CustomPayload,
            Disconnect: Disconnect,
            Difficulty: Difficulty,
            PlayerCombat: PlayerCombat,
            Camera: Camera,
            WorldBorder: WorldBorder,
            Titles: Titles,
            CompressionThreshold: CompressionThreshold,
            TabList: TabList,
            ResourcePack: ResourcePack,
            EntitySync: EntitySync,
        };
    };
    pub const status = opaque {
        pub const Ping = @import("s2c/status/Ping.zig");
        pub const ServerStatus = @import("s2c/status/ServerStatus.zig");
    };

    pub const Packet = union(enum) {
        // only the client ever sends packets in the handshake protocol
        Login: login.Packet,
        Play: play.Packet,

        pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
            switch (self.*) {
                .Login => |*login_packet| try login_packet.handleOnMainThread(game, allocator),
                .Play => |*play_packet| try play_packet.handleOnMainThread(game, allocator),
            }
        }
    };
};
