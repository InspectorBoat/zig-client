const std = @import("std");

const network_lib = @import("network");
const root = @import("root");
const network = root.network;
const C2S = network.packet.C2S;
const S2C = network.packet.S2C;
const Protocol = network.Protocol;
const Client = root.Client;
const RingBuffer = @import("util").RingBuffer;

pub const Connection = struct {
    /// The network thread does not own this memory
    name: []const u8,
    port: u16,

    /// Either thread can set this to true.
    /// Main thread polls to know when to disconnect,
    /// then calls connection_handle.disconnect to notify network thread
    disconnected: *std.atomic.Value(bool),

    socket: network_lib.Socket,

    protocol: Protocol = .Login,

    compression_threshold: i32 = -1,

    /// The main thread submits to this queue, network thread encodes and sends them
    /// The main thread should periodically poll and free already sent packets using c2s_packet_allocator
    c2s_packet_queue: *WriteReadFreeQueue(C2S),
    /// The network thread decodes packets and submits them to this queue, main thread reads and handles them
    /// The network thread should periodically poll and free already handled packets using s2c_packet_allocator
    s2c_packet_queue: *WriteReadFreeQueue(S2CWrapper),

    /// A buffer of raw bytes read from the socket but not yet decoded
    queued_bytes: @import("llm-code-quarantine").FixedFifo(u8, 1024 * 1024),
    /// This ring allocator should be used to allocate memory for s2c packets and *nothing else*
    s2c_packet_ring_alloc: RingBuffer,

    pub fn networkThreadImpl(
        name: []const u8,
        port: u16,
        disconnect_ptr: *std.atomic.Value(bool),
        c2s_packet_queue: *WriteReadFreeQueue(C2S),
        s2c_packet_queue: *WriteReadFreeQueue(S2CWrapper),
    ) !void {
        var ring_alloc_buffer: [1024 * 1024 * 8]u8 = undefined;
        var connection: Connection = .{
            .name = name,
            .port = port,

            .disconnected = disconnect_ptr,

            .socket = connectSocket(name, port) catch {
                disconnect_ptr.store(true, .release);
                return;
            },

            .c2s_packet_queue = c2s_packet_queue,
            .s2c_packet_queue = s2c_packet_queue,

            .queued_bytes = .init(),

            .s2c_packet_ring_alloc = .{ .buffer = &ring_alloc_buffer },
        };

        while (true) {
            connection.tick() catch {
                connection.disconnected.store(true, .release);
            };
            if (connection.disconnected.load(.acquire)) {
                connection.socket.close();
                @import("log").stop_network_thread(.{});
                return;
            }
        }
    }

    pub fn tick(self: *@This()) !void {
        // read from socket
        try self.readIncomingBytes();

        // decode and dispatch
        while (true) {
            // keep track of whether we actually allocated any bytes
            const initial_alloc_index = self.s2c_packet_ring_alloc.logical_alloc_index;
            const maybe_packet = try self.decodeQueuedBytes();
            if (self.disconnected.load(.acquire)) return;
            if (maybe_packet) |packet| {
                try self.dispatchS2CPacket(packet, initial_alloc_index);
                if (self.disconnected.load(.acquire)) return;
            } else break;
        }

        // free handled s2c packets
        try self.freeS2CPackets();

        // encode and send
        try self.sendC2SPackets();
    }

    pub fn freeS2CPackets(self: *@This()) !void {
        while (self.s2c_packet_queue.reclaim()) |s2c_packet_wrapper| {
            // only free if packet actually allocated any memory
            if (s2c_packet_wrapper.alloc_index) |alloc_index| {
                try self.s2c_packet_ring_alloc.freeFromTail(alloc_index);
            }
        }
    }

    pub fn sendC2SPackets(self: *@This()) !void {
        while (self.c2s_packet_queue.claim()) |packet| {
            defer self.c2s_packet_queue.release();
            try self.sendPacket(packet);
        }
    }

    pub fn dispatchS2CPacket(self: *@This(), packet: S2C, initial_alloc_index: usize) !void {
        var packet_mut = packet;
        switch (packet_mut) {
            inline else => |*specific_protocol| {
                switch (specific_protocol.*) {
                    inline else => |*specific_packet| {
                        @import("log").handle_packet(.{@tagName(std.meta.activeTag(specific_protocol.*))});
                        if (specific_packet.handle_on_network_thread) {
                            try specific_packet.handleOnNetworkThread(self);
                            // free immediately
                            if (self.s2c_packet_ring_alloc.logical_alloc_index != initial_alloc_index) {
                                try self.s2c_packet_ring_alloc.undoAllocations(initial_alloc_index);
                            }
                        } else {
                            // if packet didn't allocate, pass null allocation so we know not to free
                            const alloc_index = if (self.s2c_packet_ring_alloc.logical_alloc_index != initial_alloc_index)
                                self.s2c_packet_ring_alloc.logical_alloc_index
                            else
                                null;
                            try self.s2c_packet_queue.write(.{ .packet = packet.play, .alloc_index = alloc_index });
                        }
                    },
                }
            },
        }
    }

    pub fn connectSocket(name: []const u8, port: u16) !network_lib.Socket {
        var buffer: [8192]u8 = undefined;
        var fba_impl: std.heap.FixedBufferAllocator = .init(&buffer);

        const socket = try network_lib.connectToHost(fba_impl.allocator(), name, port, .tcp);
        errdefer socket.close();

        try makeSocketNonBlocking(socket);

        return socket;
    }

    /// https://stackoverflow.com/a/1549344/20084105
    pub fn makeSocketNonBlocking(socket: network_lib.Socket) !void {
        if (@import("builtin").os.tag == .windows) {
            const mode: u32 = 1;
            if (try std.os.windows.WSAIoctl(
                socket.internal,
                @bitCast(@as(i32, std.os.windows.ws2_32.FIONBIO)),
                std.mem.asBytes(&mode),
                undefined,
                null,
                null,
            ) != 0) return error.FailedOperation;
        } else {
            const F_SETFL = 4;

            const get_flags_rc = std.os.linux.fcntl(socket.internal, F_SETFL, 0);
            const flags: u32 = switch (std.os.linux.errno(get_flags_rc)) {
                .SUCCESS => @intCast(get_flags_rc),
                else => return error.FailedOperation,
            };

            const set_flags_rc = std.os.linux.fcntl(
                socket.internal,
                F_SETFL,
                flags | std.posix.SOCK.NONBLOCK,
            );
            if (std.os.linux.errno(set_flags_rc) != .SUCCESS) return error.FailedOperation;
        }
    }

    pub fn readIncomingBytes(self: *@This()) !void {
        // read available bytes
        var read_buffer: [262144]u8 = undefined;
        const read_bytes = self.socket.receive(&read_buffer) catch |err| switch (err) {
            // no available bytes
            error.WouldBlock => return,
            else => return err,
        };
        // add to buffer
        try self.queued_bytes.write(read_buffer[0..read_bytes]);
    }

    pub fn decodeQueuedBytes(
        self: *@This(),
    ) !?S2C {
        var buffer: S2C.ReadBuffer = .fromOwnedSlice(self.queued_bytes.readableSlice());
        const packet_body_size, const packet_header_size = buffer.readVarIntExtra(3) catch |err| switch (err) {
            error.VarIntTooBig => return err,
            error.EndOfBuffer => return null,
        };

        // We don't have enough bytes - the packet is not complete
        if (buffer.remainingBytes() < packet_body_size) return null;
        @import("log").decode_packet(.{ buffer.read_location, packet_body_size });

        const packet_size = packet_header_size + @as(usize, @intCast(packet_body_size));
        // trim buffer to prevent reading
        buffer.backer = buffer.backer[0..packet_size];
        defer {
            self.queued_bytes.discard(packet_size);
        }

        // check if the buffer needs to be decompressed before it can be read as a packet

        // if we need to decompress, we will have to free the buffer, as it will
        // no longer backed by self.queued_bytes
        const decompression_info = try self.getDecompressionInfo(&buffer);

        // stack allocate decompression buffer
        var decompress_raw_buffer: [2097152]u8 = undefined;
        if (decompression_info) |size_after_decompression| {
            buffer = try decompressBuffer(&buffer, size_after_decompression, &decompress_raw_buffer);
        }

        while (true) {
            // if we fail the allocation, roll back packet buffer and allocations, and try again
            const initial_buffer_mark = buffer.read_location;
            const initial_allocator_mark = self.s2c_packet_ring_alloc.logical_alloc_index;

            switch (self.protocol) {
                // only the client ever sends packets in the handshake protocol
                .Handshake => unreachable,
                // this does not occur in a normal connection
                .Status => unreachable,
                .Login => {
                    const login = S2C.Login.decode(&buffer, self.s2c_packet_ring_alloc.allocator()) catch |err| switch (err) {
                        error.OutOfMemory => {
                            if (self.disconnected.load(.acquire)) return null;
                            try self.handleOom(&buffer, initial_buffer_mark, initial_allocator_mark);
                            continue;
                        },
                        else => |fatal| return fatal,
                    };
                    return .{ .login = login };
                },
                .Play => {
                    const play = S2C.Play.decode(&buffer, self.s2c_packet_ring_alloc.allocator()) catch |err| switch (err) {
                        error.OutOfMemory => {
                            if (self.disconnected.load(.acquire)) return null;
                            try self.handleOom(&buffer, initial_buffer_mark, initial_allocator_mark);
                            continue;
                        },
                        else => |fatal| return fatal,
                    };
                    return .{ .play = play };
                },
            }
        }
    }

    pub fn handleOom(
        self: *@This(),
        buffer: *S2C.ReadBuffer,
        initial_buffer_mark: usize,
        initial_allocator_mark: usize,
    ) !void {
        @import("log").ring_buffer_oom_wait(.{});
        // undo allocations and reads
        buffer.read_location = initial_buffer_mark;
        try self.s2c_packet_ring_alloc.undoAllocations(initial_allocator_mark);

        // free handled s2c packets to clear up memory
        try self.freeS2CPackets();
        // send c2s packets to prevent a deadlock
        try self.sendC2SPackets();
    }

    /// check if the buffer needs to be decompressed
    /// returns null if the packet does not need to be decompressed,
    /// otherwise returns the size after decompression
    pub fn getDecompressionInfo(self: *@This(), buffer: *S2C.ReadBuffer) !?i32 {
        if (self.compression_threshold < 0) return null;
        const size_after_decompression = try buffer.readVarInt();
        // packet was not compressed
        if (size_after_decompression == 0) return null;

        // decompressed size below threshold
        if (size_after_decompression < self.compression_threshold) {
            return error.PacketTooSmall;
        }
        // decompressed size above max size
        if (size_after_decompression > 2097152) return error.PacketTooLarge;

        return size_after_decompression;
    }

    pub fn decompressBuffer(compressed_buffer: *S2C.ReadBuffer, size_after_decompression: i32, decompress_raw_buffer: *[2097152]u8) !S2C.ReadBuffer {
        // take slice of unread bytes to be compressed
        const compressed_bytes = compressed_buffer.readRemainingBytesNonAllocating();

        var input: std.Io.Reader = .fixed(compressed_bytes);
        var window: [std.compress.flate.max_window_len]u8 = undefined;
        var decompressor = std.compress.flate.Decompress.init(&input, .zlib, &window);

        const out = decompress_raw_buffer[0..@intCast(size_after_decompression)];
        try decompressor.reader.readSliceAll(out);

        return .fromOwnedSlice(out);
    }

    pub fn setCompressionThreshold(self: *@This(), compression_threshold: i32) void {
        self.compression_threshold = compression_threshold;
    }

    pub fn switchProtocol(self: *@This(), protocol: Protocol) void {
        @import("log").switch_protocol(.{protocol});
        std.debug.assert(self.protocol != protocol);
        self.protocol = protocol;
    }

    /// takes ownership of uncompressed_buffer
    pub fn compressBuffer(self: *@This(), uncompressed_buffer: *C2S.WriteBuffer, allocator: std.mem.Allocator) !C2S.WriteBuffer {
        defer uncompressed_buffer.deinit();

        var compressed_bytes: std.ArrayList(u8) = .empty;
        errdefer compressed_bytes.deinit(allocator);

        if (uncompressed_buffer.backer.items.len < self.compression_threshold) {
            var compressed_buffer: C2S.WriteBuffer = .fromOwnedArrayList(allocator, compressed_bytes);
            try compressed_buffer.writeVarInt(0);
            try compressed_buffer.writeBytes(uncompressed_buffer.backer.items);
            return compressed_buffer;
        }

        // Compress needs a fixed output writer, so compress into a scratch
        // buffer and copy the result out. +64 covers the framing.
        const uncompressed = uncompressed_buffer.backer.items;
        const window = try allocator.alloc(u8, std.compress.flate.max_window_len);
        defer allocator.free(window);
        const scratch = try allocator.alloc(u8, uncompressed.len + 64);
        defer allocator.free(scratch);

        var output: std.Io.Writer = .fixed(scratch);
        var compressor = try std.compress.flate.Compress.init(&output, window, .zlib, .default);
        try compressor.writer.writeAll(uncompressed);
        try std.compress.flate.Compress.finish(&compressor);

        try compressed_bytes.appendSlice(allocator, output.buffered());

        return .fromOwnedArrayList(allocator, compressed_bytes);
    }

    /// takes ownership of original_buffer
    pub fn prependLength(original_buffer: *C2S.WriteBuffer, allocator: std.mem.Allocator) !C2S.WriteBuffer {
        defer original_buffer.deinit();

        var out_buffer: C2S.WriteBuffer = .init(allocator);
        errdefer out_buffer.deinit();

        try out_buffer.writeByteSlice(original_buffer.backer.items);
        return out_buffer;
    }

    pub fn sendHandshakePacket(self: *@This(), packet: C2S.Handshake) !void {
        try self.sendPacket(.{ .handshake = packet });
    }

    pub fn sendLoginPacket(self: *@This(), packet: C2S.Login) !void {
        try self.sendPacket(.{ .login = packet });
    }

    pub fn sendPlayPacket(self: *@This(), packet: C2S.Play) !void {
        try self.sendPacket(.{ .play = packet });
    }

    pub fn sendPacket(
        self: *@This(),
        packet: C2S,
    ) !void {
        var packet_encode_buffer: [1024 * 1024]u8 = undefined;
        var packet_encode_alloc_impl: std.heap.FixedBufferAllocator = .init(&packet_encode_buffer);
        const packet_encode_alloc = packet_encode_alloc_impl.allocator();

        var packet_buffer: C2S.WriteBuffer = .init(packet_encode_alloc);
        defer packet_buffer.deinit();

        // write packet
        switch (packet) {
            .handshake => |handshake_packet| try handshake_packet.write(&packet_buffer),
            .login => |login_packet| try login_packet.write(&packet_buffer),
            .play => |play_packet| try play_packet.write(&packet_buffer),
        }

        // compress packet
        if (self.compression_threshold >= 0) {
            packet_buffer = try self.compressBuffer(&packet_buffer, packet_encode_alloc);
        }

        packet_buffer = try prependLength(&packet_buffer, packet_encode_alloc);
        _ = try self.socket.send(packet_buffer.backer.items);
    }
};

