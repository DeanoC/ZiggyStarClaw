const state = @import("../client/state.zig");

pub fn draw(client_state: state.ClientState, session_name: ?[]const u8, message_count: usize) void {
    _ = client_state;
    _ = session_name;
    _ = message_count;
    // TODO: render connection status, session name, message count, latency.
}
