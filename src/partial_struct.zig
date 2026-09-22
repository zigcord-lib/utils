const std = @import("std");

pub fn PartialStruct(comptime T: type) type {
    const info = @typeInfo(T);
    if (info != .@"struct") {
        @compileError("PartialStruct only works on structs");
    }
    const struct_info = info.@"struct";
    const field_count = struct_info.fields.len;

    var field_names: [field_count][]const u8 = undefined;
    var field_types: [field_count]type = undefined;
    var field_attrs: [field_count]std.builtin.Type.StructField.Attributes = undefined;

    for (struct_info.fields, 0..) |field, i| {
        const already_optional = @typeInfo(field.type) == .optional;
        field_names[i] = field.name;
        field_types[i] = if (already_optional) field.type else ?field.type;

        field_attrs[i] = std.builtin.Type.StructField.Attributes{
            .@"align" = field.alignment,
            .@"comptime" = field.is_comptime,
            .default_value_ptr = getDefaultValuePtr(field, field_types[i]),
        };
    }

    return @Struct(
        struct_info.layout,
        struct_info.backing_integer,
        &field_names,
        &field_types,
        &field_attrs,
    );
}

fn getDefaultValuePtr(
    comptime field: std.builtin.Type.StructField,
    comptime TargetType: type,
) ?*const anyopaque {
    if (field.default_value_ptr) |ptr| {
        const already_optional = @typeInfo(field.type) == .optional;
        if (already_optional) {
            return ptr;
        }

        const original_default: field.type = @as(*const field.type, @ptrCast(@alignCast(ptr))).*;
        const wrapped: TargetType = original_default;
        return @ptrCast(&wrapped);
    }

    const null_value: TargetType = null;
    return @ptrCast(&null_value);
}

const testing = std.testing;

test "all fields is optional" {
    const NonOptional = struct {
        field_1: u32,
        field_2: []const u8,
        field_3: f64,
    };

    const WithOptional = PartialStruct(NonOptional);
    const info = @typeInfo(WithOptional).@"struct";

    inline for (info.fields) |field| {
        try testing.expect(@typeInfo(field.type) == .optional);
    }
}

test "no have default values" {
    const MyStruct = struct {
        field_1: u32,
        field_2: []const u8,
        field_3: f64,
    };

    const PartialMyStruct = PartialStruct(MyStruct);

    const x: PartialMyStruct = .{
        .field_1 = 1,
        .field_2 = "2",
        .field_3 = 3.14,
    };

    try testing.expectEqual(1, x.field_1);
    try testing.expectEqualStrings("2", x.field_2.?);
    try testing.expectEqual(3.14, x.field_3);
}

test "have default values" {
    const MyStruct = struct {
        field_1: u32 = 1,
        field_2: []const u8 = "2",
        field_3: f64 = 3.14,
    };

    const PartialMyStruct = PartialStruct(MyStruct);

    const x: PartialMyStruct = .{};

    try testing.expectEqual(1, x.field_1);
    try testing.expectEqualStrings("2", x.field_2.?);
    try testing.expectEqual(3.14, x.field_3);
}

test "mixed values" {
    const MyStruct = struct {
        field_1: u32 = 1,
        field_2: ?[]const u8,
        field_3: f64,
    };

    const PartialMyStruct = PartialStruct(MyStruct);

    const x: PartialMyStruct = .{};

    try testing.expectEqual(1, x.field_1);
    try testing.expect(x.field_2 == null);
    try testing.expect(@typeInfo(@TypeOf(x.field_3)) == .optional);
}
