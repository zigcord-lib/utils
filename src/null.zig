const std = @import("std");
const mem = std.mem;
const json = std.json;

const Null = @This();

pub fn jsonParse(
    _: mem.Allocator,
    source: *json.Scanner,
    _: json.ParseOptions,
) !Null {
    return switch (try source.next()) {
        .null => .{},
        else => error.UnexpectedToken,
    };
}

pub fn jsonParseFromValue(_: mem.Allocator, source: json.Value, _: json.ParseOptions) !Null {
    return switch (source) {
        .null => .{},
        else => error.UnexpectedToken,
    };
}

const testing = std.testing;

test "deserialize from JSON" {
    const parsed = try json.parseFromSlice(Null, testing.allocator, "null", .{});
    defer parsed.deinit();

    try testing.expectEqual(Null{}, parsed.value);
}
