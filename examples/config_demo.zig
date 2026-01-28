const std = @import("std");
const config = @import("../src/client/config.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cfg = try config.loadOrDefault(allocator, "moltbot_config.json");
    defer cfg.deinit(allocator);

    std.log.info("Loaded config: {s}", .{cfg.server_url});
}
