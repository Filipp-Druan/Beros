const std = @import("std");
const Io = std.Io;

const beros = @import("beros");

pub fn main() !void {
    std.debug.print("hello", .{});

    std.debug.assert(false);
}
