const std = @import("std");

const Person = struct {
    name: []const u8, // string is a unsigned int8 array in Zig.

    pub fn printDefault(self: Person, greeting: ?[]const u8) void {
        const prefix = greeting orelse "Hello!";

        std.debug.print("{s}, {s}\n", .{ prefix, self.name });
    }

    pub fn printIf(self: Person, greeting: ?[]const u8) void {
        if (greeting) |prefix| {
            std.debug.print("{s}, {s}\n", .{ prefix, self.name });
        } else {
            std.debug.print("greeting is null\n", .{});
        }
    }

    pub fn printError(self: Person, greeting: ?[]const u8) !void {
        const prefix = greeting orelse return error.GreetingNotFound;

        std.debug.print("{s}, {s}\n", .{ prefix, self.name });
    }

    pub fn printUnsafe(self: Person, greeting: ?[]const u8) void {
        std.debug.print("{s}, {s}\n", .{ greeting.?, self.name });
    }
};

// Different way to unwrap optional, which is null.
test "Test optional" {
    const p1 = Person{ .name = "John" };

    p1.printDefault(null);

    p1.printIf(null);

    try std.testing.expectError(error.GreetingNotFound, p1.printError(null));

    p1.printUnsafe("Not safe");
    // p1.printUnsafe(null); // Panic!
}