pub const ConnectionHandle = struct {
    name: []const u8,
    port: u16,
    network_thread: std.Thread,
    /// The main thread submits to this queue, network thread encodes and sends them
    /// The main thread should periodically poll and free already sent packets
    c2s_packet_queue: *WriteReadFreeQueue(C2S),
    /// The network thread decodes packets and submits them to this queue, main thread reads and handles them
    /// The network thread should periodically poll and free already handled packets using s2c_packet_allocator
    s2c_packet_queue: *WriteReadFreeQueue(S2CWrapper),
    /// This allocator should be used to allocate memory for c2s packets and *nothing else*
    c2s_packet_allocator: std.mem.Allocator,
    /// If either thread sets this flag to true, the network thread will disconnect and halt
    disconnected: *std.atomic.Value(bool),

    pub fn sendPacket(self: *@This(), packet: C2S) !void {
        try self.c2s_packet_queue.write(packet);
    }

    pub fn sendHandshakePacket(self: *@This(), packet: C2S.Handshake) !void {
        try self.sendPacket(.{ .handshake = packet });
    }

    pub fn sendLoginPacket(self: *@This(), packet: C2S.Login) !void {
        try self.sendPacket(.{ .login = packet });
    }

    pub fn sendPlayPacket(self: *@This(), packet: C2S.Play) !void {
        try self.sendPacket(.{ .play = packet });
    }

    pub fn sendLoginSequence(self: *@This(), player_name: []const u8) !void {
        const handshake_packet: C2S.Handshake.Handshake = .{
            .version = 47,
            .address = self.name,
            .port = @intCast(self.port),
            .protocol_id = 2,
        };
        const hello_packet: C2S.Login.Hello = .{
            .player_name = player_name,
        };
        try self.sendHandshakePacket(.{ .handshake = handshake_packet });
        try self.sendLoginPacket(.{ .hello = hello_packet });
    }

    pub fn disconnect(
        self: *@This(),
        /// This should be the allocator that was passed to initConnection
        /// and was used to allocate the ring buffers used to pass packets
        allocator: std.mem.Allocator,
    ) void {
        self.disconnected.store(true, .release);
        self.network_thread.join();
        allocator.destroy(self.c2s_packet_queue);
        allocator.destroy(self.s2c_packet_queue);
        allocator.destroy(self.disconnected);
        allocator.free(self.name);
    }
};

