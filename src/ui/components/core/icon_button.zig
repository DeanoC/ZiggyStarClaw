const zgui = @import("zgui");
const theme = @import("../../theme.zig");

pub const Args = struct {
    size: f32 = 0.0,
    tooltip: ?[]const u8 = null,
};

pub fn draw(label: []const u8, args: Args) bool {
    const t = theme.activeTheme();
    const size = if (args.size > 0.0) args.size else (t.spacing.lg + t.spacing.sm);
    const label_z = zgui.formatZ("{s}", .{label});
    zgui.pushStyleVar2f(.{ .idx = .frame_padding, .v = .{ t.spacing.xs, t.spacing.xs } });
    zgui.pushStyleVar1f(.{ .idx = .frame_rounding, .v = t.radius.sm });
    const clicked = zgui.button(label_z, .{ .w = size, .h = size });
    _ = args.tooltip;
    zgui.popStyleVar(.{ .count = 2 });
    return clicked;
}
