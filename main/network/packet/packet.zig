const std = @import("std");
const root = @import("root");
const Game = root.Game;
const Connection = root.network.Connection;

pub const C2S = union(enum) {
    pub const WriteBuffer = @import("c2s/WriteBuffer.zig");

    pub const Handshake = union(enum) {
        pub const Handshake = @import("c2s/handshake/Handshake.zig");

        /// writes a type-erased packet
        pub const write = Mixin(@This()).write;

        handshake: @import("c2s/handshake/Handshake.zig"),
    };
    pub const Login = union(enum) {
        pub const Hello = @import("c2s/login/Hello.zig");
        pub const Key = @import("c2s/login/Key.zig");

        /// writes a type-erased packet
        pub const write = Mixin(@This()).write;

        hello: Hello,
        key: Key,
    };
    pub const Play = union(enum) {
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

        /// writes a type-erased packet
        pub const write = Mixin(@This()).write;

        keep_alive: KeepAlive,
        chat_message: ChatMessage,
        player_interact_entity: PlayerInteractEntity,
        player_move: PlayerMove,
        player_move_position: PlayerMovePosition,
        player_move_angles: PlayerMoveAngles,
        player_move_position_and_angles: PlayerMovePositionAndAngles,
        player_hand_action: PlayerHandAction,
        player_use: PlayerUse,
        select_slot: SelectSlot,
        hand_swing: HandSwing,
        player_movement_action: PlayerMovementAction,
        player_input: PlayerInput,
        close_menu: CloseMenu,
        menu_click_slot: MenuClickSlot,
        confirm_menu_action: ConfirmMenuAction,
        creative_menu_slot: CreativeMenuSlot,
        menu_click_button: MenuClickButton,
        sign_update: SignUpdate,
        player_abilities: PlayerAbilities,
        command_suggestions: CommandSuggestions,
        client_settings: ClientSettings,
        client_status: ClientStatus,
        custom_payload: CustomPayload,
        player_spectate: PlayerSpectate,
        resource_pack: ResourcePack,
    };
    pub const Status = union(enum) {
        pub const Ping = @import("c2s/status/Ping.zig");
        pub const ServerStatus = @import("c2s/status/ServerStatus.zig");

        /// writes a type-erased packet
        pub const write = Mixin(@This());

        ping: Ping,
        server_status: ServerStatus,
    };

    handshake: Handshake,
    login: Login,
    play: Play,

    pub fn Mixin(comptime PacketMixin: type) type {
        return struct {
            pub fn write(packet: PacketMixin, buffer: *C2S.WriteBuffer) !void {
                try buffer.writeVarInt(@intFromEnum(packet));
                switch (packet) {
                    // specific packet type must be comptime known, thus inline else is necessary
                    inline else => |specific_packet| {
                        try specific_packet.write(buffer);
                    },
                }
            }
        };
    }
};

