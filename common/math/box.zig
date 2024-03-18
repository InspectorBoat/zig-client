const std = @import("std");
const Vector3 = @import("../math/vector.zig").Vector3;
const HitResult = @import("./hitresult.zig").HitResult;
const Direction = @import("../math/direction.zig").Direction;

min: Vector3(f64),
max: Vector3(f64),

pub fn Box(comptime Element: type) type {
    return struct {
        min: Vector3(Element),
        max: Vector3(Element),

        pub fn move(self: @This(), delta: Vector3(Element)) @This() {
            return @This(){
                .min = self.min.add(delta),
                .max = self.max.add(delta),
            };
        }

        pub fn expandUniform(self: @This(), expansion: Element) @This() {
            return self.expand(.{ .x = expansion, .y = expansion, .z = expansion });
        }

        pub fn expand(self: @This(), expansion: Vector3(Element)) @This() {
            return @This(){
                .min = self.min.sub(expansion),
                .max = self.max.add(expansion),
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
            return @This(){
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

        pub fn rayTrace(self: *@This(), from: Vector3(Element), to: Vector3(Element)) ?HitResult {
            if (@typeInfo(Element) != .Float) @compileError("Box.rayTrace is only available for floating point numbers!");

            const min_x_pos = @This().traceToPlane(from, to, .x, self.min.x);
            const max_x_pos = @This().traceToPlane(from, to, .x, self.max.x);
            const min_y_pos = @This().traceToPlane(from, to, .y, self.min.y);
            const max_y_pos = @This().traceToPlane(from, to, .y, self.max.y);
            const min_z_pos = @This().traceToPlane(from, to, .z, self.min.z);
            const max_z_pos = @This().traceToPlane(from, to, .z, self.max.z);

            var hit: ?Vector3(Element) = null;
            var hit_dir: Direction = null;

            if (min_x_pos) |min_x_hit| {
                // check to see hit is valid
                if (self.isWithinY(min_x_hit) and self.isWithinZ(min_x_hit)) {
                    // check that this hit is closer
                    if (hit == null or from.distance_squared(min_x_hit) < from.distance_squared(hit.?)) {
                        hit = min_x_hit;
                        hit_dir = .West;
                    }
                }
            }
            if (max_x_pos) |max_x_hit| {
                // check to see hit is valid
                if (self.isWithinY(max_x_hit) and self.isWithinZ(max_x_hit)) {
                    // check that this hit is closer
                    if (hit == null or from.distance_squared(max_x_hit) < from.distance_squared(hit.?)) {
                        hit = max_x_hit;
                        hit_dir = .West;
                    }
                }
            }

            if (min_y_pos) |min_y_hit| {
                // check to see hit is valid
                if (self.isWithinX(min_y_hit) and self.isWithinZ(min_y_hit)) {
                    // check that this hit is closer
                    if (hit == null or from.distance_squared(min_y_hit) < from.distance_squared(hit.?)) {
                        hit = min_y_hit;
                        hit_dir = .Down;
                    }
                }
            }
            if (max_y_pos) |max_y_hit| {
                // check to see hit is valid
                if (self.isWithinX(max_y_hit) and self.isWithinZ(max_y_hit)) {
                    // check that this hit is closer
                    if (hit == null or from.distance_squared(max_y_hit) < from.distance_squared(hit.?)) {
                        hit = max_y_hit;
                        hit_dir = .Up;
                    }
                }
            }

            if (min_z_pos) |min_z_hit| {
                // check to see hit is valid
                if (self.isWithinX(min_z_hit) and self.isWithinY(min_z_hit)) {
                    // check that this hit is closer
                    if (hit == null or from.distance_squared(min_z_hit) < from.distance_squared(hit.?)) {
                        hit = min_z_hit;
                        hit_dir = .North;
                    }
                }
            }
            if (max_z_pos) |max_z_hit| {
                // check to see hit is valid
                if (self.isWithinX(max_z_hit) and self.isWithinY(max_z_hit)) {
                    // check that this hit is closer
                    if (hit == null or from.distance_squared(max_z_hit) < from.distance_squared(hit.?)) {
                        hit = max_z_hit;
                        hit_dir = .South;
                    }
                }
            }

            return HitResult{
                .hit_pos = hit,
            };
        }

        pub fn isWithinX(self: *@This(), pos: Vector3(Element)) bool {
            return self.min.x <= pos.x and pos.x <= self.max.x;
        }

        pub fn isWithinY(self: *@This(), pos: Vector3(Element)) bool {
            return self.min.y <= pos.y and pos.y <= self.max.y;
        }

        pub fn isWithinZ(self: *@This(), pos: Vector3(Element)) bool {
            return self.min.z <= pos.z and pos.z <= self.max.z;
        }

        /// Given an origin vector3 and a target vector3, travels
        /// from the origin vector3 to the target vector3 until
        /// colliding with the given plane
        pub fn traceToPlane(from: Vector3(Element), to: Vector3(Element), comptime axis: enum { x, y, z }, pos: Element) ?Vector3(Element) {
            if (@typeInfo(Element) != .Float) @compileError("Box.traceToPlane is only available for floating point numbers!");

            const delta = from.sub(to);
            const ray_progress = switch (axis) {
                .x => x: {
                    if (delta.x * delta.x < 0.0001 * 0.0001) {
                        return null;
                    } else {
                        break :x (pos - from.x) / delta.x;
                    }
                },
                .y => y: {
                    if (delta.y * delta.y < 0.0001 * 0.0001) {
                        return null;
                    } else {
                        break :y (pos - from.y) / delta.y;
                    }
                },
                .y => z: {
                    if (delta.z * delta.z < 0.0001 * 0.0001) {
                        return null;
                    } else {
                        break :z (pos - from.z) / delta.z;
                    }
                },
            };
            if (ray_progress < 0 or ray_progress > 1) return null;
            return from.add(delta.scaleUniform(ray_progress));
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
            if (@typeInfo(Element) != .Float) @compileError("Box.blockXAxisMovingHitbox is only available for floating point numbers!");

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
            if (@typeInfo(Element) != .Float) @compileError("Box.blockYAxisMovingHitbox is only available for floating point numbers!");

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
            if (@typeInfo(Element) != .Float) @compileError("Box.blockZAxisMovingHitbox is only available for floating point numbers!");

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
