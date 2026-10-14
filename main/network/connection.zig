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

    /// If either thread sets this flag to true, the network thread will wait on disconnect_event then halt
    wants_disconnect: *std.atomic.Value(bool),
    /// Network thread will wait for main thread to set this before stopping
    /// This is because the network thread holds memory that the main thread reads from (in s2c_packet_ring_alloc)
    /// The main thread setting this signals that it is done reading from any memory owned
    /// by the network thread
    disconnect_event: *std.Io.Event,

    stream: std.Io.net.Stream,

    protocol: Protocol = .Login,

    compression_threshold: i32 = -1,

    /// The main thread submits to this queue, network thread encodes and sends them
    /// The main thread should periodically poll and free already sent packets using c2s_packet_allocator
    c2s_packet_queue: *WriteReadFreeQueue(C2S),
    /// The network thread decodes packets and submits them to this queue, main thread reads and handles them
    /// The network thread should periodically poll and free already handled packets using s2c_packet_allocator
    s2c_packet_queue: *WriteReadFreeQueue(S2CWrapper),

    /// A buffer of raw bytes read from the socket but not yet decoded
    queued_bytes: @import("llm-code-quarantine").FixedFifo(u8, 1024 * 1024 * 2),
    /// This ring allocator should be used to allocate memory for s2c packets and *nothing else*
    s2c_packet_ring_alloc: RingBuffer,

    pub var ringbuffer: RingBuffer = undefined;

    pub fn networkThreadImpl(
        io: std.Io,
        name: []const u8,
        port: u16,
        wants_disconnect: *std.atomic.Value(bool),
        disconnect_event: *std.Io.Event,
        c2s_packet_queue: *WriteReadFreeQueue(C2S),
        s2c_packet_queue: *WriteReadFreeQueue(S2CWrapper),
    ) !void {
        defer {
            wants_disconnect.store(true, .release);
            disconnect_event.waitUncancelable(io);
        }

        var ring_alloc_buffer: [1024 * 1024 * 8]u8 = undefined;

        const stream = try connectStream(io, name, port);
        defer stream.close(io);

        var connection: Connection = .{
            .name = name,
            .port = port,

            .wants_disconnect = wants_disconnect,
            .disconnect_event = disconnect_event,

            .stream = stream,

            .c2s_packet_queue = c2s_packet_queue,
            .s2c_packet_queue = s2c_packet_queue,

            .queued_bytes = .init(),

            .s2c_packet_ring_alloc = .initBuffer(&ring_alloc_buffer),
        };

        ringbuffer = connection.s2c_packet_ring_alloc;

        while (true) {
            connection.tick(io) catch |e| switch (e) {
                error.Canceled => {
                    std.log.scoped(.net).info("network thread cancelled", .{});
                    return;
                },
                else => {
                    if (@errorReturnTrace()) |errorReturnTrace| std.debug.dumpErrorReturnTrace(errorReturnTrace);
                    std.log.scoped(.net).info("{}, stopping network thread", .{e});
                    return e;
                },
            };
        }
    }

    pub fn tick(self: *@This(), io: std.Io) !void {
        // read from socket
        try self.readIncomingBytes(io);

        // decode and dispatch
        while (true) {
            if (self.wants_disconnect.load(.acquire)) return;
            const packet, const rewind_mark = (try self.decodeQueuedBytes(io)) orelse break;
            if (self.wants_disconnect.load(.acquire)) return;
            try self.dispatchS2CPacket(io, packet, rewind_mark);
        }

        // free handled s2c packets
        try self.freeS2CPackets(io);

        // encode and send
        try self.sendC2SPackets(io);
    }

    pub fn freeS2CPackets(self: *@This(), io: std.Io) !void {
        while (self.s2c_packet_queue.reclaim(io)) |s2c_packet_wrapper| {
            _ = s2c_packet_wrapper;
            // self.s2c_packet_ring_alloc.freeFromTail(s2c_packet_wrapper.tail_mark);
        }
    }

    pub fn sendC2SPackets(self: *@This(), io: std.Io) !void {
        while (self.c2s_packet_queue.claim(io)) |packet| {
            defer self.c2s_packet_queue.release(io);
            try self.sendPacket(io, packet);
        }
    }

    pub fn dispatchS2CPacket(self: *@This(), io: std.Io, packet: S2C, rewind_mark: RingBuffer.RewindMark) !void {
        var packet_mut = packet;
        switch (packet_mut) {
            inline else => |*specific_protocol| {
                switch (specific_protocol.*) {
                    inline else => |*specific_packet| {
                        std.log.scoped(.handle_packet_net).debug("handling packet - {s}", .{@tagName(std.meta.activeTag(specific_protocol.*))});
                        if (specific_packet.handle_on_network_thread) {
                            try specific_packet.handleOnNetworkThread(io, self);
                            // free immediately
                            _ = self.s2c_packet_ring_alloc.undoAllocations(rewind_mark);
                        } else {
                            // if packet didn't allocate, pass null allocation so we know not to free
                            try self.s2c_packet_queue.write(io, .{ .packet = packet.play, .tail_mark = self.s2c_packet_ring_alloc.commit(rewind_mark) });
                        }
                    },
                }
            },
        }
    }

    pub fn connectStream(io: std.Io, name: []const u8, port: u16) !std.Io.net.Stream {
        const ip: std.Io.net.IpAddress = try .parseIp4(name, port);
        return try ip.connect(io, .{
            .mode = .stream,
            .protocol = .tcp,
        });
    }

    pub fn readIncomingBytes(self: *@This(), io: std.Io) !void {
        var read_buffer: [262144]u8 = undefined;
        // Stream.read is unimplemented, so we just use this for now
        const read_bytes = self.stream.socket.receiveTimeout(
            io,
            &read_buffer,
            .{ .duration = .{ .raw = .fromMilliseconds(10), .clock = .real } },
        ) catch |err| switch (err) {
            error.Timeout => return,
            else => return err,
        };
        std.log.scoped(.net).debug("read {} bytes", .{read_bytes.data.len});
        // TODO: Fix our queue implementation, make it growable
        // In fact, we should probably use a memory mapped ring buffer
        // so we never have to compact the buffer
        try self.queued_bytes.write(read_bytes.data);
    }

    pub fn decodeQueuedBytes(self: *@This(), io: std.Io) !?struct { S2C, RingBuffer.RewindMark } {
        var packet_buffer: S2C.ReadBuffer = .fromOwnedSlice(self.queued_bytes.readableSlice());

        const packet_body_size, const packet_header_size = packet_buffer.readVarIntExtra(3) catch |err| switch (err) {
            error.VarIntTooBig => return err,
            error.EndOfBuffer => return null,
        };

        // we don't have enough bytes - the packet is not complete
        if (packet_buffer.remainingBytes() < packet_body_size) return null;
        std.log.scoped(.decode_packet).debug("decoding packet - {} bytes header + {} bytes body", .{ packet_buffer.read_location, packet_body_size });

        const packet_size = packet_header_size + @as(usize, @intCast(packet_body_size));

        // trim buffer to prevent reading past the packet end
        packet_buffer.backer = packet_buffer.backer[0..packet_size];
        defer self.queued_bytes.discard(packet_size);

        // check if the buffer needs to be decompressed before it can be read as a packet
        // stack allocate decompression buffer, so we never need to worry about freeing
        var decompress_buffer: []u8 = undefined;
        if (try self.getDecompressedSize(&packet_buffer)) |decompressed_size| {
            const decompressed_bytes = decompress_buffer[0..decompressed_size];
            try decompressBuffer(&packet_buffer, decompressed_bytes);
            packet_buffer = .fromOwnedSlice(decompressed_bytes);
        }

        while (true) {
            // if we fail the allocation, roll back packet buffer and allocations, and try again
            const initial_buffer_mark = packet_buffer.read_location;
            const allocator_rewind_mark = self.s2c_packet_ring_alloc.beginRewind();

            switch (self.protocol) {
                // only the client ever sends packets in the handshake protocol
                .Handshake => unreachable,
                // this does not occur in a normal connection
                .Status => unreachable,
                .Login => {
                    const login = S2C.Login.decode(self.s2c_packet_ring_alloc.allocator(), &packet_buffer) catch |err| switch (err) {
                        error.OutOfMemory => {
                            if (self.wants_disconnect.load(.acquire)) return null;
                            try self.handleOom(io, &packet_buffer, initial_buffer_mark, allocator_rewind_mark);
                            continue;
                        },
                        else => |fatal| return fatal,
                    };
                    return .{ .{ .login = login }, allocator_rewind_mark };
                },
                .Play => {
                    const play = S2C.Play.decode(self.s2c_packet_ring_alloc.allocator(), &packet_buffer) catch |err| switch (err) {
                        error.OutOfMemory => {
                            if (self.wants_disconnect.load(.acquire)) return null;
                            try self.handleOom(io, &packet_buffer, initial_buffer_mark, allocator_rewind_mark);
                            continue;
                        },
                        else => |fatal| return fatal,
                    };
                    return .{ .{ .play = play }, allocator_rewind_mark };
                },
            }
        }
    }

    var oom_count: usize = 0;

    pub fn handleOom(
        self: *@This(),
        io: std.Io,
        buffer: *S2C.ReadBuffer,
        initial_buffer_mark: usize,
        allocator_rewind_mark: RingBuffer.RewindMark,
    ) !void {
        defer oom_count += 1;
        if (oom_count % 5000 == 0) {
            std.log.scoped(.backpressure).warn("ring buffer out of memory ({}) used: {}/{}", .{
                oom_count,
                self.s2c_packet_ring_alloc.usedBytes(),
                self.s2c_packet_ring_alloc.buffer.len,
            });
            std.log.scoped(.backpressure).warn("{}/{}/{} unread/held/released s2c packets", .{
                self.s2c_packet_queue.unread(),
                self.s2c_packet_queue.held(),
                self.s2c_packet_queue.released(),
            });
        }
        // undo allocations and reads
        buffer.read_location = initial_buffer_mark;
        const freed = self.s2c_packet_ring_alloc.undoAllocations(allocator_rewind_mark);
        if (oom_count % 5000 == 0) {
            std.log.scoped(.backpressure).warn("undid {} ring buffer bytes, now {}", .{ freed, self.s2c_packet_ring_alloc.usedBytes() });
        }
        // free handled s2c packets to clear up memory
        try self.freeS2CPackets(io);
        // send c2s packets to prevent a deadlock
        try self.sendC2SPackets(io);
    }

    /// check if the buffer needs to be decompressed
    /// returns null if the packet does not need to be decompressed,
    /// otherwise returns the size after decompression
    pub fn getDecompressedSize(self: *@This(), buffer: *S2C.ReadBuffer) !?usize {
        if (self.compression_threshold < 0) return null;

        const size_after_decompression = try buffer.readVarInt();

        return if (size_after_decompression == 0)
            null
        else if (size_after_decompression < self.compression_threshold)
            error.PacketTooSmall
        else if (size_after_decompression > 2097152)
            error.PacketTooLarge
        else
            @intCast(size_after_decompression);
    }

    pub fn decompressBuffer(compressed_buffer: *S2C.ReadBuffer, decompressed_bytes_out: []u8) !void {
        // take slice of unread bytes to be compressed
        const compressed_bytes = compressed_buffer.readRemainingBytesNonAllocating();

        var input: std.Io.Reader = .fixed(compressed_bytes);
        var window: [std.compress.flate.max_window_len]u8 = undefined;
        var decompressor: std.compress.flate.Decompress = .init(&input, .zlib, &window);

        try decompressor.reader.readSliceAll(decompressed_bytes_out);
    }

    pub fn setCompressionThreshold(self: *@This(), compression_threshold: i32) void {
        self.compression_threshold = compression_threshold;
    }

    pub fn switchProtocol(self: *@This(), protocol: Protocol) void {
        std.log.scoped(.switch_protocol).debug("switching protocol to {}", .{protocol});
        std.debug.assert(self.protocol != protocol);
        self.protocol = protocol;
    }

    /// takes ownership of uncompressed_buffer
    pub fn compressBuffer(self: *@This(), allocator: std.mem.Allocator, uncompressed_buffer: *C2S.WriteBuffer) !C2S.WriteBuffer {
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
    pub fn prependLength(allocator: std.mem.Allocator, original_buffer: *C2S.WriteBuffer) !C2S.WriteBuffer {
        defer original_buffer.deinit();

        var out_buffer: C2S.WriteBuffer = .init(allocator);
        errdefer out_buffer.deinit();

        try out_buffer.writeByteSlice(original_buffer.backer.items);
        return out_buffer;
    }

    pub fn sendHandshakePacket(self: *@This(), io: std.Io, packet: C2S.Handshake) !void {
        try self.sendPacket(io, .{ .handshake = packet });
    }

    pub fn sendLoginPacket(self: *@This(), io: std.Io, packet: C2S.Login) !void {
        try self.sendPacket(io, .{ .login = packet });
    }

    pub fn sendPlayPacket(self: *@This(), io: std.Io, packet: C2S.Play) !void {
        try self.sendPacket(io, .{ .play = packet });
    }

    pub fn sendPacket(
        self: *@This(),
        io: std.Io,
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
            packet_buffer = try self.compressBuffer(packet_encode_alloc, &packet_buffer);
        }

        packet_buffer = try prependLength(packet_encode_alloc, &packet_buffer);
        var buf: [1024]u8 = undefined;
        var writer = self.stream.writer(io, &buf);
        std.log.scoped(.net).debug("sending {} bytes", .{packet_buffer.backer.items.len});
        _ = try writer.interface.write(packet_buffer.backer.items);
        try writer.interface.flush();
    }
};

