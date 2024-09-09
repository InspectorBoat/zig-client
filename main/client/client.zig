const std = @import("std");
const root = @import("root");
const Vector2xy = root.Vector2xy;
const Connection = root.network.Connection;
const ConnectionHandle = root.network.ConnectionHandle;
const World = root.World;

pub const Client = union(enum) {
    pub const Idle = struct {
        gpa: std.mem.Allocator,
    };
    pub const Connecting = struct {
        gpa: std.mem.Allocator,
        connection_handle: ConnectionHandle,
    };
    pub const Game = struct {
        gpa: std.mem.Allocator,
        connection_handle: ConnectionHandle,
        world: World,
        partial_tick: f64 = 0,
        tick_delay: f64 = 0,
        input_queue: InputQueue = .{},
        active_inputs: struct {
            hand: struct {
                main: bool = false,
                pick: bool = false,
                use: bool = false,
            } = .{},
            movement: struct {} = .{},
        } = .{},
    };

    pub const InputQueue = @import("InputQueue.zig");
    pub const Input = InputQueue.Input;

    pub const State = std.meta.Tag(@This());

    idle: Idle,
    connecting: Connecting,
    game: Game,

    pub fn initConnection(self: *@This(), name: []const u8, port: u16, allocator: std.mem.Allocator, c2s_packet_allocator: std.mem.Allocator) !void {
        switch (self.*) {
            .idle => |idle| {
                const connection_handle = try root.network.connection.initConnection(name, port, allocator, c2s_packet_allocator);
                self.* = .{ .connecting = .{
                    .gpa = idle.gpa,
                    .connection_handle = connection_handle,
                } };
            },
            else => unreachable,
        }
    }

    pub fn initLoginSequence(self: *@This(), player_name: []const u8) !void {
        switch (self.*) {
            .connecting => |*connecting| {
                try connecting.connection_handle.sendLoginSequence(player_name);
            },
            else => unreachable,
        }
    }

    /// Calling this if self is .game or .connecting is always safe, because it can only be called once
    pub fn disconnect(self: *@This()) void {
        switch (self.*) {
            .game => |*game| {
                @import("log").total_tick_delay(.{game.tick_delay});
                @import("log").disconnect(.{});
                game.connection_handle.disconnect(game.gpa);
                game.world.deinit(game.gpa);
                self.* = .{ .idle = .{
                    .gpa = game.gpa,
                } };
            },
            .connecting => |*connecting| {
                @import("log").disconnect(.{});
                connecting.connection_handle.disconnect(connecting.gpa);
                self.* = .{ .idle = .{
                    .gpa = connecting.gpa,
                } };
            },
            else => unreachable,
        }
    }

    /// Returns the number of ticks elapsed since last call
    pub fn advanceTimer(self: *@This()) !usize {
        switch (self.*) {
            .game => |*game| {
                const ticks_elapsed, game.partial_tick = game.world.tick_timer.advance();
                return ticks_elapsed;
            },
            else => unreachable,
        }
    }

    pub fn tickWorld(self: *@This()) !void {
        switch (self.*) {
            .game => |*game| {
                const ticks_elapsed = try self.advanceTimer();
                if (ticks_elapsed == 0) return;

                // Do logging
                if (game.partial_tick > 0.0001) {
                    const nanos_per_tick: f64 = @floatFromInt(game.world.tick_timer.nanosPerTick());
                    const ms_per_tick = nanos_per_tick / std.time.ns_per_ms;
                    const delay = game.partial_tick * ms_per_tick;
                    @import("log").delayed_tick(.{delay});
                    game.tick_delay += delay;
                } else {
                    @import("log").tick_on_time(.{});
                }
                if (ticks_elapsed > 1) @import("log").lag_spike(.{ticks_elapsed});

                try self.handleInputOnTick();
                for (0..ticks_elapsed) |_| {
                    try game.world.tick(game, game.gpa);
                }
            },
            else => unreachable,
        }
    }

    pub fn handleInputOnTick(self: *@This()) !void {
        switch (self.*) {
            .game => |*game| {
                const player = &game.world.player;
                const player_input = &player.input;
                while (game.input_queue.on_tick.readItem()) |input| {
                    switch (input) {
                        .hand => |hand| {
                            switch (hand) {
                                .drop => |drop| if (drop) try game.connection_handle.sendPlayPacket(.{ .player_hand_action = .{ .action = .drop_single_item, .block_pos = .origin(), .face = .Down } }),
                                .main => |main| switch (main) {
                                    true => {
                                        try game.connection_handle.sendPlayPacket(.{ .hand_swing = .{} });
                                        switch (player.crosshair) {
                                            .block => |block| {
                                                game.world.mining_state = .{ .target_block_pos = block.block_pos, .face = block.dir };
                                                try game.connection_handle.sendPlayPacket(.{ .player_hand_action = .{
                                                    .action = .start_breaking_block,
                                                    .face = block.dir,
                                                    .block_pos = block.block_pos,
                                                } });
                                            },
                                            .entity => |entity| {
                                                try game.connection_handle.sendPlayPacket(.{ .player_interact_entity = .{
                                                    .action = .attack,
                                                    .target_network_id = entity.entity_network_id,
                                                } });
                                            },
                                            .miss => {},
                                        }
                                    },
                                    false => {},
                                },
                                else => {},
                            }
                        },
                        .movement => |movement| {
                            switch (movement) {
                                .forward => |forward| player_input.forward = forward,
                                .left => |left| player_input.left = left,
                                .right => |right| player_input.right = right,
                                .back => |back| player_input.back = back,
                                .jump => |jump| player_input.jump = jump,
                                .sprint => |sprint| player_input.sprint = sprint,
                                .sneak => |sneak| player_input.sneak = sneak,
                            }
                        },
                        .rotate => std.debug.panic("Rotated on tick - don't do this! Queue on frame instead", .{}),
                        .inventory => std.debug.panic("TODO!", .{}),
                    }
                }
            },
            else => unreachable,
        }
    }

    pub fn handleInputOnFrame(self: *@This()) !void {
        switch (self.*) {
            .game => |*game| {
                const player = &game.world.player;

                while (game.input_queue.on_frame.readItem()) |input| {
                    switch (input) {
                        .hand => std.debug.panic("Hand action on frame - don't do this! Queue on tick instead", .{}),
                        .movement => std.debug.panic("Movement action on frame - don't do this! Queue on tick instead", .{}),
                        .rotate => |rotation| {
                            player.base.rotation.yaw -= @as(f32, @floatFromInt(rotation.x)) / 5;
                            player.base.rotation.pitch -= @as(f32, @floatFromInt(rotation.y)) / 5;
                        },
                        .inventory => std.debug.panic("Inventory action on frame - don't do this! Queue on tick instead!", .{}),
                    }
                }
            },
            else => unreachable,
        }
    }

    /// Handles incoming packets and frees c2s packets that have already been processed by the network thread
    pub fn tickConnection(self: *@This()) !void {
        const s2c_packet_queue, const c2s_packet_queue, const allocator = switch (self.*) {
            inline .game, .connecting => |client_state| .{ client_state.connection_handle.s2c_packet_queue, client_state.connection_handle.c2s_packet_queue, client_state.gpa },
            else => unreachable,
        };

        // Read and handle incoming s2c packets
        while (blk: {
            s2c_packet_queue.lock();
            break :blk s2c_packet_queue.read();
        }) |s2c_packet_wrapper| : (s2c_packet_queue.unlock()) {
            @import("log").handle_packet(.{s2c_packet_wrapper.packet});

            var s2c_play_packet = s2c_packet_wrapper.packet;

            switch (s2c_play_packet) {
                // Specific packet type must be comptime known, thus inline else is necessary
                inline else => |*specific_packet| {
                    // Eliminate packets at comptime to prevent a compile error
                    if (specific_packet.handle_on_network_thread) unreachable;

                    try specific_packet.handleOnMainThread(
                        switch (self.*) {
                            specific_packet.required_client_state => |*client_state| client_state,
                            else => return error.BadClientState,
                        },
                        allocator,
                    );
                },
            }
        } else {
            s2c_packet_queue.unlock();
        }

        // Free c2s packets already sent by the network thread
        {
            c2s_packet_queue.lock();
            defer c2s_packet_queue.unlock();
            while (c2s_packet_queue.free()) |_| {}
        }

        self.checkConnection();
    }

    /// Disconnect if we broke connection
    pub fn checkConnection(self: *@This()) void {
        switch (self.*) {
            inline .connecting, .game => |game_state| {
                if (game_state.connection_handle.disconnected.*) {
                    std.debug.print("main thread disconnecting\n", .{});
                    self.disconnect();
                }
            },
            else => unreachable,
        }
    }
};
