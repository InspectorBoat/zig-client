const std = @import("std");
const network_lib = @import("network");
const root = @import("root");
const network = root.network;
const WritePacketBuffer = network.packet.c2s.WritePacketBuffer;
const ReadPacketBuffer = network.packet.c2s.ReadPacketBuffer;
const Protocol = network.Protocol;
const S2CLoginPacket = network.packet.S2CLoginPacket;
const S2CPlayPacket = network.packet.S2CPlayPacket;
const C2SHandshakePacket = network.packet.C2SHandshakePacket;
const C2SLoginPacket = network.packet.C2SLoginPacket;
const C2SPlayPacket = network.packet.C2SPlayPacket;
const C2SPacket = network.packet.C2SPacket;
const S2CPacket = network.packet.S2CPacket;
const HandShakeC2SPacket = network.packet.c2s.handshake.HandshakeC2SPacket;
const HelloC2SPacket = network.packet.c2s.handshake.HandshakeC2SPacket;
const Game = root.Game;
const RingBuffer = @import("util").RingBuffer;

pub const Connection = struct {
    /// The network thread does not own this memory
    name: []const u8,
    port: u16,

    disconnected: *bool,

    socket: network_lib.Socket,

    protocol: Protocol = .Login,

    compression_threshold: i32 = -1,

    /// The main thread submits to this queue, network thread encodes and sends them
    /// The main thread should periodically poll and free already sent packets using c2s_packet_allocator
    c2s_packet_queue: *WriteReadFreeQueue(C2SPacket),
    /// The network thread decodes packets and submits them to this queue, main thread reads and handles them
    /// The network thread should periodically poll and free already handled packets using s2c_packet_allocator
    s2c_packet_queue: *WriteReadFreeQueue(S2CPacketWrapper),

    /// A buffer of raw bytes read from the socket but not yet decoded
    queued_bytes: std.fifo.LinearFifo(u8, .{ .Static = 1024 * 1024 }),
    /// This ring allocator should be used to allocate memory for s2c packets and *nothing else*
    s2c_packet_ring_alloc: RingBuffer,

    pub fn networkThreadImpl(
        name: []const u8,
        port: u16,
        disconnect_ptr: *bool,
        c2s_packet_queue: *WriteReadFreeQueue(C2SPacket),
        s2c_packet_queue: *WriteReadFreeQueue(S2CPacketWrapper),
    ) !void {
        var ring_alloc_buffer: [1024 * 1024 * 8]u8 = undefined;
        var connection: Connection = .{
            .name = name,
            .port = port,

            .disconnected = disconnect_ptr,

            .socket = connectSocket(name, port) catch {
                disconnect_ptr.* = true;
                return;
            },

            .c2s_packet_queue = c2s_packet_queue,
            .s2c_packet_queue = s2c_packet_queue,

            .queued_bytes = std.fifo.LinearFifo(u8, .{ .Static = 1024 * 1024 }).init(),

            .s2c_packet_ring_alloc = .{ .buffer = &ring_alloc_buffer },
        };

        while (true) {
            connection.tick() catch {
                connection.disconnected.* = true;
            };
            if (connection.disconnected.*) {
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
            const initial_alloc_index = self.s2c_packet_ring_alloc.alloc_index;
            const maybe_packet = try self.decodeQueuedBytes();
            if (self.disconnected.*) return;
            if (maybe_packet) |packet| {
                try self.dispatchS2CPacket(packet, initial_alloc_index);
                if (self.disconnected.*) return;
            } else break;
        }

        // free handled s2c packets
        try self.freeS2CPackets();

        // encode and send
        try self.sendC2SPackets();
    }

    pub fn freeS2CPackets(self: *@This()) !void {
        self.s2c_packet_queue.lock();
        errdefer self.s2c_packet_queue.unlock();
        while (self.s2c_packet_queue.free()) |s2c_packet_wrapper| {
            // only free if packet actually allocated any memory
            if (s2c_packet_wrapper.alloc_index) |alloc_index| {
                try self.s2c_packet_ring_alloc.freeOldest(alloc_index);
            }
        }
        self.s2c_packet_queue.unlock();
    }

    pub fn sendC2SPackets(self: *@This()) !void {
        self.c2s_packet_queue.lock();
        errdefer self.c2s_packet_queue.unlock();
        while (self.c2s_packet_queue.read()) |packet| {
            try self.sendPacket(packet);
        }
        self.c2s_packet_queue.unlock();
    }

    pub fn dispatchS2CPacket(self: *@This(), packet: S2CPacket, initial_alloc_index: usize) !void {
        var packet_mut = packet;
        switch (packet_mut) {
            inline else => |*specific_protocol| {
                switch (specific_protocol.*) {
                    inline else => |*specific_packet| {
                        if (specific_packet.handle_on_network_thread) {
                            @import("log").handle_packet(.{specific_packet});
                            try specific_packet.handleOnNetworkThread(self);
                            // free immediately
                            if (self.s2c_packet_ring_alloc.alloc_index != initial_alloc_index) {
                                try self.s2c_packet_ring_alloc.freeLatest(initial_alloc_index);
                            }
                        } else {
                            // if packet didn't allocate, pass null allocation so we know not to free
                            const alloc_index = if (self.s2c_packet_ring_alloc.alloc_index != initial_alloc_index)
                                self.s2c_packet_ring_alloc.alloc_index
                            else
                                null;
                            self.s2c_packet_queue.lock();
                            errdefer self.s2c_packet_queue.unlock();
                            try self.s2c_packet_queue.write(.{ .packet = packet, .alloc_index = alloc_index });
                            self.s2c_packet_queue.unlock();
                        }
                    },
                }
            },
        }
    }

    pub fn connectSocket(name: []const u8, port: u16) !network_lib.Socket {
        var buffer: [8192]u8 = undefined;
        var fba_impl = std.heap.FixedBufferAllocator.init(&buffer);

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

            const flags = try std.posix.fcntl(socket.internal, F_SETFL, 0);

            if (flags == -1) return error.FailedOperation;
            if (try std.posix.fcntl(
                socket.internal,
                F_SETFL,
                flags | std.posix.SOCK.NONBLOCK,
            ) != 0)
                return error.FailedOperation;
        }
    }

    pub fn readIncomingBytes(self: *@This()) !void {
        // read available bytes
        var read_buffer: [262144]u8 = undefined;
        const read_bytes = self.socket.reader().read(&read_buffer) catch |err| switch (err) {
            // no available bytes
            error.WouldBlock => return,
            else => return err,
        };
        // add to buffer
        try self.queued_bytes.write(read_buffer[0..read_bytes]);
    }

    pub fn decodeQueuedBytes(
        self: *@This(),
    ) !?S2CPacket {
        var buffer = ReadPacketBuffer.fromOwnedSlice(self.queued_bytes.readableSlice(0));
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
            self.queued_bytes.realign();
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

        const packet = packet: {
            while (true) {
                // if we fail the allocation, reset the packet buffer, reset the allocations, and try again
                const initial_read_location = buffer.read_location;
                const initial_alloc_index = self.s2c_packet_ring_alloc.alloc_index;

                const packet = switch (self.protocol) {
                    // only the client ever sends packets in the handshake protocol
                    .Handshake => unreachable,
                    // this does not occur in a normal connection
                    .Status => unreachable,
                    .Login => S2CPacket{
                        .Login = S2CLoginPacket.decode(&buffer, self.s2c_packet_ring_alloc.allocator()) catch {
                            if (self.disconnected.*) return null;
                            try self.handleOom(&buffer, initial_read_location, initial_alloc_index);
                            continue;
                        },
                    },
                    .Play => S2CPacket{
                        .Play = S2CPlayPacket.decode(&buffer, self.s2c_packet_ring_alloc.allocator()) catch {
                            if (self.disconnected.*) return null;
                            try self.handleOom(&buffer, initial_read_location, initial_alloc_index);
                            continue;
                        },
                    },
                };

                break :packet packet;
            }
        };

        if (buffer.remainingBytes() > 0) @import("log").warn_unused_buffer_bytes(.{buffer.remainingBytes()});

        return packet;
    }

    pub fn handleOom(
        self: *@This(),
        buffer: *ReadPacketBuffer,
        initial_read_location: usize,
        initial_alloc_index: usize,
    ) !void {
        @import("log").ring_buffer_oom_wait(.{});
        // reset packet buffer
        buffer.read_location = initial_read_location;
        // free if any bytes were actually allocated
        if (initial_alloc_index != self.s2c_packet_ring_alloc.alloc_index) try self.s2c_packet_ring_alloc.freeLatest(initial_alloc_index);

        // free s2c packets to clear up memory
        try self.freeS2CPackets();
        // try to send c2s packets to prevent a deadlock
        try self.sendC2SPackets();
    }

    /// check if the buffer needs to be decompressed
    /// returns null if the packet does not need to be decompressed,
    /// otherwise returns the size after decompression
    pub fn getDecompressionInfo(self: *@This(), buffer: *ReadPacketBuffer) !?i32 {
        if (self.compression_threshold < 0) return null;
        const size_after_decompression = try buffer.readVarInt();
        // packet was not compressed
        if (size_after_decompression == 0) return null;

        // decompressed size below threshold
        if (size_after_decompression < self.compression_threshold) return error.PacketTooSmall;
        // decompressed size above max size
        if (size_after_decompression > 2097152) return error.PacketTooLarge;

        return size_after_decompression;
    }

    pub fn decompressBuffer(compressed_buffer: *ReadPacketBuffer, size_after_decompression: i32, decompress_raw_buffer: *[2097152]u8) !ReadPacketBuffer {
        // take slice of unread bytes to be compressed
        const compressed_bytes = compressed_buffer.readRemainingBytesNonAllocating();

        var compressed_byte_stream = std.io.fixedBufferStream(compressed_bytes);
        var decompressor = std.compress.zlib.decompressor(compressed_byte_stream.reader());

        const actual_decompressed_size = try decompressor.reader().readAll(decompress_raw_buffer[0..@intCast(size_after_decompression)]);
        std.debug.assert(actual_decompressed_size == size_after_decompression);

        return ReadPacketBuffer.fromOwnedSlice(decompress_raw_buffer[0..@intCast(size_after_decompression)]);
    }

    pub fn setCompressionThreshold(self: *@This(), compression_threshold: i32) void {
        self.compression_threshold = compression_threshold;
    }

    pub fn switchProtocol(self: *@This(), protocol: Protocol) void {
        @import("log").switch_protocol(.{protocol});
        std.debug.assert(self.protocol != protocol);
        self.protocol = protocol;
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.socket.close();
        self.queued_bytes.deinit();
        allocator.free(self.address);
    }

    /// takes ownership of uncompressed_buffer
    pub fn compressBuffer(self: *@This(), uncompressed_buffer: *WritePacketBuffer, allocator: std.mem.Allocator) !WritePacketBuffer {
        defer uncompressed_buffer.deinit();

        var compressed_bytes = std.ArrayList(u8).init(allocator);
        errdefer compressed_bytes.deinit();

        if (uncompressed_buffer.backer.items.len < self.compression_threshold) {
            var compressed_buffer = WritePacketBuffer.fromOwnedArrayList(compressed_bytes);
            try compressed_buffer.writeVarInt(0);
            try compressed_buffer.writeBytes(uncompressed_buffer.backer.items);
            return compressed_buffer;
        }

        var compressor = try std.compress.zlib.compressor(compressed_bytes.writer(), .{});
        try compressor.writer().writeAll(uncompressed_buffer.backer.items);
        try compressor.finish();

        return WritePacketBuffer.fromOwnedArrayList(compressed_bytes);
    }

    /// takes ownership of original_buffer
    pub fn prependLength(original_buffer: *WritePacketBuffer, allocator: std.mem.Allocator) !WritePacketBuffer {
        defer original_buffer.deinit();

        var out_buffer = WritePacketBuffer.init(allocator);
        errdefer out_buffer.deinit();

        try out_buffer.writeByteSlice(original_buffer.backer.items);
        return out_buffer;
    }

    pub fn sendHandshakePacket(self: *@This(), packet: C2SHandshakePacket) !void {
        try self.sendPacket(.{ .Handshake = packet });
    }

    pub fn sendLoginPacket(self: *@This(), packet: C2SLoginPacket) !void {
        try self.sendPacket(.{ .Login = packet });
    }

    pub fn sendPlayPacket(self: *@This(), packet: C2SPlayPacket) !void {
        try self.sendPacket(.{ .Play = packet });
    }

    pub fn sendPacket(
        self: *@This(),
        packet: C2SPacket,
    ) !void {
        var packet_encode_buffer: [1024 * 1024]u8 = undefined;
        var packet_encode_alloc_impl = std.heap.FixedBufferAllocator.init(&packet_encode_buffer);
        const packet_encode_alloc = packet_encode_alloc_impl.allocator();

        var packet_buffer = WritePacketBuffer.init(packet_encode_alloc);
        defer packet_buffer.deinit();

        // write packet
        switch (packet) {
            .Handshake => |handshake_packet| try handshake_packet.write(&packet_buffer),
            .Login => |login_packet| try login_packet.write(&packet_buffer),
            .Play => |play_packet| try play_packet.write(&packet_buffer),
        }

        // compress packet
        if (self.compression_threshold >= 0) {
            packet_buffer = try self.compressBuffer(&packet_buffer, packet_encode_alloc);
        }

        packet_buffer = try prependLength(&packet_buffer, packet_encode_alloc);
        try self.socket.writer().writeAll(packet_buffer.backer.items);
    }

    pub fn tcpConnectToHost(allocator: std.mem.Allocator, name: []const u8, port: u16) std.net.TcpConnectToHostError!std.net.Stream {
        const list = try std.net.getAddressList(allocator, name, port);
        defer list.deinit();

        if (list.addrs.len == 0) return error.UnknownHostName;

        for (list.addrs) |addr| {
            return tcpConnectToAddress(addr) catch |err| switch (err) {
                error.ConnectionRefused => {
                    continue;
                },
                else => return err,
            };
        }
        return std.os.ConnectError.ConnectionRefused;
    }

    pub fn tcpConnectToAddress(address: std.net.Address) std.net.TcpConnectToAddressError!std.net.Stream {
        const sock_flags = std.os.SOCK.STREAM | std.os.SOCK.NONBLOCK |
            (if (@import("builtin").target.os.tag == .windows) 0 else std.os.SOCK.CLOEXEC);
        const sockfd = try std.os.socket(address.any.family, sock_flags, std.os.IPPROTO.TCP);
        errdefer std.net.Stream.close(.{ .handle = sockfd });
        std.os.connect(sockfd, &address.any, address.getOsSockLen()) catch |err| switch (err) {
            error.WouldBlock => void{},
            else => return err,
        };

        return std.net.Stream{ .handle = sockfd };
    }
};

