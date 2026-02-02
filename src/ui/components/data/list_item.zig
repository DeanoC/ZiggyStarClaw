const zgui = @import("zgui");
const theme = @import("../../theme.zig");

pub const Args = struct {
    label: []const u8,
    selected: bool = false,
    disabled: bool = false,
    id: ?[]const u8 = null,
};

pub fn draw(args: Args) bool {
    const t = theme.activeTheme();
    const label_z = if (args.id) |id|
        zgui.formatZ("{s}##{s}", .{ args.label, id })
    else
        zgui.formatZ("{s}", .{args.label});

    zgui.pushStyleVar2f(.{ .idx = .frame_padding, .v = .{ t.spacing.sm, t.spacing.xs } });
    const clicked = zgui.selectable(label_z, .{
        .selected = args.selected,
        .flags = .{ .disabled = args.disabled },
    });
    zgui.popStyleVar(.{ .count = 1 });
    return clicked;
}
