const std = @import("std");

const zio = @import("zio");
const quarantine = @import("llm-code-quarantine");
const main = @import("main");
const util = @import("util");

const Connection = @This();
pub const ConnectError = std.Io.net.IpAddress.ConnectError;
const network = main.network;
const Protocol = network.Protocol;
const C2S = network.packet.C2S;
const S2C = network.packet.S2C;
const RingBuffer = util.RingBuffer;
const SpscQueue = util.SpscQueue;

protocol: Protocol = .Login,
compression_threshold: i32 = -1,

wants_disconnect: std.atomic.Value(bool) = .init(false),

ip: zio.net.IpAddress,
stream: zio.net.Stream,

incoming_packets: SpscQueue(S2CWrapper),
outgoing_packets: SpscQueue(C2SWrapper),

incoming_allocator: RingBuffer,
outgoing_allocator: RingBuffer,

pub fn networkThreadImpl(connection: *@This()) Error!void {
    defer connection.wants_disconnect.store(true, .release);
    std.log.scoped(.net).info("network task entered", .{});

    connection.tick() catch |e| switch (e) {
        error.Canceled => {
            std.log.scoped(.net).info("network task cancelled", .{});
            return;
        },
        else => {
            if (@errorReturnTrace()) |errorReturnTrace| std.debug.dumpErrorReturnTrace(errorReturnTrace);
            std.log.scoped(.net).info("{}, stopping network task", .{e});
            return e;
        },
    };
}

pub const Error = ReceiveBytesError || DecodePacketError || DispatchPacketError || SendPacketError;
pub fn tick(self: *@This()) Error!void {
    const unread_bytes: *quarantine.FixedFifo(u8, 1024 * 1024) = std.heap.page_allocator.create(quarantine.FixedFifo(u8, 1024 * 1024)) catch return;
    unread_bytes.* = .init();

    while (true) {
        try zio.maybeYield();

        // read from socket
        try self.receiveBytes(unread_bytes);

        // decode and dispatch
        while (true) {
            const packet, const rewind_mark = (self.decodePacket(unread_bytes) catch |e| switch (e) {
                error.RingBufferFull => {
                    std.log.scoped(.backpressure).warn("ring buffer out of memory: {}/{}", .{ self.incoming_allocator.usedBytes(), self.incoming_allocator.buffer.len });
                    break;
                },
                else => return e,
            }) orelse break;
            try self.dispatchS2CPacket(packet, rewind_mark);
        }

        // encode and send outbound packets
        try self.sendC2SPackets();
    }
}

pub fn sendC2SPackets(self: *@This()) SendPacketError!void {
    while (self.outgoing_packets.pop()) |packet| {
        try self.sendPacket(packet.@"0");
    }
}

pub const DispatchPacketError = error{ PacketHandlingError, QueueFull };
pub fn dispatchS2CPacket(self: *@This(), packet: S2C, rewind_mark: RingBuffer.RewindMark) DispatchPacketError!void {
    var packet_mut = packet;
    switch (packet_mut) {
        inline else => |*specific_protocol| {
            switch (specific_protocol.*) {
                inline else => |*specific_packet| {
                    if (specific_packet.handle_on_network_thread) {
                        std.log.scoped(.handle_packet_net).debug("handling packet - {s}", .{@tagName(std.meta.activeTag(specific_protocol.*))});
                        specific_packet.handleOnNetworkThread(undefined, self) catch return error.PacketHandlingError;
                        // free immediately
                        self.incoming_allocator.undoAllocations(rewind_mark);
                    } else {
                        self.incoming_packets.push(.{ packet.play, self.incoming_allocator.commit(rewind_mark) }) catch return error.QueueFull;
                    }
                },
            }
        },
    }
}

