const std = @import("std");

const Point = @import("point.zig").Point;

pub fn KdNode(comptime K: usize) type {
    return struct {
        point: Point(K),
        left: ?*KdNode(K), // Can be null or a pointer to KdNodeN
        right: ?*KdNode(K), // Can be null or a pointer to KdNodeN

        pub fn init(coord: Point(K)) KdNode(K) {
            return .{ .point = coord, .left = null, .right = null };
        }

        pub fn deinit(self: *KdNode(K), alloc: std.mem.Allocator) void {
            if (self.left) |val| {
                val.deinit(alloc);
            }
            if (self.right) |val| {
                val.deinit(alloc);
            }

            alloc.destroy(self);
        }

        pub fn print(self: *const KdNode(K)) void {
            std.debug.print("{any}\n", .{self});
        }

        pub fn insert(
            self: ?*KdNode(K),
            point: Point(K),
            depth: usize,
            alloc: std.mem.Allocator,
        ) !*KdNode(K) {
            if (self == null) {
                const newNode = try alloc.create(KdNode(K));
                newNode.* = KdNode(K).init(point);
                return newNode;
            }

            const axis = depth % K;
            const n = self.?;

            if (point.coords[axis] < n.point.coords[axis]) {
                n.left = try KdNode(K).insert(n.left, point, depth + 1, alloc);
            } else {
                n.right = try KdNode(K).insert(n.right, point, depth + 1, alloc);
            }

            return n;
        }

        pub fn findNearest(
            self: *const KdNode(K),
            target: *const Point(K),
            depth: usize,
            best: *Point(K),
            best_dist: *f64,
        ) void {
            const dist = target.distance(&self.point);
            if (dist < best_dist.*) {
                // Found nearer point.
                best.* = self.point;
                best_dist.* = dist;
            }

            const axis = depth % K;
            const diff = target.coords[axis] - self.point.coords[axis];

            // Target is on the left partition if diff < 0.
            const first = if (diff < 0) self.left else self.right;
            const second = if (diff < 0) self.right else self.left;

            // Check the 1st partition.
            if (first) |child| {
                child.findNearest(target, depth + 1, best, best_dist);
            }

            // Check the 2nd partition if the target is closer than the best point.
            if (@sqrt(diff * diff) < best_dist.*) {
                if (second) |child| {
                    child.findNearest(target, depth + 1, best, best_dist);
                }
            }
        }
    };
}

const TOLERANCE_TEST = std.math.floatEps(f64);

test "use KdNode" {
    const K = 3;

    const p = Point(K).init([_]f64{ 1.0, 2.0, 3.0 });
    const root = KdNode(K).init(p);

    for (p.coords, root.point.coords) |a, b|
        try std.testing.expectApproxEqAbs(a, b, TOLERANCE_TEST);
    try std.testing.expectEqual(null, root.left);
    try std.testing.expectEqual(null, root.right);
}

test "insert Point" {
    // Get allocator.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Define test data.
    const K = 3;
    const p1 = Point(K).init([_]f64{ 1.0, 2.0, 3.0 });
    const p2 = Point(K).init([_]f64{ -1.0, 2.0, 3.0 });

    // Create uut.
    var root = try KdNode(K).insert(null, p1, 0, allocator);
    defer root.deinit(allocator);
    // root = try root.insert(p2, 0, allocator);
    _ = try root.insert(p2, 0, allocator);

    // root.print();

    // Check result.
    try std.testing.expect(root.left != null);
    for (root.left.?.point.coords, p2.coords) |a, b|
        try std.testing.expectApproxEqAbs(b, a, TOLERANCE_TEST);
    try std.testing.expect(root.left.?.left == null);
    try std.testing.expect(root.left.?.right == null);

    try std.testing.expect(root.right == null);
}

test "find findNearest Point" {
    // Get allocator.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Define test data.
    const K = 2;
    const target = Point(K).init([_]f64{ 2.0, 6.0 });
    const points = [_]Point(K){ Point(K).init([_]f64{ -1.0, -1.0 }), Point(K).init([_]f64{ 0.0, 0.0 }), Point(K).init([_]f64{ 1.0, 2.0 }), Point(K).init([_]f64{ 2.0, 4.0 }) };

    // Create uut.
    var root = try KdNode(K).insert(null, points[0], 0, allocator);
    defer root.deinit(allocator);
    for (points[1..points.len]) |p| {
        root = try root.insert(p, 0, allocator);
    }

    // Test findNearest().
    var best = Point(K).init([_]f64{ -3.0, 4.0 });
    var best_dist: f64 = std.math.inf(f64);
    root.findNearest(&target, 0, &best, &best_dist);

    for (points[3].coords, best.coords) |a, b|
        try std.testing.expectApproxEqAbs(a, b, TOLERANCE_TEST);
    try std.testing.expectApproxEqAbs(2.0, best_dist, TOLERANCE_TEST);
}