pub const ConnectionHandle = struct {
    name: []const u8,
    port: u16,
    network_task: std.Io.Future(@typeInfo(@TypeOf(network.connection.Connection.networkThreadImpl)).@"fn".return_type.?),
    /// The main thread submits to this queue, network thread encodes and sends them
    /// The main thread should periodically poll and free already sent packets
    c2s_packet_queue: *WriteReadFreeQueue(C2S),
    /// The network thread decodes packets and submits them to this queue, main thread reads and handles them
    /// The network thread should periodically poll and free already handled packets using s2c_packet_allocator
    s2c_packet_queue: *WriteReadFreeQueue(S2CWrapper),
    /// This allocator should be used to allocate memory for c2s packets and *nothing else*
    /// It is currently usused, but there *are* c2s packets that will need allocation.
    /// At that point, we should switch to a RingBuffer and do the same song and dance the
    /// s2c_packet_allocator goes through
    c2s_packet_allocator: std.mem.Allocator,
    /// If either thread sets this flag to true, the network thread will wait on disconnect_event then halt
    wants_disconnect: *std.atomic.Value(bool),
    /// Network thread will wait for main thread to set this before stopping
    /// This is because the network thread holds memory that the main thread reads from (in s2c_packet_ring_alloc)
    /// The main thread setting this signals that it is done reading from any memory owned
    /// by the network thread
    disconnect_event: *std.Io.Event,

    pub fn sendPacket(
        self: *@This(),
        io: std.Io,
        packet: C2S,
    ) !void {
        try self.c2s_packet_queue.write(io, packet);
    }

    pub fn sendHandshakePacket(self: *@This(), io: std.Io, packet: C2S.Handshake) !void {
        try self.sendPacket(io, .{ .handshake = packet });
    }

    pub fn sendLoginPacket(self: *@This(), io: std.Io, packet: C2S.Login) !void {
        try self.sendPacket(io, .{ .login = packet });
    }

    pub fn sendPlayPacket(self: *@This(), io: std.Io, packet: C2S.Play) !void {
        try self.sendPacket(io, .{ .play = packet });
    }

    pub fn sendLoginSequence(self: *@This(), io: std.Io, player_name: []const u8) !void {
        const handshake_packet: C2S.Handshake.Handshake = .{
            .version = 47,
            .address = self.name,
            .port = @intCast(self.port),
            .protocol_id = 2,
        };
        const hello_packet: C2S.Login.Hello = .{
            .player_name = player_name,
        };
        try self.sendHandshakePacket(io, .{ .handshake = handshake_packet });
        try self.sendLoginPacket(io, .{ .hello = hello_packet });
    }

    pub fn disconnect(
        self: *@This(),
        io: std.Io,
        /// This should be the allocator that was passed to initConnection
        /// and was used to allocate the ring buffers used to pass packets
        allocator: std.mem.Allocator,
    ) void {
        std.log.scoped(.net).info("sending cancel to network thread", .{});
        self.wants_disconnect.store(true, .release);
        self.disconnect_event.set(io);
        self.network_task.cancel(io) catch {};
        allocator.destroy(self.c2s_packet_queue);
        allocator.destroy(self.s2c_packet_queue);
        allocator.destroy(self.wants_disconnect);
        allocator.destroy(self.disconnect_event);
        allocator.free(self.name);
        std.log.scoped(.net).info("disconnected successfully", .{});
    }
};

