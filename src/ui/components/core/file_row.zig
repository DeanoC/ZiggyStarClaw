const zgui = @import("zgui");
const theme = @import("../../theme.zig");
const components = @import("../components.zig");

pub const Args = struct {
    filename: []const u8,
    language: ?[]const u8 = null,
    status: ?[]const u8 = null,
    dirty: bool = false,
};

pub fn draw(args: Args) void {
    const t = theme.activeTheme();
    theme.push(.heading);
    zgui.text("{s}", .{args.filename});
    theme.pop();

    if (args.language != null or args.dirty) {
        zgui.sameLine(.{ .spacing = t.spacing.sm });
    }

    if (args.language) |lang| {
        components.core.badge.draw(lang, .{
            .variant = .primary,
            .filled = false,
            .size = .small,
        });
    }

    if (args.dirty) {
        zgui.sameLine(.{ .spacing = t.spacing.xs });
        components.core.badge.draw("modified", .{
            .variant = .warning,
            .filled = true,
            .size = .small,
        });
    }

    if (args.status) |status| {
        zgui.textDisabled("{s}", .{status});
    }
}
