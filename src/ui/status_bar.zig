const zgui = @import("zgui");
const state = @import("../client/state.zig");
const theme = @import("theme.zig");

pub fn draw(
    client_state: state.ClientState,
    is_connected: bool,
    session_name: ?[]const u8,
    message_count: usize,
    last_error: ?[]const u8,
) void {
    const t = theme.activeTheme();
    const spacing = t.spacing.sm;
    const label = t.colors.text_secondary;
    const value = t.colors.text_primary;
    const status_color: [4]f32 = switch (client_state) {
        .connected => t.colors.success,
        .connecting, .authenticating => t.colors.warning,
        .error_state => t.colors.danger,
        .disconnected => if (is_connected) t.colors.success else t.colors.text_secondary,
    };

    zgui.textColored(label, "Status:", .{});
    zgui.sameLine(.{ .spacing = spacing });
    zgui.textColored(status_color, "{s}", .{@tagName(client_state)});
    zgui.sameLine(.{ .spacing = spacing });
    zgui.textColored(label, "Connection:", .{});
    zgui.sameLine(.{ .spacing = spacing });
    zgui.textColored(value, "{s}", .{if (is_connected) "online" else "offline"});
    zgui.sameLine(.{ .spacing = spacing });
    zgui.textColored(label, "Session:", .{});
    zgui.sameLine(.{ .spacing = spacing });
    if (session_name) |name| {
        zgui.textColored(value, "{s}", .{name});
    } else {
        zgui.textColored(label, "(none)", .{});
    }
    zgui.sameLine(.{ .spacing = spacing });
    zgui.textColored(label, "Messages:", .{});
    zgui.sameLine(.{ .spacing = spacing });
    zgui.textColored(value, "{d}", .{message_count});
    if (last_error) |err| {
        zgui.sameLine(.{ .spacing = spacing });
        zgui.textColored(t.colors.danger, "Error: {s}", .{err});
    }
}