pub const ReceiveBytesError = (zio.ev.NetRecv.Error || zio.Timeoutable) || std.mem.Allocator.Error;
pub fn receiveBytes(
    self: *@This(),
    bytes: *quarantine.FixedFifo(u8, 1024 * 1024),
) ReceiveBytesError!void {
    var read_buffer: [262144]u8 = undefined;
    const read_bytes = self.stream.read(
        &read_buffer,
        .{ .duration = .zero },
    ) catch |err| switch (err) {
        error.Timeout => return,
        else => return err,
    };
    std.log.scoped(.net).debug("read {} bytes", .{read_bytes});
    // TODO: Fix our queue implementation, make it growable
    // In fact, we should probably use a memory mapped ring buffer
    // so we never have to compact the buffer
    try bytes.write(read_buffer[0..read_bytes]);
}

pub const DecodePacketError = DecompressPacketError || PacketHeaderError || S2C.ReadPacketError || error{RingBufferFull};
pub fn decodePacket(self: *@This(), unread_bytes: *quarantine.FixedFifo(u8, 1024 * 1024)) DecodePacketError!?struct { S2C, RingBuffer.RewindMark } {
    var packet_buffer: S2C.ReadBuffer = .fromOwnedSlice(unread_bytes.readableSlice());

    const packet_body_size, const packet_header_size = packet_buffer.readVarIntExtra(3) catch |err| switch (err) {
        error.VarIntTooBig => return error.MalformedPacket,
        error.EndOfBuffer => return null,
    };

    // we don't have enough bytes, so the packet is not complete
    if (packet_buffer.remainingBytes() < packet_body_size) return null;
    std.log.scoped(.decode_packet).debug("decoding packet - {} bytes header + {} bytes body", .{ packet_buffer.read_location, packet_body_size });

    const packet_size = packet_header_size + @as(usize, @intCast(packet_body_size));

    var ok = true;
    defer if (ok) unread_bytes.discard(packet_size);
    errdefer ok = false;

    // trim buffer to prevent reading past the packet end
    packet_buffer.backer = packet_buffer.backer[0..packet_size];

    // check if the buffer needs to be decompressed before it can be read as a packet
    // stack allocate decompression buffer, so we never need to worry about freeing
    var decompress_buffer: [2097152]u8 = undefined;
    if (self.getDecompressedSize(&packet_buffer) catch return error.PacketDecompressionError) |decompressed_size| {
        const decompressed_bytes = decompress_buffer[0..decompressed_size];
        try decompressBuffer(&packet_buffer, decompressed_bytes);
        packet_buffer = .fromOwnedSlice(decompressed_bytes);
    }

    // if we fail the allocation, roll back packet buffer and allocations
    const allocator_rewind_mark = self.incoming_allocator.beginRewind();
    errdefer self.incoming_allocator.undoAllocations(allocator_rewind_mark);

    switch (self.protocol) {
        // only the client ever sends packets in the handshake protocol
        .Handshake => unreachable,
        // this does not occur in a normal connection
        .Status => unreachable,
        .Login => {
            const packet = S2C.Login.read(self.incoming_allocator.allocator(), &packet_buffer) catch |e| switch (e) {
                error.OutOfMemory => return error.RingBufferFull,
                inline else => return e,
            };
            return .{ .{ .login = packet }, allocator_rewind_mark };
        },
        .Play => {
            const packet = S2C.Play.read(self.incoming_allocator.allocator(), &packet_buffer) catch |e| switch (e) {
                error.OutOfMemory => return error.RingBufferFull,
                inline else => return e,
            };
            return .{ .{ .play = packet }, allocator_rewind_mark };
        },
    }
}

/// check if the buffer needs to be decompressed
/// returns null if the packet does not need to be decompressed,
/// otherwise returns the size after decompression
pub const PacketHeaderError = error{ PacketTooLarge, PacketTooSmall, MalformedPacket };
pub fn getDecompressedSize(self: *@This(), buffer: *S2C.ReadBuffer) PacketHeaderError!?usize {
    if (self.compression_threshold < 0) return null;

    const size_after_decompression = buffer.readVarInt() catch return error.MalformedPacket;

    return if (size_after_decompression == 0)
        null
    else if (size_after_decompression < self.compression_threshold)
        error.PacketTooSmall
    else if (size_after_decompression > 2097152)
        error.PacketTooLarge
    else
        @intCast(size_after_decompression);
}