/// Spawns a new thread and initializes a new connection in that thread, then returns a handle to that connection
pub fn initConnection(
    io: std.Io,
    /// This allocator will be used to allocate the ring buffers used for passing packets between threads,
    /// also also duplicate name
    allocator: std.mem.Allocator,
    /// This allocator will be used to allocate memory for c2s packets and nothing else
    /// It is currently usused, but there *are* c2s packets that will need allocation.
    /// At that point, we should switch to a RingBuffer and do the same song and dance the
    /// s2c_packet_allocator goes through
    c2s_packet_allocator: std.mem.Allocator,
    name: []const u8,
    port: u16,
) !ConnectionHandle {
    const c2s_packet_queue: *WriteReadFreeQueue(C2S) = try allocator.create(WriteReadFreeQueue(C2S));
    const s2c_packet_queue: *WriteReadFreeQueue(S2CWrapper) = try allocator.create(WriteReadFreeQueue(S2CWrapper));

    const disconnect_event = try allocator.create(std.Io.Event);
    const wants_disconnect = try allocator.create(std.atomic.Value(bool));

    const name_dupe = try allocator.dupe(u8, name);

    c2s_packet_queue.* = .{};
    s2c_packet_queue.* = .{};
    disconnect_event.* = .unset;
    wants_disconnect.*.raw = false;

    const network_task = try io.concurrent(
        Connection.networkThreadImpl,
        .{
            io,
            name_dupe,
            port,
            wants_disconnect,
            disconnect_event,
            c2s_packet_queue,
            s2c_packet_queue,
        },
    );

    return .{
        .name = name_dupe,
        .port = port,
        .network_task = network_task,
        .c2s_packet_queue = c2s_packet_queue,
        .s2c_packet_queue = s2c_packet_queue,
        .c2s_packet_allocator = c2s_packet_allocator,
        .wants_disconnect = wants_disconnect,
        .disconnect_event = disconnect_event,
    };
}

