pub const VarIntByte = packed struct(u8) {
    /// The data bits of the VarInt
    data: u7 = 0,
    /// Whether more bytes exist in this VarInt
    cont: bool = false,
};
