const std = @import("std");
const connection = @import("network/connection.zig");
const Connection = @import("network/connection.zig").Connection;
const ConnectionHandle = @import("network/connection.zig").ConnectionHandle;
const World = @import("world/World.zig");
const Screen = @import("screen/Screen.zig");

pub const GameState = enum {
    Idle,
    Connecting,
    Ingame,
};

pub const Game = union(GameState) {
    pub const IdleGame = struct {
        gpa: std.mem.Allocator,
    };
    pub const ConnectingGame = struct {
        gpa: std.mem.Allocator,
        connection_handle: ConnectionHandle,
    };
    pub const IngameGame = struct {
        gpa: std.mem.Allocator,
        connection_handle: ConnectionHandle,
        world: World,
        partial_tick: f64 = 0,
        tick_delay: f64 = 0,
        ticks_elapsed: usize = 0,
    };

    Idle: IdleGame,
    Connecting: ConnectingGame,
    Ingame: IngameGame,

    pub fn initConnection(self: *@This(), name: []const u8, port: u16, allocator: std.mem.Allocator, c2s_packet_allocator: std.mem.Allocator) !void {
        switch (self.*) {
            .Idle => |idle| {
                const connection_handle = try connection.initConnection(name, port, allocator, c2s_packet_allocator);
                self.* = .{ .Connecting = .{
                    .gpa = idle.gpa,
                    .connection_handle = connection_handle,
                } };
            },
            else => unreachable,
        }
    }

    pub fn initLoginSequence(self: *@This(), player_name: []const u8) !void {
        switch (self.*) {
            .Connecting => |*connecting| {
                try connecting.connection_handle.sendLoginSequence(player_name);
            },
            else => unreachable,
        }
    }

    /// Calling this if self is .Ingame or .Connecting is always safe, because it can only be called once
    pub fn disconnect(self: *@This()) void {
        switch (self.*) {
            .Ingame => |*ingame| {
                @import("log").total_tick_delay(.{ingame.tick_delay});
                @import("log").disconnect(.{});
                ingame.connection_handle.disconnect(ingame.gpa);
                ingame.world.deinit(ingame.gpa);
                self.* = .{ .Idle = .{
                    .gpa = ingame.gpa,
                } };
            },
            .Connecting => |*connecting| {
                @import("log").disconnect(.{});
                connecting.connection_handle.disconnect(connecting.gpa);
                self.* = .{ .Idle = .{
                    .gpa = connecting.gpa,
                } };
            },
            else => unreachable,
        }
    }

    pub fn advanceTimer(self: *@This()) !void {
        switch (self.*) {
            .Ingame => |*ingame| {
                ingame.ticks_elapsed, ingame.partial_tick = ingame.world.tick_timer.advance();
            },
            else => unreachable,
        }
    }

    pub fn tickWorld(self: *@This()) !void {
        switch (self.*) {
            .Ingame => |*ingame| {
                if (ingame.ticks_elapsed > 0) {
                    if (ingame.partial_tick > 0.0001) {
                        const delay = ingame.partial_tick * @as(f64, @floatFromInt(ingame.world.tick_timer.nanosPerTick())) / std.time.ns_per_ms;
                        @import("log").delayed_tick(.{delay});
                        ingame.tick_delay += delay;
                    } else {
                        @import("log").tick_on_time(.{});
                    }
                }
                if (ingame.ticks_elapsed > 1) @import("log").lag_spike(.{ingame.ticks_elapsed});
                for (0..ingame.ticks_elapsed) |_| {
                    try ingame.world.tick(ingame, ingame.gpa);
                }
                ingame.ticks_elapsed = 0;
            },
            else => unreachable,
        }
    }

    /// Handles incoming packets and frees c2s packets that have already been processed by the network thread
    pub fn tickConnection(self: *@This()) !void {
        switch (self.*) {
            .Ingame => |game| {
                const s2c_packet_queue = game.connection_handle.s2c_packet_queue;

                // Read and handle incoming s2c packets
                while (blk: {
                    s2c_packet_queue.lock();
                    defer s2c_packet_queue.unlock();
                    break :blk s2c_packet_queue.read();
                }) |s2c_packet_wrapper| {
                    @import("log").handle_packet(.{s2c_packet_wrapper.packet});

                    var s2c_play_packet = s2c_packet_wrapper.packet;

                    switch (s2c_play_packet) {
                        // Specific packet type must be comptime known, thus inline else is necessary
                        inline else => |*specific_packet| {
                            // required to comptime prune other packets to prevent a compile error
                            if (!specific_packet.handle_on_network_thread) {
                                try specific_packet.handleOnMainThread(self, game.gpa);
                            } else unreachable;
                        },
                    }
                }

                // Free c2s packets already sent by the network thread
                const c2s_packet_queue = game.connection_handle.c2s_packet_queue;
                c2s_packet_queue.lock();
                defer c2s_packet_queue.unlock();
                while (c2s_packet_queue.free()) |_| {}
            },
            // Packets are never sent to the main thread in the connecting state
            .Connecting => |connecting| {
                // Free c2s packets already sent by the network thread
                const c2s_packet_queue = connecting.connection_handle.c2s_packet_queue;
                c2s_packet_queue.lock();
                defer c2s_packet_queue.unlock();
                while (c2s_packet_queue.free()) |_| {}
            },
            else => unreachable,
        }
    }

    /// Disconnect if we broke connection
    pub fn checkConnection(self: *@This()) void {
        switch (self.*) {
            inline .Connecting, .Ingame => |game_state| {
                if (game_state.connection_handle.disconnected.*) {
                    std.debug.print("main thread disconnecting\n", .{});
                    self.disconnect();
                }
            },
            else => unreachable,
        }
    }
};
