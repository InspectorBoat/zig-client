min: Vector3(f64),
max: Vector3(f64),

pub fn Box(comptime Element: type) type {
    return struct {
        min: Vector3(Element),
        max: Vector3(Element),

        pub const unit_cube: @This() = .{
            .min = .{ .x = 0, .y = 0, .z = 0 },
            .max = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
        };

        pub fn new(min_x: Element, min_y: Element, min_z: Element, max_x: Element, max_y: Element, max_z: Element) @This() {
            return .{
                .min = .{ .x = min_x, .y = min_y, .z = min_z },
                .max = .{ .x = max_x, .y = max_y, .z = max_z },
            };
        }

        pub fn feetAt(feet: Vector3(Element), width: Element, height: Element) @This() {
            const half_width = width / 2.0;
            return .{
                .min = .{
                    .x = feet.x - half_width,
                    .y = feet.y,
                    .z = feet.z - half_width,
                },
                .max = .{
                    .x = feet.x + half_width,
                    .y = feet.y + height,
                    .z = feet.z + half_width,
                },
            };
        }

        pub fn centeredPost(distance_from_side: Element, height: Element) @This() {
            return .{
                .min = .{
                    .x = distance_from_side,
                    .y = 0,
                    .z = distance_from_side,
                },
                .max = .{
                    .x = 1 - distance_from_side,
                    .y = height,
                    .z = 1 - distance_from_side,
                },
            };
        }

        pub fn move(self: @This(), delta: Vector3(Element)) @This() {
            return .{
                .min = .add(self.min, delta),
                .max = .add(self.max, delta),
            };
        }

        pub fn expandUniform(self: @This(), expansion: Element) @This() {
            return self.expand(.{ .x = expansion, .y = expansion, .z = expansion });
        }

        pub fn expand(self: @This(), expansion: Vector3(Element)) @This() {
            return .{
                .min = .sub(self.min, expansion),
                .max = .add(self.max, expansion),
            };
        }

        pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;
            try writer.print("{d} {d} {d} {d} {d} {d}", .{
                self.min.x,
                self.min.y,
                self.min.z,
                self.max.x,
                self.max.y,
                self.max.z,
            });
        }

        pub fn grow(self: @This(), growth: Vector3(Element)) @This() {
            return .{
                .min = .{
                    .x = if (growth.x < 0) self.min.x + growth.x else self.min.x,
                    .y = if (growth.y < 0) self.min.y + growth.y else self.min.y,
                    .z = if (growth.z < 0) self.min.z + growth.z else self.min.z,
                },
                .max = .{
                    .x = if (growth.x > 0) self.max.x + growth.x else self.max.x,
                    .y = if (growth.y > 0) self.max.y + growth.y else self.max.y,
                    .z = if (growth.z > 0) self.max.z + growth.z else self.max.z,
                },
            };
        }

        pub fn contract(self: @This(), shrink: Vector3(Element)) @This() {
            return .{
                .min = .add(self.min, shrink),
                .max = .sub(self.max, shrink),
            };
        }

        /// Touching faces do not count as intersecting
        pub fn intersects(self: @This(), other: @This()) bool {
            return self.min.x < other.max.x and self.max.x > other.min.x and
                self.min.y < other.max.y and self.max.y > other.min.y and
                self.min.z < other.max.z and self.max.z > other.min.z;
        }

        pub fn combine(self: @This(), other: @This()) @This() {
            return .{
                .min = .{
                    .x = @min(self.min.x, other.min.x),
                    .y = @min(self.min.y, other.min.y),
                    .z = @min(self.min.z, other.min.z),
                },
                .max = .{
                    .x = @max(self.max.x, other.max.x),
                    .y = @max(self.max.y, other.max.y),
                    .z = @max(self.max.z, other.max.z),
                },
            };
        }

        pub fn equals(self: @This(), other: @This()) bool {
            return self.min.x == other.min.x and
                self.min.y == other.min.y and
                self.min.z == other.min.z and
                self.max.x == other.max.x and
                self.max.y == other.max.y and
                self.max.z == other.max.z;
        }

        pub fn contains(self: @This(), pos: Vector3(Element)) bool {
            return self.min.x <= pos.x and pos.x <= self.max.x and
                self.min.y <= pos.y and pos.y <= self.max.y and
                self.min.z <= pos.z and pos.z <= self.max.z;
        }

        /// `@param mover:` the box that is moving
        ///
        /// `@param xDistance:` the distance the mover box has moved on the x-axis
        ///
        /// `@return:` The distance moved by mover. This will be equivalent to xDistance if mover and this are already colliding or did not colide at all
        ///
        /// ### Possibilities:
        /// #### Cannot collide:
        /// - mover and this cannot collide
        /// ```
        ///  |-------|
        ///  | mover |
        ///  |-------|
        ///                          |--------|
        ///                          |  self  |
        ///                          |--------|
        /// ```
        /// - returns `distance`
        ///
        ///
        /// #### Mover moves to the right and collides:
        /// - mover is completely to the left (negative x) of self
        /// - distance is positive (moving to the left)
        /// - the two boxes intersect in the Y and Z axis
        ///
        /// ```
        ///  |-------|                 |--------|
        ///  | mover | -> distance ->  |  self  |
        ///  |-------|                 |--------|
        ///          ^                 ^
        ///      mover.max.x       self.min.x
        /// ```
        /// - returns `distance` or `self.min.x - mover.max.x`, whichever is lesser (smaller magnitude)
        ///
        ///
        /// #### Mover moves to the left and collides:
        /// - mover is completely to the right (positive x) of self
        /// - distance is negative (moving to the left)
        /// - the two boxes intersect in the Y and Z axis
        /// ```
        ///  |--------|                |-------|
        ///  |  self  | <- distance <- | mover |
        ///  |--------|                |-------|
        ///           ^                ^
        ///       self.max.x       mover.min.x
        /// ```
        /// - returns `distance` or `self.max.x - mover.min.x`, whichever is greater (smaller magnitude)
        ///
        ///
        /// #### Already colliding:
        /// - mover and self are already colliding
        /// ```
        /// |------------|
        /// |            |
        /// |    this    |
        /// |         |--|------|
        /// |---------|--|      |
        ///           |  mover  |
        ///           |         |
        ///           |---------|
        /// ```
        /// - returns `distance`
        ///
        /// This last case is not programmed as an explicit case:
        /// it is merely a side effect of how the previous two cases function
        ///
        pub fn blockXAxisMovingHitbox(self: @This(), mover: @This(), distance: Element) Element {
            if (@typeInfo(Element) != .float) @compileError("Box.blockXAxisMovingHitbox is only available for floating point numbers!");

            // cannot collide
            if (mover.max.y <= self.min.y or mover.min.y >= self.max.y or mover.max.z <= self.min.z or mover.min.z >= self.max.z) {
                return distance;
            }
            // colliding by moving +x
            else if (distance > 0 and mover.max.x <= self.min.x) {
                const collision_distance = self.min.x - mover.max.x;
                if (collision_distance < distance) return collision_distance;
            }
            // colliding by moving -x
            else if (distance < 0 and mover.min.x >= self.max.x) {
                const collision_distance = self.max.x - mover.min.x;
                if (collision_distance > distance) return collision_distance;
            }
            // did not collide
            return distance;
        }

        pub fn blockYAxisMovingHitbox(self: @This(), mover: @This(), distance: Element) Element {
            if (@typeInfo(Element) != .float) @compileError("Box.blockYAxisMovingHitbox is only available for floating point numbers!");

            // cannot collide
            if (mover.max.x <= self.min.x or mover.min.x >= self.max.x or mover.max.z <= self.min.z or mover.min.z >= self.max.z) {
                return distance;
            }
            // colliding by moving +x
            else if (distance > 0 and mover.max.y <= self.min.y) {
                const collision_distance = self.min.y - mover.max.y;
                if (collision_distance < distance) return collision_distance;
            }
            // colliding by moving -x
            else if (distance < 0 and mover.min.y >= self.max.y) {
                const collision_distance = self.max.y - mover.min.y;
                if (collision_distance > distance) return collision_distance;
            }
            // did not collide
            return distance;
        }

        pub fn blockZAxisMovingHitbox(self: @This(), mover: @This(), distance: Element) Element {
            if (@typeInfo(Element) != .float) @compileError("Box.blockZAxisMovingHitbox is only available for floating point numbers!");

            // cannot collide
            if (mover.max.x <= self.min.x or mover.min.x >= self.max.x or mover.max.y <= self.min.y or mover.min.y >= self.max.y) {
                return distance;
            }
            // colliding by moving +x
            else if (distance > 0 and mover.max.z <= self.min.z) {
                const collision_distance = self.min.z - mover.max.z;
                if (collision_distance < distance) return collision_distance;
            }
            // colliding by moving -x
            else if (distance < 0 and mover.min.z >= self.max.z) {
                const collision_distance = self.max.z - mover.min.z;
                if (collision_distance > distance) return collision_distance;
            }
            // did not collide
            return distance;
        }
    };
}

const std = @import("std");

const main = @import("main");

const Vector3 = main.Vector3;
