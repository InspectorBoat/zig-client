pub const VarIntByte = packed struct {
    /// The data bits of the VarInt
    data_bits: u7 = 0,
    /// Whether more bytes exist in this VarInt
    has_more_bytes: bool = false,
};
