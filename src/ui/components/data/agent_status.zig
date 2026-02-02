const zgui = @import("zgui");
const theme = @import("../../theme.zig");
const components = @import("../components.zig");

pub const Args = struct {
    label: []const u8,
    subtitle: ?[]const u8 = null,
    connected: ?bool = null,
    paired: ?bool = null,
    platform: ?[]const u8 = null,
};

pub fn draw(args: Args) void {
    const t = theme.activeTheme();
    theme.push(.heading);
    zgui.text("{s}", .{args.label});
    theme.pop();

    if (args.subtitle) |subtitle| {
        zgui.sameLine(.{ .spacing = t.spacing.sm });
        zgui.textDisabled("{s}", .{subtitle});
    }

    if (args.platform) |platform| {
        zgui.sameLine(.{ .spacing = t.spacing.sm });
        components.core.badge.draw(platform, .{
            .variant = .neutral,
            .filled = false,
            .size = .small,
        });
    }

    if (args.connected) |connected| {
        zgui.sameLine(.{ .spacing = t.spacing.sm });
        components.core.badge.draw(if (connected) "online" else "offline", .{
            .variant = if (connected) .success else .neutral,
            .filled = true,
            .size = .small,
        });
    }

    if (args.paired) |paired| {
        zgui.sameLine(.{ .spacing = t.spacing.xs });
        components.core.badge.draw(if (paired) "paired" else "unpaired", .{
            .variant = if (paired) .primary else .neutral,
            .filled = paired,
            .size = .small,
        });
    }
}
