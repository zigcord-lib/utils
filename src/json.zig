const std = @import("std");
const json = std.json;

fn isHaveJsonStringifySkippable(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .@"struct", .@"union", .@"enum", .@"opaque" => @hasDecl(T, "jsonStringifySkippable"),
        else => false,
    };
}

fn isSinglePointer(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .pointer => |p| p.size == .one,
        else => false,
    };
}

pub fn stringifyStruct(value: anytype, jws: *json.Stringify) !void {
    const ptr = if (comptime isSinglePointer(@TypeOf(value))) value else &value;
    const T = @typeInfo(@TypeOf(ptr)).pointer.child;

    const info = @typeInfo(T);
    if (info != .@"struct") @compileError("stringifyStruct only works on structs");

    try jws.beginObject();

    inline for (info.@"struct".fields) |field| {
        const field_value = @field(ptr, field.name);

        const skip = blk: {
            if (comptime isHaveJsonStringifySkippable(field.type)) {
                break :blk field_value.jsonStringifySkippable();
            } else break :blk false;
        };

        if (!skip) {
            try jws.objectField(field.name);
            try jws.write(field_value);
        }
    }

    try jws.endObject();
}

const testing = std.testing;

test "isHaveJsonStringifySkippable: non-container types do not cause compile error" {
    const WithDecl = struct {
        pub fn jsonStringifySkippable(_: @This()) bool {
            return false;
        }
    };
    const WithoutDecl = struct { x: u32 };

    const UnionWithDecl = union(enum) {
        a,
        b: u32,

        pub fn jsonStringifySkippable(_: @This()) bool {
            return false;
        }
    };
    const UnionWithoutDecl = union(enum) { a, b: u32 };

    const EnumWithDecl = enum {
        a,
        b,

        pub fn jsonStringifySkippable(_: @This()) bool {
            return false;
        }
    };
    const EnumWithoutDecl = enum { a, b };

    try testing.expect(isHaveJsonStringifySkippable(WithDecl));
    try testing.expect(!isHaveJsonStringifySkippable(WithoutDecl));
    try testing.expect(isHaveJsonStringifySkippable(UnionWithDecl));
    try testing.expect(!isHaveJsonStringifySkippable(UnionWithoutDecl));
    try testing.expect(isHaveJsonStringifySkippable(EnumWithDecl));
    try testing.expect(!isHaveJsonStringifySkippable(EnumWithoutDecl));
}

test "isHaveJsonStringifySkippable: container types" {
    const WithDecl = struct {
        pub fn jsonStringifySkippable(_: @This()) bool {
            return false;
        }
    };

    try testing.expect(!isHaveJsonStringifySkippable(u64));
    try testing.expect(!isHaveJsonStringifySkippable(bool));
    try testing.expect(!isHaveJsonStringifySkippable(f32));
    try testing.expect(!isHaveJsonStringifySkippable([]const u8));
    try testing.expect(!isHaveJsonStringifySkippable([4]u8));
    try testing.expect(!isHaveJsonStringifySkippable(?u32));
    try testing.expect(!isHaveJsonStringifySkippable(?WithDecl));
    try testing.expect(!isHaveJsonStringifySkippable(*const WithDecl));
}

test "stringifyStruct: serialize to JSON with struct" {
    const SerializableStruct = struct {
        const Self = @This();

        serialize: bool,

        pub fn jsonStringifySkippable(self: Self) bool {
            return !self.serialize;
        }
    };

    const MyStruct = struct {
        const Self = @This();

        serializable: SerializableStruct,

        pub fn jsonStringify(self: *const Self, jws: *json.Stringify) !void {
            return stringifyStruct(self, jws);
        }
    };

    const serializable = MyStruct{ .serializable = .{ .serialize = true } };
    const non_serializable = MyStruct{ .serializable = .{ .serialize = false } };

    const serializable_result = try json.Stringify.valueAlloc(testing.allocator, serializable, .{});
    defer testing.allocator.free(serializable_result);
    const non_serializable_result = try json.Stringify.valueAlloc(testing.allocator, non_serializable, .{});
    defer testing.allocator.free(non_serializable_result);

    try testing.expectEqualStrings(
        \\{"serializable":{"serialize":true}}
    , serializable_result);

    try testing.expectEqualStrings("{}", non_serializable_result);
}
