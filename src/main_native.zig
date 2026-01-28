const std = @import("std");
const client_state = @import("client/state.zig");
const config = @import("client/config.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    // Load config or fall back to defaults.
    var cfg = try config.loadOrDefault(allocator, "moltbot_config.json");
    defer cfg.deinit(allocator);

    var ctx = try client_state.ClientContext.init(allocator);
    defer ctx.deinit();

    std.log.info("MoltBot client stub (native) loaded. Server: {s}", .{cfg.server_url});
}