/// Spawns a new thread and initializes a new connection in that thread, then returns a handle to that connection
pub fn initConnection(
    name: []const u8,
    port: u16,
    /// This allocator will be used to allocate the ring buffers used for passing packets between threads,
    /// also also duplicate name
    allocator: std.mem.Allocator,
    /// This allocator will be used to allocate memory for c2s packets and nothing else
    c2s_packet_allocator: std.mem.Allocator,
) !ConnectionHandle {
    const c2s_packet_queue: *WriteReadFreeQueue(C2S) = try allocator.create(WriteReadFreeQueue(C2S));
    const s2c_packet_queue: *WriteReadFreeQueue(S2CWrapper) = try allocator.create(WriteReadFreeQueue(S2CWrapper));
    const disconnect_ptr = try allocator.create(std.atomic.Value(bool));
    const name_dupe = try allocator.dupe(u8, name);

    c2s_packet_queue.* = .{};
    s2c_packet_queue.* = .{};
    disconnect_ptr.* = .init(false);

    const thread: std.Thread = try .spawn(.{ .stack_size = 16 * 1024 * 1024 }, Connection.networkThreadImpl, .{ name_dupe, port, disconnect_ptr, c2s_packet_queue, s2c_packet_queue });

    return .{
        .name = name_dupe,
        .port = port,
        .network_thread = thread,
        .c2s_packet_queue = c2s_packet_queue,
        .s2c_packet_queue = s2c_packet_queue,
        .c2s_packet_allocator = c2s_packet_allocator,
        .disconnected = disconnect_ptr,
    };
}

