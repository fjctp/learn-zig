const std = @import("std");
const Allocator = std.mem.Allocator;

const Point = @import("point.zig").Point;
const KdNode = @import("kdNode.zig").KdNode;

pub fn KdTree(comptime K: usize) type {
    return struct {
        root: ?*KdNode(K),
        allocator: Allocator,

        pub fn init(allocator: Allocator) KdTree(K) {
            return .{
                .root = null,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *KdTree(K)) void {
            if (self.root) |node| {
                node.deinit(self.allocator);
            }
        }

        pub fn insert(self: *KdTree(K), point: Point(K)) !void {
            if (self.root) |node| {
                _ = try node.insert(point, 0, self.allocator);
                return;
            }
            self.root = try KdNode(K).insert(null, point, 0, self.allocator);
        }

        pub fn findNearest(self: *KdTree(K), target: Point(K)) ?Point(K) {
            if (self.root) |node| {
                var best = node.point;
                var best_dist = target.distance(&best);
                node.findNearest(&target, 0, &best, &best_dist);
                return best;
            }
            return null;
        }
    };
}

const TOLERANCE_TEST = std.math.floatEps(f64);

test "use KdTree" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const KdTree2D = KdTree(2);
    const Point2D = Point(2);

    var tree = KdTree2D.init(allocator);
    defer tree.deinit();

    try tree.insert(Point2D.init([_]f64{ 2.0, 3.0 }));
    try tree.insert(Point2D.init([_]f64{ 5.0, 4.0 }));
    try tree.insert(Point2D.init([_]f64{ 9.0, 6.0 }));
    try tree.insert(Point2D.init([_]f64{ 4.0, 7.0 }));
    try tree.insert(Point2D.init([_]f64{ 8.0, 1.0 }));
    try tree.insert(Point2D.init([_]f64{ 7.0, 2.0 }));

    const target = Point(2).init([_]f64{ 5.0, 5.0 });
    if (tree.findNearest(target)) |nearest| {
        for ([_]f64{ 5.0, 4.0 }, nearest.coords) |a, b|
            try std.testing.expectApproxEqAbs(a, b, TOLERANCE_TEST);
    } else {
        return error.PointNotFound;
    }
}

test "rebalance KdTree" {
    if (@import("builtin").os.tag == .linux) return error.SkipZigTest;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const KdTree2D = KdTree(2);
    const Point2D = Point(2);

    var tree = KdTree2D.init(allocator);
    defer tree.deinit();

    try tree.insert(Point2D.init([_]f64{ 2.0, 3.0 }));
    try tree.insert(Point2D.init([_]f64{ 5.0, 4.0 }));
    try tree.insert(Point2D.init([_]f64{ 9.0, 6.0 }));
    try tree.insert(Point2D.init([_]f64{ 4.0, 7.0 }));
    try tree.insert(Point2D.init([_]f64{ 8.0, 1.0 }));
    try tree.insert(Point2D.init([_]f64{ 7.0, 2.0 }));
    try tree.rebalance();

    const target = Point(2).init([_]f64{ 5.0, 5.0 });
    if (tree.findNearest(target)) |nearest| {
        for ([_]f64{ 5.0, 4.0 }, nearest.coords) |a, b|
            try std.testing.expectApproxEqAbs(a, b, TOLERANCE_TEST);
    } else {
        return error.PointNotFound;
    }
}
