const zgui = @import("zgui");
const theme = @import("../../theme.zig");
const components = @import("../components.zig");

pub const Args = struct {
    name: []const u8,
    file_type: ?[]const u8 = null,
    status: ?[]const u8 = null,
};

pub fn draw(args: Args) void {
    const t = theme.activeTheme();
    const cursor = zgui.getCursorScreenPos();
    const local = zgui.getCursorPos();
    const icon_size = zgui.getTextLineHeight();
    const icon_color = zgui.colorConvertFloat4ToU32(theme.activeTheme().colors.primary);
    const draw_list = zgui.getWindowDrawList();
    draw_list.addRectFilled(.{
        .pmin = cursor,
        .pmax = .{ cursor[0] + icon_size, cursor[1] + icon_size },
        .col = icon_color,
        .rounding = 2.0,
    });

    zgui.setCursorPos(.{ local[0] + icon_size + t.spacing.xs, local[1] });
    zgui.dummy(.{ .w = 0.0, .h = 0.0 });
    zgui.text("{s}", .{args.name});
    var has_badge = false;
    if (args.file_type) |file_type| {
        zgui.sameLine(.{ .spacing = t.spacing.sm });
        components.core.badge.draw(file_type, .{
            .variant = .neutral,
            .filled = false,
            .size = .small,
        });
        has_badge = true;
    }
    if (args.status) |status| {
        zgui.sameLine(.{ .spacing = if (has_badge) t.spacing.xs else t.spacing.sm });
        components.core.badge.draw(status, .{
            .variant = .primary,
            .filled = false,
            .size = .small,
        });
    }
}
