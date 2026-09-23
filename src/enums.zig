const std = @import("std");
const ascii = std.ascii;

pub fn fromString(comptime T: type, s: []const u8) ?T {
    const info = @typeInfo(T);
    if (info != .@"enum") @compileError("fromString only works on enums");

    inline for (info.@"enum".fields) |field| {
        if (ascii.eqlIgnoreCase(field.name, s)) return @enumFromInt(field.value);
    }

    return null;
}

const testing = std.testing;

test {
    const E = enum {
        first,
        second,
    };

    try testing.expectEqual(.first, fromString(E, "first").?);
    try testing.expectEqual(.second, fromString(E, "second").?);
    try testing.expectEqual(null, fromString(E, "unknown"));
}
