const std = @import("std");

const Point1D = struct {
    x: f64,
};

const Point2D = struct {
    x: f64,
    y: f64,

    pub fn distance(self: Point2D) f64 {
        return @sqrt(self.x * self.x + self.y * self.y);
    }
};

fn doSomethingWithDistance(comptime T: type, item: T) void {
    std.debug.print("Type \'{}\' has distance and its value is {}.\n", .{ T, item.distance() });
    std.debug.print("\n", .{});
}

// Update a field inside a struct after its creation.
test "1_mutable_field" {
    var a = Point2D{ .x = 1.0, .y = 2.0 };
    std.debug.print("a = {}, {}\n", .{ .x = a.x, .y = a.y });

    a.x += 1.0;
    std.debug.print("a = {}, {}\n", .{ .x = a.x, .y = a.y });
    std.debug.print("\n", .{});
}

// A generic function, `doSomethingWithDistance`, that depends on implementation of distance() in a struct.
test "2_interface" {
    // Worked!
    const a = Point2D{ .x = 1.0, .y = 2.0 };
    doSomethingWithDistance(Point2D, a); // Works!

    // ERROR! No distance() in Point1D.
    // const b = Point1D{ .x = 1.0 };
    // doSomethingWithDistance(Point1D, b);
}