pub const S2C = union(enum) {
    pub const ReadBuffer = @import("s2c/ReadBuffer.zig");

    pub const Login = union(enum) {
        pub const CompressionThreshold = @import("s2c/login/CompressionThreshold.zig");
        pub const Hello = @import("s2c/login/Hello.zig");
        pub const LoginFail = @import("s2c/login/LoginFail.zig");
        pub const LoginSuccess = @import("s2c/login/LoginSuccess.zig");

        /// decodes a packet buffer into a type-erased packet
        pub const decode = Mixin(@This()).decode;
        /// handles a type-erased packet
        pub const handleOnMainThread = Mixin(@This()).handleOnMainThread;
        pub const handleOnNetworkThread = Mixin(@This()).handleOnNetworkThread;

        login_fail: LoginFail,
        hello: Hello,
        login_success: LoginSuccess,
        compression_threshold: CompressionThreshold,
    };
    pub const Play = union(enum) {
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

        /// decodes a packet buffer into a type-erased packet
        pub const decode = Mixin(@This()).decode;
        /// handles a type-erased packet
        pub const handleOnMainThread = Mixin(@This()).handleOnMainThread;
        // Of these, only CompressionThreshold, Keepalive, and Disconnect really need to be handled on the network thread
        // .CompressionThreshold, .TabList, .KeepAlive, .ResourcePack, .Disconnect,
        pub const handleOnNetworkThread = Mixin(@This()).handleOnNetworkThread;

        keep_alive: KeepAlive,
        login: @import("s2c/play/Login.zig"),
        chat_message: ChatMessage,
        world_time: WorldTime,
        entity_equipment: EntityEquipment,
        spawn_point: SpawnPoint,
        player_health: PlayerHealth,
        player_respawn: PlayerRespawn,
        player_move: PlayerMove,
        select_slot: SelectSlot,
        player_sleep: PlayerSleep,
        entity_animation: EntityAnimation,
        add_player: AddPlayer,
        entity_pickup: EntityPickup,
        add_entity: AddEntity,
        add_mob: AddMob,
        add_painting: AddPainting,
        add_xp_orb: AddXpOrb,
        entity_velocity: EntityVelocity,
        remove_entities: RemoveEntities,
        entity_move: EntityMove,
        entity_move_position: EntityMovePosition,
        entity_move_angles: EntityMoveAngles,
        entity_move_position_angles: EntityMovePositionAndAngles,
        entity_teleport: EntityTeleport,
        entity_head_angles: EntityHeadAngles,
        entity_event: EntityEvent,
        entity_attach: EntityAttach,
        entity_data: EntityData,
        entity_status_effect: EntityStatusEffect,
        entity_remove_status_effect: EntityRemoveStatusEffect,
        player_xp: PlayerXp,
        entity_attributes: EntityAttributes,
        world_chunk: WorldChunk,
        blocks_update: BlocksUpdate,
        block_update: BlockUpdate,
        block_event: BlockEvent,
        block_mining_progress: BlockMiningProgress,
        world_chunks: WorldChunks,
        explosion: Explosion,
        world_event: WorldEvent,
        sound_event: SoundEvent,
        particle: Particle,
        game_event: GameEvent,
        add_global_entity: AddGlobalEntity,
        open_menu: OpenMenu,
        close_menu: CloseMenu,
        menu_slot_update: MenuSlotUpdate,
        inventory_menu: InventoryMenu,
        menu_data: MenuData,
        confirm_menu_action: ConfirmMenuAction,
        sign_update: SignUpdate,
        map_data: MapData,
        block_entity_update: BlockEntityUpdate,
        open_sign_editor: OpenSignEditor,
        statistics: Statistics,
        player_info: PlayerInfo,
        player_abilities: PlayerAbilities,
        command_suggestions: CommandSuggestions,
        scoreboard_objective: ScoreboardObjective,
        scoreboard_score: ScoreboardScore,
        scoreboard_display: ScoreboardDisplay,
        team: Team,
        custom_payload: CustomPayload,
        disconnect: Disconnect,
        difficulty: Difficulty,
        player_combat: PlayerCombat,
        camera: Camera,
        world_border: WorldBorder,
        titles: Titles,
        compression_threshold: CompressionThreshold,
        tab_list: TabList,
        resource_pack: ResourcePack,
        entity_sync: EntitySync,
    };
    pub const Status = union(enum) {
        pub const Ping = @import("s2c/status/Ping.zig");
        pub const ServerStatus = @import("s2c/status/ServerStatus.zig");

        /// decodes a packet buffer into a type-erased packet
        pub const decode = Mixin(@This()).decode;
        /// handles a type-erased packet
        pub const handleOnMainThread = Mixin(@This()).handleOnMainThread;
        pub const handleOnNetworkThread = Mixin(@This()).handleOnNetworkThread;

        ping: Ping,
        server_status: ServerStatus,
    };

    // only the client ever sends packets in the handshake protocol
    login: Login,
    play: Play,

    pub fn handleOnMainThread(self: *@This(), game: *Game, allocator: std.mem.Allocator) !void {
        switch (self.*) {
            .login => |*login_packet| try login_packet.handleOnMainThread(game, allocator),
            .play => |*play_packet| try play_packet.handleOnMainThread(game, allocator),
        }
    }

    pub fn Mixin(comptime PacketMixin: type) type {
        return struct {
            pub fn decode(buffer: *S2C.ReadBuffer, allocator: std.mem.Allocator) !PacketMixin {
                // the amount of packet types in this union
                const PacketTypeCount = @typeInfo(PacketMixin).@"union".fields.len;

                // read the opcode of the packet from the buffer
                switch (try buffer.readVarInt()) {
                    // opcode must be comptime known, thus inline is necessary
                    inline 0...PacketTypeCount - 1 => |opcode| {
                        // the packet type corresponding to the opcode
                        const PacketType = typeFromOpcode(opcode);
                        // the field name of the packet type corresponding to the opcode
                        const PacketName = comptime nameFromOpcode(opcode);
                        return @unionInit(
                            PacketMixin,
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
            pub fn handleOnMainThread(packet: *PacketMixin, game: *Game, allocator: std.mem.Allocator) !void {
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
            pub fn handleOnNetworkThread(packet: *PacketMixin, server_connection: *Connection) !void {
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
                return @typeInfo(PacketMixin).@"union".fields[opcode].name;
            }
            pub fn typeFromOpcode(comptime opcode: i32) type {
                return @typeInfo(PacketMixin).@"union".fields[opcode].type;
            }
        };
    }
};