pub const ConnectionHandle = struct {
    name: []const u8,
    port: u16,
    network_thread: std.Thread,
    /// The main thread submits to this queue, network thread encodes and sends them
    /// The main thread should periodically poll and free already sent packets
    c2s_packet_queue: *WriteReadFreeQueue(C2SPacket),
    /// The network thread decodes packets and submits them to this queue, main thread reads and handles them
    /// The network thread should periodically poll and free already handled packets using s2c_packet_allocator
    s2c_packet_queue: *WriteReadFreeQueue(S2CPacketWrapper),
    /// This allocator should be used to allocate memory for c2s packets and *nothing else*
    c2s_packet_allocator: std.mem.Allocator,
    /// If either thread sets this flag to true, the network thread will disconnect and halt
    disconnected: *bool,

    pub fn sendPacket(self: *@This(), packet: C2SPacket) !void {
        self.c2s_packet_queue.lock();
        errdefer self.c2s_packet_queue.unlock();
        try self.c2s_packet_queue.write(packet);
        self.c2s_packet_queue.unlock();
    }

    pub fn getPacket(self: *@This()) ?S2CPacket {
        self.s2c_packet_queue.mutex.lock();
        const packet = self.c2s_packet_queue.queue.readItem();
        self.c2s_packet_queue.mutex.unlock();
        return packet;
    }

    pub fn sendHandshakePacket(self: *@This(), packet: C2SHandshakePacket) !void {
        try self.sendPacket(.{ .Handshake = packet });
    }

    pub fn sendLoginPacket(self: *@This(), packet: C2SLoginPacket) !void {
        try self.sendPacket(.{ .Login = packet });
    }

    pub fn sendPlayPacket(self: *@This(), packet: C2SPlayPacket) !void {
        try self.sendPacket(.{ .Play = packet });
    }

    pub fn sendLoginSequence(self: *@This(), player_name: []const u8) !void {
        const handshake_packet = HandShakeC2SPacket{
            .version = 47,
            .address = self.name,
            .port = @intCast(self.port),
            .protocol_id = 2,
        };
        const hello_packet = HelloC2SPacket{
            .player_name = player_name,
        };
        try self.sendHandshakePacket(.{ .Handshake = handshake_packet });
        try self.sendLoginPacket(.{ .Hello = hello_packet });
    }

    pub fn disconnect(
        self: *@This(),
        /// This should be the allocator that was passed to initConnection
        /// and was used to allocate the ring buffers used to pass packets
        allocator: std.mem.Allocator,
    ) void {
        self.disconnected.* = true;
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
    const c2s_packet_queue: *WriteReadFreeQueue(C2SPacket) = try allocator.create(WriteReadFreeQueue(C2SPacket));
    const s2c_packet_queue: *WriteReadFreeQueue(S2CPacketWrapper) = try allocator.create(WriteReadFreeQueue(S2CPacketWrapper));
    const disconnect_ptr = try allocator.create(bool);
    const name_dupe = try allocator.dupe(u8, name);

    c2s_packet_queue.* = .{};
    s2c_packet_queue.* = .{};
    disconnect_ptr.* = false;

    const thread = try std.Thread.spawn(.{}, Connection.networkThreadImpl, .{ name_dupe, port, disconnect_ptr, c2s_packet_queue, s2c_packet_queue });

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

pub const S2CPacketWrapper = struct {
    packet: S2CPacket,
    alloc_index: ?usize,
};

/// A variation on a FIFO queue
/// The first thread writes, the other reads, and the first then frees
// Could be better, but whatever
pub fn WriteReadFreeQueue(comptime Element: type) type {
    const size = 8192;
    return struct {
        buffer: [size]Element = .{undefined} ** size,

        mutex: std.Thread.Mutex = .{},

        /// The next element freed will be from this index
        free_index: usize = 0,
        /// The next element read will be read from this index
        read_index: usize = 0,
        /// The next element will be written to the index
        write_index: usize = 0,

        /// Elements that have been written but not read
        unread: usize = 0,
        /// Elements that have been read but not freed
        unfreed: usize = 0,

        pub fn lock(self: *@This()) void {
            self.mutex.lock();
        }

        pub fn tryLock(self: *@This()) bool {
            return self.mutex.tryLock();
        }

        pub fn unlock(self: *@This()) void {
            self.mutex.unlock();
        }

        pub fn write(self: *@This(), element: Element) !void {
            // we're out of space, as we have caught up to the free index
            if (self.unread + self.unfreed >= size) return error.WouldOverflow;

            self.buffer[self.write_index] = element;

            self.write_index += 1;
            self.write_index %= size;

            self.unread += 1;
        }

        pub fn read(self: *@This()) ?Element {
            // no elements to read
            if (self.unread == 0) return null;

            const element = self.buffer[self.read_index];

            self.read_index += 1;
            self.read_index %= size;

            self.unread -= 1;
            self.unfreed += 1;

            return element;
        }

        pub fn free(self: *@This()) ?Element {
            // no elements to free
            if (self.unfreed == 0) return null;

            const element = self.buffer[self.free_index];

            self.free_index += 1;
            self.free_index %= size;

            self.unfreed -= 1;
            return element;
        }
    };
}
