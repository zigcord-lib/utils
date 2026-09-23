const std = @import("std");
const mem = std.mem;
const json = std.json;

pub fn Optional(comptime T: type) type {
    return union(enum) {
        const Self = @This();

        missing,
        present: T,

        pub fn get(self: Self) ?T {
            return switch (self) {
                .present => |v| v,
                .missing => null,
            };
        }

        pub fn jsonParse(
            allocator: mem.Allocator,
            source: *json.Scanner,
            options: json.ParseOptions,
        ) !Self {
            return .{
                .present = try json.innerParse(
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
            return .{
                .present = try json.innerParseFromValue(
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
                .present => |v| jws.write(v),
            };
        }
    };
}

const testing = std.testing;

test "deserialize from JSON with using struct" {
    const Member = struct {
        nick: Optional(?[]const u8) = .missing,
        avatar: Optional(?[]const u8) = .missing,
        banner: Optional(?[]const u8) = .missing,
    };

    const raw_json =
        \\{"avatar": null, "banner": "hash"}
    ;

    const parsed = try json.parseFromSlice(Member, testing.allocator, raw_json, .{});
    defer parsed.deinit();

    try testing.expect(parsed.value.nick == .missing);
    try testing.expect(parsed.value.avatar == .present);
    try testing.expectEqualStrings("hash", parsed.value.banner.present.?);
}
