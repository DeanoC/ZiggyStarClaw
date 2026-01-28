const std = @import("std");
const state = @import("state.zig");

pub fn handleRawMessage(ctx: *state.ClientContext, raw: []const u8) !void {
    // TODO: parse JSON envelope and dispatch to appropriate handlers.
    std.log.debug("Received raw message (len={d})", .{raw.len});
    _ = ctx;
}

pub fn handleConnectionState(ctx: *state.ClientContext, new_state: state.ClientState) void {
    ctx.state = new_state;
}
