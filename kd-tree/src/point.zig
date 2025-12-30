const std = @import("std");
const Allocator = std.mem.Allocator;

const Point = struct {
    coords: []f64,
    allocator: Allocator,

    pub fn init(allocator: Allocator, coords: []const f64) !Point {
        const owned = try allocator.dupe(f64, coords);
        return Point{ .coords = owned, .allocator = allocator };
    }

    pub fn deinit(self: *Point) void {
        self.allocator.free(self.coords);
    }

    pub fn distanceSquared(self: *const Point, other: *const Point) f64 {
        var sum: f64 = 0.0;
        for (self.coords, other.coords) |a, b| {
            const diff = a - b;
            sum += diff * diff;
        }
        return sum;
    }
};

const TOLERANCE_TEST = 1.0e-6;

test "use Point" {
    const gpa = std.testing.allocator;
    const expected = [_]f64{ 1.0, 2.0, 3.0 };
    var p1 = try Point.init(gpa, &expected);
    defer p1.deinit();

    for (expected, p1.coords) |exp, val| {
        try std.testing.expectApproxEqAbs(exp, val, TOLERANCE_TEST);
    }
}

test "zero distance" {
    const gpa = std.testing.allocator;
    var p1 = try Point.init(gpa, &[_]f64{ 1.0, 2.0, 3.0 });
    var p2 = try Point.init(gpa, &[_]f64{ 1.0, 2.0, 3.0 });
    defer p1.deinit();
    defer p2.deinit();

    const dist = p1.distanceSquared(&p2);
    try std.testing.expectApproxEqAbs(0.0, dist, TOLERANCE_TEST);
}

test "one distance" {
    const gpa = std.testing.allocator;
    var p1 = try Point.init(gpa, &[_]f64{ 1.0, 2.0, 3.0 });
    var p2 = try Point.init(gpa, &[_]f64{ 1.0, 2.0, 4.0 });
    defer p1.deinit();
    defer p2.deinit();

    const dist = p1.distanceSquared(&p2);
    try std.testing.expectApproxEqAbs(1.0, dist, TOLERANCE_TEST);
}
