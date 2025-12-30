const std = @import("std");
const Allocator = std.mem.Allocator;

const Point = @import("point.zig").Point;

const KdNode = struct {
    point: Point,
    left: ?*KdNode,
    right: ?*KdNode,
};

pub const KdTree = struct {
    root: ?*KdNode,
    k: usize,
    allocator: Allocator,

    pub fn init(allocator: Allocator, k: usize) KdTree {
        return KdTree{
            .root = null,
            .k = k,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *KdTree) void {
        self.freeNode(self.root);
    }

    fn freeNode(self: *KdTree, node: ?*KdNode) void {
        if (node) |n| {
            self.freeNode(n.left);
            self.freeNode(n.right);
            n.point.deinit();
            self.allocator.destroy(n);
        }
    }

    pub fn insert(self: *KdTree, coords: []const f64) !void {
        if (coords.len != self.k) return error.DimensionMismatch;
        const point = try Point.init(self.allocator, coords);
        self.root = try self.insertRecursive(self.root, point, 0);
    }

    fn insertRecursive(self: *KdTree, node: ?*KdNode, point: Point, depth: usize) !*KdNode {
        if (node == null) {
            const new_node = try self.allocator.create(KdNode);
            new_node.* = KdNode{
                .point = point,
                .left = null,
                .right = null,
            };
            return new_node;
        }

        const n = node.?;
        const axis = depth % self.k;

        if (point.coords[axis] < n.point.coords[axis]) {
            n.left = try self.insertRecursive(n.left, point, depth + 1);
        } else {
            n.right = try self.insertRecursive(n.right, point, depth + 1);
        }

        return n;
    }

    pub fn nearest(self: *KdTree, target: []const f64) !?Point {
        if (target.len != self.k) return error.DimensionMismatch;
        if (self.root == null) return null;

        var target_point = try Point.init(self.allocator, target);
        defer target_point.deinit();

        var best = self.root.?.point;
        var best_dist = target_point.distanceSquared(&best);

        self.nearestRecursive(self.root.?, &target_point, 0, &best, &best_dist);

        return try Point.init(self.allocator, best.coords);
    }

    fn nearestRecursive(
        self: *KdTree,
        node: *KdNode,
        target: *const Point,
        depth: usize,
        best: *Point,
        best_dist: *f64,
    ) void {
        const dist = target.distanceSquared(&node.point);
        if (dist < best_dist.*) {
            best.* = node.point;
            best_dist.* = dist;
        }

        const axis = depth % self.k;
        const diff = target.coords[axis] - node.point.coords[axis];

        const first = if (diff < 0) node.left else node.right;
        const second = if (diff < 0) node.right else node.left;

        if (first) |child| {
            self.nearestRecursive(child, target, depth + 1, best, best_dist);
        }

        if (diff * diff < best_dist.*) {
            if (second) |child| {
                self.nearestRecursive(child, target, depth + 1, best, best_dist);
            }
        }
    }

    pub fn rebalance(self: *KdTree) !void {
        var points = std.ArrayList(Point).init(self.allocator);
        defer points.deinit();

        try self.collectPoints(self.root, &points);
        self.freeNode(self.root);
        self.root = try self.buildBalanced(points.items, 0);
    }

    fn collectPoints(self: *KdTree, node: ?*KdNode, points: *std.ArrayList(Point)) !void {
        if (node) |n| {
            try points.append(n.point);
            try self.collectPoints(n.left, points);
            try self.collectPoints(n.right, points);
        }
    }

    fn buildBalanced(self: *KdTree, points: []Point, depth: usize) !?*KdNode {
        if (points.len == 0) return null;

        const axis = depth % self.k;
        std.mem.sort(Point, points, axis, struct {
            fn lessThan(ax: usize, a: Point, b: Point) bool {
                return a.coords[ax] < b.coords[ax];
            }
        }.lessThan);

        const median = points.len / 2;
        const node = try self.allocator.create(KdNode);
        node.* = KdNode{
            .point = points[median],
            .left = try self.buildBalanced(points[0..median], depth + 1),
            .right = try self.buildBalanced(points[median + 1 ..], depth + 1),
        };

        return node;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var tree = KdTree.init(allocator, 2);
    defer tree.deinit();

    try tree.insert(&[_]f64{ 2.0, 3.0 });
    try tree.insert(&[_]f64{ 5.0, 4.0 });
    try tree.insert(&[_]f64{ 9.0, 6.0 });
    try tree.insert(&[_]f64{ 4.0, 7.0 });
    try tree.insert(&[_]f64{ 8.0, 1.0 });
    try tree.insert(&[_]f64{ 7.0, 2.0 });

    const target = &[_]f64{ 5.0, 5.0 };
    if (try tree.nearest(target)) |nearest_val| {
        var nearest = nearest_val;
        defer nearest.deinit();
        std.debug.print("Nearest to [{d}, {d}]: [{d}, {d}]\n", .{
            target[0], target[1], nearest.coords[0], nearest.coords[1],
        });
    }

    try tree.rebalance();
    std.debug.print("Tree rebalanced!\n", .{});

    if (try tree.nearest(target)) |nearest_val| {
        var nearest = nearest_val;
        defer nearest.deinit();
        std.debug.print("Nearest after rebalance: [{d}, {d}]\n", .{
            nearest.coords[0], nearest.coords[1],
        });
    }
}
