const std = @import("std");

pub const PartialStruct = @import("./partial_struct.zig").PartialStruct;

test {
    std.testing.refAllDecls(@This());
}