pub const DecompressPacketError = error{PacketDecompressionError};
pub fn decompressBuffer(compressed_buffer: *S2C.ReadBuffer, decompressed_bytes_out: []u8) DecompressPacketError!void {
    var scratch_buffer: [std.compress.flate.max_window_len]u8 = undefined;

    var input: std.Io.Reader = .fixed(compressed_buffer.readRemainingBytesNonAllocating());
    var decompressor: std.compress.flate.Decompress = .init(&input, .zlib, &scratch_buffer);
    decompressor.reader.readSliceAll(decompressed_bytes_out) catch return error.PacketDecompressionError;
}

pub fn switchProtocol(self: *@This(), protocol: Protocol) void {
    std.log.scoped(.switch_protocol).debug("switching protocol to {}", .{protocol});
    std.debug.assert(self.protocol != protocol);
    self.protocol = protocol;
}

pub const CompressPacketError = error{PacketCompressionError};
pub fn compressBuffer(uncompressed_buffer: *C2S.WriteBuffer, buffer: []u8) CompressPacketError!C2S.WriteBuffer {
    var scratch_buffer: [std.compress.flate.max_window_len]u8 = undefined;

    var output: std.Io.Writer = .fixed(buffer);
    var compressor = std.compress.flate.Compress.init(&output, &scratch_buffer, .zlib, .fastest) catch return error.PacketCompressionError;
    compressor.writer.writeAll(uncompressed_buffer.backer.items) catch return error.PacketCompressionError;
    compressor.finish() catch return error.PacketCompressionError;

    return .fromOwnedSlice(output.buffered());
}

pub const SendPacketError = C2S.WritePacketError || CompressPacketError || error{ Canceled, NetworkFailure };

pub fn sendHandshakePacket(self: *@This(), packet: C2S.Handshake) SendPacketError!void {
    try self.sendPacket(.{ .handshake = packet });
}

pub fn sendLoginPacket(self: *@This(), packet: C2S.Login) SendPacketError!void {
    try self.sendPacket(.{ .login = packet });
}

pub fn sendPlayPacket(self: *@This(), packet: C2S.Play) SendPacketError!void {
    try self.sendPacket(.{ .play = packet });
}

pub fn sendPacket(self: *@This(), packet: C2S) SendPacketError!void {
    var packet_encode_buffer: [2097152]u8 = undefined;
    var packet_buffer: C2S.WriteBuffer = .initBuffer(&packet_encode_buffer);

    // write packet
    switch (packet) {
        .handshake => |handshake_packet| try handshake_packet.write(&packet_buffer),
        .login => |login_packet| try login_packet.write(&packet_buffer),
        .play => |play_packet| try play_packet.write(&packet_buffer),
    }

    std.log.scoped(.send_packet).debug("sending packet {s}", .{switch (packet) {
        inline else => |specific_packet| @tagName(specific_packet),
    }});

    const uncompressed_len = packet_buffer.backer.items.len;

    var packet_compress_buffer: [2097152]u8 = undefined;

    const compress = self.compression_threshold >= 0 and uncompressed_len >= self.compression_threshold;
    if (compress) {
        packet_buffer = try compressBuffer(&packet_buffer, &packet_compress_buffer);
    }

    // if compression_threshold >= 0, framing is [length][uncompressed size][data]
    // where a size of 0 means the data was not compressed.
    // otherwise framing is [length][data]

    var header_buf: [8]u8 = undefined;
    var header: C2S.WriteBuffer = .initBuffer(&header_buf);
    if (self.compression_threshold >= 0) {
        const uncompressed_size: i32 = if (compress) @intCast(uncompressed_len) else 0;
        header.writeVarInt(@intCast(packet_buffer.backer.items.len + C2S.WriteBuffer.getVarIntSize(uncompressed_size))) catch unreachable;
        header.writeVarInt(uncompressed_size) catch unreachable;
    } else {
        header.writeVarInt(@intCast(uncompressed_len)) catch unreachable;
    }

    std.log.scoped(.net).debug("sending {} bytes", .{packet_buffer.backer.items.len + header.backer.items.len});

    var buf: [1024]u8 = undefined;
    var writer = self.stream.writer(&buf);
    _ = writer.interface.write(header.backer.items) catch switch (writer.err.?) {
        error.Canceled => return error.Canceled,
        else => return error.NetworkFailure,
    };
    _ = writer.interface.write(packet_buffer.backer.items) catch switch (writer.err.?) {
        error.Canceled => return error.Canceled,
        else => return error.NetworkFailure,
    };
    writer.interface.flush() catch switch (writer.err.?) {
        error.Canceled => return error.Canceled,
        else => return error.NetworkFailure,
    };
}

