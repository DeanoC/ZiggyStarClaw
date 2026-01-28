const std = @import("std");

pub fn info(comptime fmt: []const u8, args: anytype) void {
    std.log.info(fmt, args);
}

pub fn warn(comptime fmt: []const u8, args: anytype) void {
    std.log.warn(fmt, args);
}

pub fn err(comptime fmt: []const u8, args: anytype) void {
    std.log.err(fmt, args);
}

pub fn debug(comptime fmt: []const u8, args: anytype) void {
    std.log.debug(fmt, args);
}
