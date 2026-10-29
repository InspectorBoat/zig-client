pub const Client = union(enum) {
    idle: Idle,
    connecting: Connecting,
    game: Game,

    pub const Idle = struct {
        gpa: std.mem.Allocator,

        pub fn initConnection(
            self: *@This(),
            io: std.Io,
            allocator: std.mem.Allocator,
            name: []const u8,
            port: u16,
            player_name: []const u8,
        ) !void {
            const gpa = self.gpa;

            const connection_handle: Connection.Handle = try .init(io, allocator, name, port, player_name);

            const client: *Client = @alignCast(@fieldParentPtr("idle", self));

            client.* = .{ .connecting = .{
                .gpa = gpa,

                .connection_handle = connection_handle,
            } };
        }
    };
    pub const Connecting = struct {
        gpa: std.mem.Allocator,

        connection_handle: Connection.Handle,
    };
    pub const Game = struct {
        gpa: std.mem.Allocator,

        connection_handle: Connection.Handle,

        world: World,
        partial_tick: f64 = 0,
        tick_delay: f64 = 0,
        input_queue: InputQueue = .empty,
        input_manager: InputManager = .{},

        pub fn handleInputOnFrame(self: *@This()) void {
            const player = &self.world.player;

            while (self.input_queue.on_frame.popFront()) |input| {
                switch (input) {
                    .hand => std.debug.panic("Hand action on frame - don't do this! Queue on tick instead", .{}),
                    .movement => std.debug.panic("Movement action on frame - don't do this! Queue on tick instead", .{}),
                    .rotate => |rotation| {
                        player.base.rotation.yaw -= @as(f32, @floatFromInt(rotation.x)) / 5;
                        player.base.rotation.pitch -= @as(f32, @floatFromInt(rotation.y)) / 5;

                        player.base.rotation.pitch = @max(@min(90, player.base.rotation.pitch), -90);
                    },
                    .inventory => std.debug.panic("Inventory action on frame - don't do this! Queue on tick instead!", .{}),
                    .open_screen => std.debug.panic("Screen action on frame - don't do this! Queue on tick instead!", .{}),
                    .close_screen => std.debug.panic("Screen action on frame - don't do this! Queue on tick instead!", .{}),
                }
            }
        }

        pub fn handleInputOnTick(self: *@This(), io: std.Io, allocator: std.mem.Allocator) !void {
            const interactions = @import("interactions.zig");

            const player = &self.world.player;
            const inputs = &self.input_manager;

            try interactions.updateHotbarSlot(io, self, player);

            // If a menu was open at the start:
            // No hand inputs or movements this tick
            // Attack cooldown = 10000

            // TODO: Vanilla processes events in a different order than we do:
            // They do mouse, then keyboard
            // while ours can be interleaved (we handle immediately and queue,
            // vanilla handles on tick)
            // This is an observable difference, although *technically* it could
            // also happen on vanilla if you had really weird keybindings
            // Also, we don't distinguish the menu the input was done on,
            // So we could do an input on one menu, then have the server open another menu,
            // then that could cause an OOB
            // So we need to rethink our approach to handling keybinds,
            // and probably bring them more in line with vanilla

            // Note that it is possible to *open* the inventory
            // and perform another action on the same tick
            const menu_screen_open = self.world.menu_screen_open;

            inputs.cooldown.attack -|= 1;
            inputs.cooldown.auto_use -|= 1;

            var drop_presses: usize, var attack_presses: usize, var use_presses: usize, var pick_presses: usize = .{ 0, 0, 0, 0 };
            while (self.input_queue.on_tick.popFront()) |queued_input| {
                switch (queued_input) {
                    .hand => |hand| {
                        switch (hand) {
                            .drop => |drop| switch (drop) {
                                true => {
                                    drop_presses += 1;
                                    inputs.hand.drop = true;
                                },
                                false => inputs.hand.attack = false,
                            },
                            .attack => |attack| switch (attack) {
                                true => {
                                    attack_presses += 1;
                                    inputs.hand.attack = true;
                                },
                                false => inputs.hand.attack = false,
                            },
                            .use => |use| switch (use) {
                                true => {
                                    use_presses += 1;
                                    inputs.hand.use = true;
                                },
                                false => inputs.hand.use = false,
                            },
                            .pick => |pick| switch (pick) {
                                true => {
                                    pick_presses += 1;
                                    inputs.hand.pick = true;
                                },
                                false => inputs.hand.pick = false,
                            },
                            .hotkey => |hotkey| self.world.player.hotbar_slot = @intCast(hotkey),
                            .scroll => |scroll| {
                                self.world.player.hotbar_slot += @intCast(@mod(scroll, 9));
                                self.world.player.hotbar_slot = @mod(self.world.player.hotbar_slot, 9);
                            },
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
                    .close_screen => try interactions.closeScreen(io, allocator, self),
                    .open_screen => try interactions.openScreen(io, allocator, self),
                    .inventory => |action| {
                        try interactions.click(
                            io,
                            allocator,
                            self,
                            self.world.getMenuPtr(),
                            action,
                        );
                    },
                    .rotate => std.debug.panic("Rotated on tick - don't do this! Queue on frame instead", .{}),
                }
            }

            if (menu_screen_open) {
                attack_presses = 0;
                use_presses = 0;
                pick_presses = 0;
                inputs.hand = .{};
                inputs.movement = .{};
                inputs.cooldown.attack = 10000;
            }

            for (0..drop_presses) |_| if (inputs.movement.sprint) try interactions.dropEntireStack(io, self) else try interactions.dropSingleItem(io, self);

            if (player.item_in_use != null) {
                if (!inputs.hand.use) try interactions.stopUsingItem(io, self, player);
            } else {
                for (0..attack_presses) |_| try interactions.attack(io, self, player);
                for (0..use_presses) |_| try interactions.use(io, self, player);
                for (0..pick_presses) |_| try interactions.pick(io, self, player);
            }
            if (inputs.hand.use and self.input_manager.cooldown.auto_use == 0 and player.item_in_use == null) {
                try interactions.use(io, self, player);
            }

            if (!inputs.hand.attack) self.input_manager.cooldown.attack = 0;

            if (self.input_manager.cooldown.attack == 0 and player.item_in_use == null) {
                if (inputs.hand.attack and self.world.crosshair == .block)
                    try interactions.updateBlockMining(io, self, player, self.world.crosshair.block.block_pos, self.world.crosshair.block.dir)
                else
                    try interactions.stopMiningBlock(io, self);
            }
        }

        pub const InputManager = struct {
            cooldown: struct {
                attack: usize = 0,
                auto_use: usize = 0,
                mining: usize = 0,
                auto_jump: usize = 0,
            } = .{},
            hand: struct {
                attack: bool = false,
                use: bool = false,
                pick: bool = false,
                drop: bool = false,
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
    pub const State = std.meta.Tag(@This());

    ///Handle inputs, and tick world if necessary
    pub fn updateGame(self: *@This(), io: std.Io) !void {
        switch (self.*) {
            .game => |*game| {
                game.handleInputOnFrame();

                const ticks_elapsed, game.partial_tick = game.world.tick_timer.advance(io);
                if (ticks_elapsed == 0) return;

                // Do logging
                logTickStatistics(game.partial_tick, ticks_elapsed);

                for (0..ticks_elapsed) |_| {
                    const start: std.Io.Clock.Timestamp = .now(io, .cpu_thread);
                    defer std.log.scoped(.tick_timing_noisy).debug("tick took {} ms", .{@as(f128, start.untilNow(io).raw.nanoseconds) / std.time.ns_per_ms});

                    game.world.pick();
                    try game.handleInputOnTick(io, game.gpa);
                    try game.world.tick(io, game.gpa, game);
                }
            },
            else => unreachable,
        }
    }

    /// Handles incoming packets and frees c2s packets that have already been processed by the network thread
    /// Disconnects if connection is closed
    pub fn tickConnection(self: *@This(), io: std.Io) !void {
        const gpa, const connection_handle, const incoming_packets, const incoming_allocator = switch (self.*) {
            inline .game, .connecting => |client_state| .{
                client_state.gpa,
                client_state.connection_handle,
                &client_state.connection_handle.connection.incoming_packets,
                &client_state.connection_handle.connection.incoming_allocator,
            },
            else => unreachable,
        };

        // Read and handle incoming s2c packets
        while (true) {
            var s2c_packet, const tail_mark = incoming_packets.pop() orelse break;
            defer incoming_allocator.freeFromTail(tail_mark);

            std.log.scoped(.handle_packet_main).debug("handling packet - {s}", .{@tagName(std.meta.activeTag(s2c_packet))});

            switch (s2c_packet) {
                // Specific packet type must be comptime known, thus inline else is necessary
                inline else => |*specific_packet| {
                    // Eliminate packets at comptime to prevent a compile error
                    if (specific_packet.handle_on_network_thread) unreachable;
                    try specific_packet.handleOnMainThread(
                        io,
                        gpa,
                        switch (self.*) {
                            specific_packet.required_client_state => |*client_state| client_state,
                            else => {
                                std.log.err("expected {} for packet {s}", .{ specific_packet.required_client_state, @tagName(std.meta.activeTag(s2c_packet)) });
                                continue;
                            },
                        },
                    );
                },
            }
        }

        if (connection_handle.connection.wants_disconnect.load(.acquire)) {
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
                game.input_queue.deinit(gpa);
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

const std = @import("std");

const main = @import("main");

const Vector2xz = main.Vector2xz;
const World = main.World;
const Connection = main.network.Connection;
