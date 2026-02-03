const std = @import("std");
const unified_config = @import("unified_config.zig");

pub const BridgeEndpoint = struct {
    host: []u8,
    port: u16,

    pub fn deinit(self: *BridgeEndpoint, allocator: std.mem.Allocator) void {
        allocator.free(self.host);
    }
};

/// Derive node-bridge host/port from unified config.
///
/// Rules:
/// - if gateway.bridgeHost present -> use it
/// - else use host from gateway.wsUrl
/// - if gateway.bridgePort present -> use it
/// - else derive as (wsUrl port + 1)
pub fn getBridgeEndpoint(allocator: std.mem.Allocator, gw: unified_config.UnifiedConfig.Gateway) !BridgeEndpoint {
    var host: []u8 = undefined;
    var port: u16 = 0;

    if (gw.bridgeHost) |h| {
        host = try allocator.dupe(u8, std.mem.trim(u8, h, " \t\r\n"));
    } else {
        // std.Uri helpers can return borrowed slices depending on input; avoid freeing
        // anything returned from Uri APIs. Use an arena for any internal allocations,
        // then copy into the caller allocator.
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();
        const aa = arena.allocator();

        const uri = try std.Uri.parse(gw.wsUrl);
        const h = try uri.getHostAlloc(aa);
        host = try allocator.dupe(u8, h);
    }

    if (gw.bridgePort) |p| {
        port = p;
    } else {
        const uri = try std.Uri.parse(gw.wsUrl);
        // Uri.port is optional; default depends on scheme.
        const ws_port: u16 = if (uri.port) |p| @intCast(p) else blk: {
            const s = uri.scheme;
            if (std.mem.eql(u8, s, "wss") or std.mem.eql(u8, s, "https")) break :blk 443;
            break :blk 80;
        };
        port = ws_port + 1;
    }

    return .{ .host = host, .port = port };
}