pub const Handle = struct {
    network_task: zio.JoinHandle(Connection.Error!void),
    connection: *Connection,
    pub fn sendPacket(
        self: *@This(),
        packet: C2S,
    ) !void {
        try self.connection.outgoing_packets.push(.{ packet, undefined });
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

    pub fn disconnect(
        self: *@This(),
        _: std.Io,
        allocator: std.mem.Allocator,
    ) void {
        std.log.scoped(.net).info("sending cancel to network thread", .{});

        self.connection.wants_disconnect.store(true, .release);

        self.network_task.cancel();

        self.connection.stream.close();

        self.connection.incoming_packets.deinit(allocator);
        self.connection.outgoing_packets.deinit(allocator);
        self.connection.incoming_allocator.deinit(allocator);
        self.connection.outgoing_allocator.deinit(allocator);

        allocator.destroy(self.connection);

        std.log.scoped(.net).info("disconnected successfully", .{});
    }

    /// Spawns a new thread and initializes a new connection in that thread, then returns a handle to that connection
    pub fn init(
        _: std.Io,
        allocator: std.mem.Allocator,
        address: []const u8,
        port: u16,
        player_name: []const u8,
    ) !@This() {
        const ip: zio.net.IpAddress = try .parseIp(address, port);

        const stream: zio.net.Stream = try ip.connect(.{});
        errdefer stream.close();

        const connection = try allocator.create(Connection);
        errdefer allocator.destroy(connection);

        var incoming_packets: SpscQueue(S2CWrapper) = try .initCapacity(allocator, 1024);
        errdefer incoming_packets.deinit(allocator);
        var outgoing_packets: SpscQueue(C2SWrapper) = try .initCapacity(allocator, 1024);
        errdefer outgoing_packets.deinit(allocator);

        var incoming_allocator: RingBuffer = try .initCapacity(allocator, 1024 * 1024 * 16);
        errdefer incoming_allocator.deinit(allocator);
        var outgoing_allocator: RingBuffer = try .initCapacity(allocator, 1024 * 1024 * 16);
        errdefer outgoing_allocator.deinit(allocator);

        connection.* = .{
            .ip = ip,
            .stream = stream,

            .incoming_packets = incoming_packets,
            .outgoing_packets = outgoing_packets,

            .incoming_allocator = incoming_allocator,
            .outgoing_allocator = outgoing_allocator,
        };

        try connection.sendHandshakePacket(.{ .handshake = .{
            .version = 47,
            .address = address,
            .port = @intCast(port),
            .protocol_id = 2,
        } });
        try connection.sendLoginPacket(.{ .hello = .{
            .player_name = player_name,
        } });

        const network_task = try zio.spawn(Connection.networkThreadImpl, .{connection});
        std.log.debug("starting network task", .{});

        return .{
            .network_task = network_task,
            .connection = connection,
        };
    }
};

pub const S2CWrapper = struct { S2C.Play, RingBuffer.TailMark };
pub const C2SWrapper = struct { C2S, RingBuffer.TailMark };
