language: []const u8,
view_distance: i8,
chat_visibility: ChatVisibility,
chat_colors: bool,
skin_layers: packed struct(u8) {
    cape: bool = true,
    jacket: bool = true,
    left_sleeve: bool = true,
    right_sleeve: bool = true,
    left_pants_leg: bool = true,
    right_pants_leg: bool = true,
    hat: bool = true,
    _: u1 = 0,
},

const main = @import("main");

const ChatVisibility = @import("../../../../chat/chatvisibility.zig").ChatVisibility;

const C2S = main.network.packet.C2S;
