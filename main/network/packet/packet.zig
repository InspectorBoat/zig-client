pub const C2S = union(enum) {
    login: Login,
    play: Play,

    pub const Handshake = union(enum) {
        handshake: C2S.Handshake.Handshake,

        pub const write = Mixin(@This()).write;

        pub const Handshake = @import("c2s/handshake/Handshake.zig");
    };
    pub const Login = union(enum) {
        hello: Hello,
        key: Key,

        pub const write = Mixin(@This()).write;

        pub const Hello = @import("c2s/login/Hello.zig");
        pub const Key = @import("c2s/login/Key.zig");
    };
    pub const Play = union(enum) {
        player_move: PlayerMove,
        player_move_position: PlayerMove.Position,
        player_move_angles: PlayerMove.Angles,
        player_move_position_and_angles: PlayerMove.PositionAndAngles,
        player_hand_action: PlayerHandAction,
        player_use: PlayerUse,
        hand_swing: HandSwing,
        player_movement_action: PlayerMovementAction,
        confirm_menu_action: ConfirmMenuAction,
        menu_click_button: MenuClickButton,
        player_abilities: PlayerAbilities,
        client_settings: ClientSettings,
        client_status: struct {
            status: enum(i32) {
                a = 0,
                b = 1,
                c = 2,
            },
        },
        custom_payload: CustomPayload,
        player_spectate: PlayerSpectate,
        resource_pack: ResourcePack,

        pub const write = Mixin(@This()).write;

        pub const KeepAlive = @import("c2s/play/KeepAlive.zig");
        pub const ChatMessage = @import("c2s/play/ChatMessage.zig");
        pub const PlayerInteractEntity = @import("c2s/play/PlayerInteractEntity.zig");
        pub const PlayerMove = @import("c2s/play/PlayerMove.zig");
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
    };
    pub const Status = union(enum) {
        ping: Ping,
        server_status: ServerStatus,

        pub const write = Mixin(@This());

        pub const Ping = @import("c2s/status/Ping.zig");
        pub const ServerStatus = @import("c2s/status/ServerStatus.zig");
    };

    pub const WriteBuffer = @import("c2s/WriteBuffer.zig");

    pub const WritePacketError = error{ OutOfMemory, IllegalPacket };
    pub fn Mixin(comptime PacketMixin: type) type {
        return struct {
            pub noinline fn write(packet: PacketMixin, buffer: *C2S.WriteBuffer) WritePacketError!void {
                try buffer.writeVarInt(@backingInt(packet));
                switch (packet) {
                    inline else => |specific_packet| {
                        specific_packet.write(buffer) catch |e| {
                            return if (e == error.OutOfMemory)
                                error.OutOfMemory
                            else
                                error.IllegalPacket;
                        };
                    },
                }
            }
        };
    }
};

pub const S2C = union(enum) {
    login: Login,
    play: Play,

    pub const Login = union(enum) {
        login_fail: LoginFail,
        hello: Hello,
        login_success: LoginSuccess,
        compression_threshold: CompressionThreshold,

        pub const read = Mixin(@This()).read;

        pub const CompressionThreshold = @import("s2c/login/CompressionThreshold.zig");
        pub const Hello = @import("s2c/login/Hello.zig");
        pub const LoginFail = @import("s2c/login/LoginFail.zig");
        pub const LoginSuccess = @import("s2c/login/LoginSuccess.zig");
    };
    pub const Play = union(enum) {
        login: S2C.Play.Login,
        player_respawn: PlayerRespawn,
        player_move: PlayerMove,
        add_entity: AddEntity,
        entity_velocity: EntityVelocity,
        remove_entities: RemoveEntities,
        entity_move_angles: EntityMove.Angles,
        entity_move_position_angles: EntityMove.PositionAndAngles,
        entity_teleport: EntityTeleport,
        world_chunk: WorldChunk,

        pub const read = Mixin(@This()).read;
        pub const Login = @import("s2c/play/Login.zig");
        pub const PlayerRespawn = @import("s2c/play/PlayerRespawn.zig");
        pub const PlayerMove = @import("s2c/play/PlayerMove.zig");
        pub const AddEntity = @import("s2c/play/AddEntity.zig");
        pub const EntityVelocity = @import("s2c/play/EntityVelocity.zig");
        pub const RemoveEntities = @import("s2c/play/RemoveEntities.zig");
        pub const EntityMove = @import("s2c/play/EntityMove.zig");
        pub const EntityTeleport = @import("s2c/play/EntityTeleport.zig");
        pub const WorldChunk = @import("s2c/play/WorldChunk.zig");
    };
    pub const Status = union(enum) {
        ping: Ping,
        server_status: ServerStatus,

        pub const read = Mixin(@This()).read;

        pub const Ping = @import("s2c/status/Ping.zig");
        pub const ServerStatus = @import("s2c/status/ServerStatus.zig");
    };

    pub const ReadBuffer = @import("s2c/ReadBuffer.zig");

    pub const ReadPacketError = error{ InvalidOpcode, MalformedPacket, OutOfMemory };
    pub fn Mixin(comptime PacketMixin: type) type {
        return struct {
            pub noinline fn read(allocator: std.mem.Allocator, buffer: *S2C.ReadBuffer) ReadPacketError!PacketMixin {
                const packet_type_info = @typeInfo(PacketMixin).@"union";
                switch (buffer.readVarInt() catch return error.MalformedPacket) {
                    inline 0...packet_type_info.field_names.len - 1 => |opcode| {
                        return @unionInit(
                            PacketMixin,
                            packet_type_info.field_names[opcode],
                            packet_type_info.field_types[opcode].decode(allocator, buffer) catch return error.MalformedPacket,
                        );
                    },
                    else => unreachable,
                }
            }
        };
    }
};

const std = @import("std");
