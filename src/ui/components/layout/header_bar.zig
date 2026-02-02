const zgui = @import("zgui");
const theme = @import("../../theme.zig");

pub const Args = struct {
    title: []const u8,
    subtitle: ?[]const u8 = null,
};

pub fn begin(args: Args) bool {
    const t = theme.activeTheme();
    zgui.pushStyleVar2f(.{ .idx = .window_padding, .v = .{ t.spacing.sm, t.spacing.xs } });
    zgui.pushStyleVar1f(.{ .idx = .child_rounding, .v = t.radius.md });
    zgui.pushStyleVar1f(.{ .idx = .child_border_size, .v = 1.0 });
    zgui.pushStyleColor4f(.{ .idx = .child_bg, .c = t.colors.surface });
    zgui.pushStyleColor4f(.{ .idx = .border, .c = t.colors.border });

    const opened = zgui.beginChild("##header_bar", .{
        .h = zgui.getFrameHeightWithSpacing() + t.spacing.sm,
        .child_flags = .{ .border = true },
    });
    if (!opened) return false;

    theme.push(.heading);
    zgui.text("{s}", .{args.title});
    theme.pop();
    if (args.subtitle) |subtitle| {
        zgui.sameLine(.{ .spacing = t.spacing.sm });
        zgui.textDisabled("{s}", .{subtitle});
    }
    zgui.sameLine(.{ .spacing = t.spacing.sm });
    return true;
}

pub fn end() void {
    zgui.endChild();
    zgui.popStyleColor(.{ .count = 2 });
    zgui.popStyleVar(.{ .count = 3 });
}
