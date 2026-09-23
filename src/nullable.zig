const std = @import("std");
const mem = std.mem;
const json = std.json;

pub fn Nullable(comptime T: type) type {
    return union(enum) {
        const Self = @This();

        missing,
        null,
        value: T,

        pub fn get(self: Self) ?T {
            return switch (self) {
                .value => |v| v,
                else => null,
            };
        }

        pub fn jsonParse(
            allocator: mem.Allocator,
            source: *json.Scanner,
            options: json.ParseOptions,
        ) !Self {
            if (try source.peekNextTokenType() == .null) {
                _ = try source.next();
                return .null;
            }

            return .{
                .value = try json.innerParse(
                    T,
                    allocator,
                    source,
                    options,
                ),
            };
        }

        pub fn jsonParseFromValue(
            allocator: mem.Allocator,
            source: json.Value,
            options: json.ParseOptions,
        ) !Self {
            if (source == .null) return .null;

            return .{
                .value = try json.innerParseFromValue(
                    T,
                    allocator,
                    source,
                    options,
                ),
            };
        }

        pub fn jsonStringify(self: Self, jws: *json.Stringify) !void {
            return switch (self) {
                .missing => error.WriteFailed,
                .null => jws.write(null),
                .value => |v| jws.write(v),
            };
        }
    };
}

const testing = std.testing;

test "deserialize from JSON with using struct" {
    const Member = struct {
        nick: Nullable([]const u8) = .missing,
        avatar: Nullable([]const u8) = .missing,
        banner: Nullable([]const u8) = .missing,
    };

    const raw_json =
        \\{"avatar": null, "banner": "hash"}
    ;

    var parsed = try json.parseFromSlice(Member, testing.allocator, raw_json, .{});
    defer parsed.deinit();

    try testing.expect(parsed.value.nick == .missing);
    try testing.expect(parsed.value.avatar == .null);
    try testing.expectEqualStrings("hash", parsed.value.banner.get().?);
}