// Wrapper for S2C packet being sent to the main thread
pub const S2CWrapper = struct {
    // Only S2C.Play packets are ever sent to the main thread
    packet: S2C.Play,
    tail_mark: RingBuffer.TailMark,
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
        buffer: [size]Element = @splat(undefined),

        mutex: std.Io.Mutex = .init,

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
        pub fn write(self: *@This(), io: std.Io, element: Element) !void {
            self.mutex.lockUncancelable(io);
            defer self.mutex.unlock(io);

            if (self.unread() + self.held() + self.released() >= size) return error.WouldOverflow;

            self.buffer[self.write_index % size] = element;
            self.write_index += 1;
        }

        /// Consumer: holds the next element for processing.
        /// Element stays reserved until `release` is called.
        /// Can only claim one element at a time.
        pub fn claim(self: *@This(), io: std.Io) ?Element {
            self.mutex.lockUncancelable(io);
            defer self.mutex.unlock(io);

            std.debug.assert(self.held() == 0);

            // no elements to take
            if (self.unread() == 0) return null;

            const element = self.buffer[self.claim_index % size];

            self.claim_index += 1;

            return element;
        }

        /// Consumer: release the claimed element.
        pub fn release(self: *@This(), io: std.Io) void {
            self.mutex.lockUncancelable(io);
            defer self.mutex.unlock(io);

            std.debug.assert(self.held() == 1);

            self.release_index += 1;
        }

        /// Producer: takes back an element the consumer has
        /// finished processing so its slot can be reused
        pub fn reclaim(self: *@This(), io: std.Io) ?Element {
            self.mutex.lockUncancelable(io);
            defer self.mutex.unlock(io);

            // the main thread has not released anything new
            if (self.released() == 0) return null;

            const element = self.buffer[self.reclaim_index % size];

            self.reclaim_index += 1;

            return element;
        }
    };
}
