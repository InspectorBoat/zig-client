const std = @import("std");
const root = @import("root");
const Vector2xy = root.Vector2xy;
const Vector2xz = root.Vector2xz;
const Connection = root.network.Connection;
const ConnectionHandle = root.network.ConnectionHandle;
const World = root.World;

pub const Client = union(enum) {
    pub const Idle = struct {
        gpa: std.mem.Allocator,

        pub fn initConnection(self: *@This(), io: std.Io, allocator: std.mem.Allocator, c2s_packet_allocator: std.mem.Allocator, name: []const u8, port: u16, player_name: []const u8) !void {
            const gpa = self.gpa;

            var connection_handle = try root.network.connection.initConnection(io, allocator, c2s_packet_allocator, name, port);
            const client: *Client = @alignCast(@fieldParentPtr("idle", self));
            client.* = .{ .connecting = .{
                .gpa = gpa,

                .connection_handle = connection_handle,
            } };
            try connection_handle.sendLoginSequence(io, player_name);
        }
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
        active_inputs: ActiveInputs = .{},

        pub fn handleInputOnFrame(self: *@This()) void {
            const player = &self.world.player;

            while (self.input_queue.on_frame.readItem()) |input| {
                switch (input) {
                    .hand => std.debug.panic("Hand action on frame - don't do this! Queue on tick instead", .{}),
                    .movement => std.debug.panic("Movement action on frame - don't do this! Queue on tick instead", .{}),
                    .rotate => |rotation| {
                        player.base.rotation.yaw -= @as(f32, @floatFromInt(rotation.x)) / 5;
                        player.base.rotation.pitch -= @as(f32, @floatFromInt(rotation.y)) / 5;

                        player.base.rotation.pitch = @max(@min(90, player.base.rotation.pitch), -90);
                    },
                    .inventory => std.debug.panic("Inventory action on frame - don't do this! Queue on tick instead!", .{}),
                }
            }
        }

        pub fn handleInputOnTick(self: *@This(), io: std.Io) !void {
            const interactions = @import("interactions.zig");
            const player = &self.world.player;
            const inputs = &self.active_inputs;

            // Cannot attack or break the same tick as stopping item usage
            var released_use_item = false;

            while (self.input_queue.on_tick.readItem()) |queued_input| {
                switch (queued_input) {
                    .hand => |hand| {
                        switch (hand) {
                            .drop => |drop| switch (drop) {
                                true => if (inputs.movement.sprint) try interactions.dropEntireStack(io, self) else try interactions.dropSingleItem(io, self),
                                false => {},
                            },
                            .main => |main| switch (main) {
                                true => {
                                    inputs.hand.main = true;
                                    if (player.item_in_use != null or released_use_item) continue;
                                    try interactions.swingHand(io, self);
                                    switch (player.crosshair) {
                                        .miss => {},
                                        .block => if (self.world.mining_state == null) try interactions.startMiningBlock(io, self, player),
                                        .entity => |entity| try interactions.attackEntity(io, self, entity.entity_network_id),
                                    }
                                },
                                false => inputs.hand.main = false,
                            },
                            .use => |use| switch (use) {
                                true => {
                                    if (player.item_in_use != null or released_use_item) continue;
                                    try interactions.use(io, self, player);
                                },
                                false => if (player.item_in_use != null) {
                                    released_use_item = true;
                                },
                            },
                            else => {},
                        }
                    },
                    .movement => |movement| {
                        switch (movement) {
                            .forward => |forward| inputs.movement.forward = forward,
                            .left => |left| inputs.movement.left = left,
                            .right => |right| inputs.movement.right = right,
                            .back => |back| inputs.movement.back = back,
                            .jump => |jump| inputs.movement.jump = jump,
                            .sprint => |sprint| inputs.movement.sprint = sprint,
                            .sneak => |sneak| inputs.movement.sneak = sneak,
                        }
                    },
                    .rotate => std.debug.panic("Rotated on tick - don't do this! Queue on frame instead", .{}),
                    .inventory => std.debug.panic("TODO!", .{}),
                }
            }

            if (inputs.hand.main) {
                try interactions.updateBlockMining(io, self, player);
            } else if (self.world.mining_state != null) {
                try interactions.stopMiningBlock(io, self);
            }
        }

        pub const ActiveInputs = struct {
            hand: struct {
                main: bool = false,
                pick: bool = false,
                use: bool = false,
            } = .{},
            movement: struct {
                forward: bool = false,
                left: bool = false,
                right: bool = false,
                back: bool = false,
                jump: bool = false,
                sneak: bool = false,
                sprint: bool = false,
                pub fn steer(self: @This()) Vector2xz(f32) {
                    return .{
                        .x = @floatFromInt(@as(i2, @intFromBool(self.left)) - @as(i2, @intFromBool(self.right))),
                        .z = @floatFromInt(@as(i2, @intFromBool(self.forward)) - @as(i2, @intFromBool(self.back))),
                    };
                }
            } = .{},
        };
    };

    pub const InputQueue = @import("InputQueue.zig");
    pub const Input = InputQueue.Input;
    pub const State = std.meta.Tag(@This());

    idle: Idle,
    connecting: Connecting,
    game: Game,

    ///Handle inputs, and tick world if necessary
    pub fn updateGame(self: *@This(), io: std.Io) !void {
        switch (self.*) {
            .game => |*game| {
                game.handleInputOnFrame();

                const ticks_elapsed, game.partial_tick = game.world.tick_timer.advance(io);
                if (ticks_elapsed == 0) return;

                // Do logging
                logTickStatistics(game.partial_tick, ticks_elapsed);

                try game.handleInputOnTick(io);
                for (0..ticks_elapsed) |_| {
                    try game.world.tick(io, game.gpa, game);
                }
            },
            else => unreachable,
        }
    }

    /// Handles incoming packets and frees c2s packets that have already been processed by the network thread
    /// Disconnects if connection is closed
    pub fn tickConnection(self: *@This(), io: std.Io) !void {
        const gpa, const connection_handle, const s2c_packet_queue, const c2s_packet_queue = switch (self.*) {
            inline .game, .connecting => |client_state| .{
                client_state.gpa,
                client_state.connection_handle,
                client_state.connection_handle.s2c_packet_queue,
                client_state.connection_handle.c2s_packet_queue,
            },
            else => unreachable,
        };

        // Read and handle incoming s2c packets
        while (true) {
            const s2c_packet_wrapper = s2c_packet_queue.claim(io) orelse break;
            defer s2c_packet_queue.release(io);

            std.log.scoped(.handle_packet_main).debug("handling packet - {s}", .{@tagName(std.meta.activeTag(s2c_packet_wrapper.packet))});

            var s2c_play_packet = s2c_packet_wrapper.packet;

            switch (s2c_play_packet) {
                // Specific packet type must be comptime known, thus inline else is necessary
                inline else => |*specific_packet| {
                    // Eliminate packets at comptime to prevent a compile error
                    if (specific_packet.handle_on_network_thread) unreachable;
                    try specific_packet.handleOnMainThread(
                        io,
                        gpa,
                        switch (self.*) {
                            specific_packet.required_client_state => |*client_state| client_state,
                            else => std.debug.panic("expected {}", .{specific_packet.required_client_state}),
                        },
                    );
                },
            }
            break;
        }

        // Free c2s packets already sent by the network thread
        while (c2s_packet_queue.reclaim(io)) |_| {}

        if (connection_handle.wants_disconnect.load(.acquire)) {
            self.disconnect(io);
        }
    }

    /// Calling this if self is .game or .connecting is always safe, because it can only be called once
    pub fn disconnect(self: *@This(), io: std.Io) void {
        switch (self.*) {
            .game => |*game| {
                const gpa = game.gpa;

                std.log.scoped(.client).debug("total delay: {d} ms", .{game.tick_delay});
                std.log.scoped(.client).info("main thread terminating connection", .{});
                game.connection_handle.disconnect(io, gpa);
                game.world.deinit(gpa);
                self.* = .{ .idle = .{
                    .gpa = gpa,
                } };
            },
            .connecting => |*connecting| {
                const gpa = connecting.gpa;

                std.log.scoped(.client).info("main thread terminating connection", .{});
                connecting.connection_handle.disconnect(io, gpa);
                self.* = .{ .idle = .{
                    .gpa = gpa,
                } };
            },
            else => unreachable,
        }
    }

    pub fn logTickStatistics(partial_tick: f64, ticks_elapsed: usize) void {
        const late_tick_threshold_ms: f64 = 10.0;
        const ms_behind = partial_tick * 50.0;
        if (ms_behind > late_tick_threshold_ms) {
            std.log.scoped(.tick_late).info("late tick: {d} ms behind", .{ms_behind});
        } else {
            std.log.scoped(.tick_on_time).debug("on time: {d} ms behind", .{ms_behind});
        }
        if (ticks_elapsed > 1) std.log.scoped(.tick_late).warn("lag spike - ticking {} times at once", .{ticks_elapsed});
    }
};
