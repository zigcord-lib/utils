const std = @import("std");
const mem = std.mem;
const ascii = std.ascii;

pub fn eqlString(comptime strategy: EqlStringCaseStrategy, a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;

    return switch (strategy) {
        .ignore => ascii.eqlIgnoreCase(a, b),
        .lower => mem.eql(u8, a, b) and isLowerString(a),
        .upper => mem.eql(u8, a, b) and isUpperString(a),
    };
}

pub const EqlStringCaseStrategy = enum {
    lower,
    upper,
    ignore,
};

pub fn eqlStrings(comptime strategy: EqlStringCaseStrategy, a: []const []const u8, b: []const []const u8) bool {
    if (a.len != b.len) return false;

    for (a, b) |a_item, b_item| {
        if (!eqlString(strategy, a_item, b_item)) return false;
    }

    return true;
}

pub fn isLowerString(s: []const u8) bool {
    for (s) |c| {
        if (ascii.isUpper(c)) return false;
    }

    return true;
}

pub fn isLowerStrings(s: []const []const u8) bool {
    for (s) |string| {
        if (!isLowerString(string)) return false;
    }

    return true;
}

pub fn isUpperString(s: []const u8) bool {
    for (s) |c| {
        if (ascii.isLower(c)) return false;
    }

    return true;
}

pub fn isUpperStrings(s: []const []const u8) bool {
    for (s) |string| {
        if (!isUpperString(string)) return false;
    }

    return true;
}

pub fn comptimeLowerString(comptime s: []const u8) *const [s.len]u8 {
    return comptime blk: {
        var buf: [s.len]u8 = undefined;
        for (s, 0..) |c, i| buf[i] = ascii.toLower(c);
        const final = buf;
        break :blk &final;
    };
}

pub fn comptimeUpperString(comptime s: []const u8) *const [s.len]u8 {
    return comptime blk: {
        var buf: [s.len]u8 = undefined;
        for (s, 0..) |c, i| buf[i] = ascii.toUpper(c);
        const final = buf;
        break :blk &final;
    };
}

const testing = std.testing;

test "eqlString/s" {
    // Ignore-case
    try testing.expect(eqlString(.ignore, "aa", "aa"));
    try testing.expect(eqlString(.ignore, "aA", "Aa"));

    // Upper-case
    try testing.expect(eqlString(.upper, "AA", "AA"));
    try testing.expect(!eqlString(.upper, "aA", "Aa"));

    // Lower-case
    try testing.expect(eqlString(.lower, "aa", "aa"));
    try testing.expect(!eqlString(.lower, "aA", "Aa"));

    // Ignore-case
    try testing.expect(eqlStrings(.ignore, &.{ "aa", "bb" }, &.{ "aa", "bb" }));
    try testing.expect(eqlStrings(.ignore, &.{ "aA", "bB" }, &.{ "Aa", "Bb" }));
    try testing.expect(!eqlStrings(.ignore, &.{ "aA", "bB", "cC" }, &.{ "Aa", "Bb", "c" }));

    // Upper-case
    try testing.expect(eqlStrings(.upper, &.{ "AA", "BB" }, &.{ "AA", "BB" }));
    try testing.expect(!eqlStrings(.upper, &.{ "aA", "bB" }, &.{ "Aa", "Bb" }));
    try testing.expect(!eqlStrings(.upper, &.{ "aA", "bB", "cC" }, &.{ "Aa", "Bb", "c" }));

    // Lower-case
    try testing.expect(eqlStrings(.lower, &.{ "aa", "bb" }, &.{ "aa", "bb" }));
    try testing.expect(!eqlStrings(.lower, &.{ "aA", "bB" }, &.{ "Aa", "Bb" }));
    try testing.expect(!eqlStrings(.lower, &.{ "aA", "bB", "cC" }, &.{ "Aa", "Bb", "c" }));
}

test "isLowerString/s" {
    try testing.expect(isLowerString("abc"));
    try testing.expect(!isLowerString("abC"));

    try testing.expect(isLowerStrings(&.{ "abc", "abc" }));
    try testing.expect(!isLowerStrings(&.{ "abc", "aBc" }));
}

test "isUpperString/s" {
    try testing.expect(isUpperString("ABC"));
    try testing.expect(isUpperString("A_B_C"));
    try testing.expect(!isUpperString("abC"));

    try testing.expect(isUpperStrings(&.{ "ABC", "ABC" }));
    try testing.expect(!isUpperStrings(&.{ "ABC", "AbC" }));
}

test "comptimeUpper/lower" {
    try testing.expectEqualStrings("ABC", comptimeUpperString("abc"));
    try testing.expectEqualStrings("abc", comptimeLowerString("ABC"));
}