// Wrapper for S2C packet being sent to the main thread
pub const S2CWrapper = struct {
    // Only S2C.Play packets are ever sent to the main thread
    packet: S2C.Play,
    alloc_index: ?usize,
};

/// The network thread pushes packets with `write`.
/// The main thread takes them with `claim` and `release`s.
/// The network thread frees released elements (and their associated allocations) with `reclaim`.
/// Looks like a snake with 3 stretchy segments moving right:
///     |=========|========|========>
///  reclaim   release   claim    write
pub fn WriteReadFreeQueue(comptime Element: type) type {
    const size = 8192;
    return struct {
        buffer: [size]Element = .{undefined} ** size,

        mutex: @import("llm-code-quarantine").Mutex = .{},

        /// The next element written will go to this index
        write_index: usize = 0,
        /// The next element claimed will be at this index
        claim_index: usize = 0,
        /// The next element released will be at this index
        release_index: usize = 0,
        /// The next element reclaimed will be at this index
        reclaim_index: usize = 0,

        /// Elements written but not yet peeked by the main thread
        fn unread(self: *@This()) usize {
            return self.write_index - self.claim_index;
        }

        /// Elements claimed by the main thread but still processing. At most 1
        fn held(self: *@This()) u1 {
            return @intCast(self.claim_index - self.release_index);
        }

        /// Elements released but not yet reclaimed.
        fn released(self: *@This()) usize {
            return self.release_index - self.reclaim_index;
        }

        /// Producer: appends an element. Fails if every slot is still in use.
        pub fn write(self: *@This(), element: Element) !void {
            self.mutex.lock();
            defer self.mutex.unlock();

            if (self.unread() + self.held() + self.released() >= size) return error.WouldOverflow;

            self.buffer[self.write_index % size] = element;
            self.write_index += 1;
        }

        /// Consumer: holds the next element for processing.
        /// Element stays reserved until `release` is called.
        /// Can only claim one element at a time.
        pub fn claim(self: *@This()) ?Element {
            self.mutex.lock();
            defer self.mutex.unlock();

            std.debug.assert(self.held() == 0);

            // no elements to take
            if (self.unread() == 0) return null;

            const element = self.buffer[self.claim_index % size];

            self.claim_index += 1;

            return element;
        }

        /// Consumer: release the claimed element.
        pub fn release(self: *@This()) void {
            self.mutex.lock();
            defer self.mutex.unlock();

            std.debug.assert(self.held() == 1);

            self.release_index += 1;
        }

        /// Producer: takes back an element the consumer has
        /// finished processing so its slot can be reused
        pub fn reclaim(self: *@This()) ?Element {
            self.mutex.lock();
            defer self.mutex.unlock();

            // the main thread has not released anything new
            if (self.released() == 0) return null;

            const element = self.buffer[self.reclaim_index % size];

            self.reclaim_index += 1;

            return element;
        }
    };
}
