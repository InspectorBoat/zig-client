pub const Event = union(u32) {
    Frame: f64,
    Tick: void,
    ChunkUpdate: void,
};
