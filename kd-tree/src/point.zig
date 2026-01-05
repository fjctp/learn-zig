const std = @import("std");

pub fn Point(comptime SIZE: usize) type {
    return struct {
        coords: [SIZE]f64,

        pub fn init(coords: [SIZE]f64) Point(SIZE) {
            return Point(SIZE){ .coords = coords };
        }

        pub fn distance(self: *const Point(SIZE), other: *const Point(SIZE)) f64 {
            var sum: f64 = 0.0;
            for (self.coords, other.coords) |a, b| {
                const diff = a - b;
                sum += diff * diff;
            }
            return @sqrt(sum);
        }
    };
}

const TOLERANCE_TEST = 1.0e-6;

inline fn testInit(comptime SIZE: usize, data: [SIZE]f64) !void {
    const PointFixed = Point(SIZE);
    const p1 = PointFixed.init(data);

    // std.debug.print("Type: {}\n", .{@TypeOf(p1)});

    for (data, p1.coords) |exp, val| {
        try std.testing.expectApproxEqAbs(exp, val, TOLERANCE_TEST);
    }
}

// Test creation of Point() with varying sizes.
test "use Point" {
    try testInit(1, [_]f64{1.0});
    try testInit(2, [_]f64{ 1.0, 2.0 });
    try testInit(3, [_]f64{ 1.0, 2.0, 3.0 });
    try testInit(4, [_]f64{ 1.0, 2.0, 3.0, 4.0 });
}

// Test Point().distance() function.
test "compute distance" {
    const Point3 = Point(3);
    const p1 = Point3.init([_]f64{ 1.0, 2.0, 3.0 });
    const p2 = Point3.init([_]f64{ -1.0, 1.0, 7.0 });

    const dist = p1.distance(&p2);
    try std.testing.expectApproxEqAbs(@sqrt(21.0), dist, TOLERANCE_TEST);
}
