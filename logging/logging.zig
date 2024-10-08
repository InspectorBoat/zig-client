const std = @import("std");

pub fn LogType(comptime enabled: bool, comptime fmt: []const u8) fn (args: anytype) void {
    return struct {
        pub fn closure(args: anytype) void {
            if (enabled) std.debug.print(fmt ++ "\n", args);
        }
    }.closure;
}

pub const DEBUG_RING_ALLOCATOR = false;
pub const ring_buffer_oom_wait = LogType(DEBUG_RING_ALLOCATOR, "ring buffer ran out of memory, waiting");
pub const ring_buffer_oom = LogType(DEBUG_RING_ALLOCATOR, "failed {} byte allocation from ring allocator, used {} bytes");
pub const ring_buffer_allocate = LogType(DEBUG_RING_ALLOCATOR, "allocated {} bytes from ring allocator");
pub const ring_buffer_free = LogType(DEBUG_RING_ALLOCATOR, "freed {} bytes from ring allocator");
pub const stop_network_thread = LogType(true, "stopping network thread");
pub const invalid_opcode = LogType(true, "invalid opcode {}");
pub const switch_protocol = LogType(false, "switching protocol to {}");
pub const warn_unused_buffer_bytes = LogType(false, "{} unused bytes in buffer");
pub const decode_packet = LogType(false, "decoding packet - {} bytes header + {} bytes body");
pub const handle_packet = LogType(false, "handling packet - {s}");
pub const recieve_teleport_packet = LogType(false, "teleported to pos: {} | rot: {} | rel: {}");
pub const transaction = LogType(false, "transaction - {}");
pub const free_section = LogType(false, "freeing section");
pub const free_chunk = LogType(false, "freeing chunk at {}");
pub const update_chunk = LogType(false, "updating chunk at {}");
pub const devirtualize_chunk = LogType(false, "chunk devirtualized in {} ms");
pub const lag_spike = LogType(false, "lag spike - ticking {} times at once");
pub const delayed_tick = LogType(false, "late tick - {d} ms behind");
pub const tick_on_time = LogType(false, "ticked on time");
pub const disconnect = LogType(true, "main thread terminating connection");
pub const total_tick_delay = LogType(false, "total delay: {d} ms");
pub const display_average_tick_ms = LogType(true, "average ms/tick: {d} ms");
pub const decompression_time = LogType(false, "took {d} ms to decompress {} bytes from {} bytes");
pub const add_entity = LogType(false, "added entity {} at {}");
pub const remove_entity = LogType(false, "removed entity {}");
pub const remove_entity_missing = LogType(false, "tried to remove missing entity with network id {}");
pub const entity_move = LogType(false, "entity {} moved to {}");
pub const entity_rotate = LogType(false, "entity {} rotated to {}");

pub const player_start_sprint = LogType(false, "begin sprinting");
pub const player_stop_sprint = LogType(false, "stop sprinting");

pub const set_block_in_missing_chunk = LogType(false, "attempted to set block in missing chunk {}!");

pub const recieved_chunk = LogType(false, "decoded recieved chunk in {d} ms");
pub const load_new_chunk = LogType(false, "loaded new chunk at {}");
pub const unload_chunk = LogType(false, "unloaded chunk at {}");

pub const reload_shader = LogType(true, "reloading shaders");
