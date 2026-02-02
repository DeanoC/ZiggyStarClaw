const std = @import("std");
const zgui = @import("zgui");
const theme = @import("../../theme.zig");

pub const Args = struct {
    title: []const u8,
    subtitle: ?[]const u8 = null,
    show_traffic_lights: bool = false,
    show_search: bool = false,
    search_buffer: ?[:0]u8 = null,
    show_notifications: bool = false,
    notification_count: usize = 0,
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

    const draw_list = zgui.getWindowDrawList();
    if (args.show_traffic_lights) {
        const cursor = zgui.getCursorScreenPos();
        const radius: f32 = 5.0;
        const spacing: f32 = 6.0;
        const red = zgui.colorConvertFloat4ToU32(.{ 0.92, 0.26, 0.21, 1.0 });
        const yellow = zgui.colorConvertFloat4ToU32(.{ 0.98, 0.74, 0.02, 1.0 });
        const green = zgui.colorConvertFloat4ToU32(.{ 0.20, 0.66, 0.33, 1.0 });
        const center_y = cursor[1] + radius + 2.0;
        draw_list.addCircleFilled(.{ .p = .{ cursor[0] + radius, center_y }, .r = radius, .col = red });
        draw_list.addCircleFilled(.{
            .p = .{ cursor[0] + radius * 3.0 + spacing, center_y },
            .r = radius,
            .col = yellow,
        });
        draw_list.addCircleFilled(.{
            .p = .{ cursor[0] + radius * 5.0 + spacing * 2.0, center_y },
            .r = radius,
            .col = green,
        });
        zgui.dummy(.{ .w = radius * 6.0 + spacing * 2.0, .h = radius * 2.0 });
        zgui.sameLine(.{ .spacing = t.spacing.sm });
    }

    theme.push(.heading);
    zgui.text("{s}", .{args.title});
    theme.pop();
    if (args.subtitle) |subtitle| {
        zgui.sameLine(.{ .spacing = t.spacing.sm });
        zgui.textDisabled("{s}", .{subtitle});
    }

    if (args.show_search or args.show_notifications) {
        const search_width: f32 = if (args.show_search) 180.0 else 0.0;
        const badge_width: f32 = if (args.show_notifications) 64.0 else 0.0;
        const gap: f32 = if (args.show_search and args.show_notifications) t.spacing.sm else 0.0;
        const total = search_width + badge_width + gap;
        const avail = zgui.getContentRegionAvail();
        const spacer = if (avail[0] > total) avail[0] - total else t.spacing.sm;
        zgui.sameLine(.{ .spacing = spacer });

        if (args.show_search) {
            if (args.search_buffer) |buf| {
                zgui.setNextItemWidth(search_width);
                _ = zgui.inputText("Search", .{ .buf = buf });
            }
        }

        if (args.show_notifications) {
            if (args.show_search) {
                zgui.sameLine(.{ .spacing = t.spacing.sm });
            }
            drawNotificationBadge(t, args.notification_count);
        }
    } else {
        zgui.sameLine(.{ .spacing = t.spacing.sm });
    }
    return true;
}

pub fn end() void {
    zgui.endChild();
    zgui.popStyleColor(.{ .count = 2 });
    zgui.popStyleVar(.{ .count = 3 });
}

fn drawNotificationBadge(t: *const theme.Theme, count: usize) void {
    var label_buf: [16]u8 = undefined;
    const label = std.fmt.bufPrint(&label_buf, "{d}", .{count}) catch "0";
    const label_z = zgui.formatZ("{s}", .{label});
    zgui.pushStyleVar2f(.{ .idx = .frame_padding, .v = .{ t.spacing.xs, 1.0 } });
    zgui.pushStyleVar1f(.{ .idx = .frame_rounding, .v = t.radius.lg });
    zgui.pushStyleColor4f(.{ .idx = .button, .c = t.colors.primary });
    zgui.pushStyleColor4f(.{ .idx = .button_hovered, .c = t.colors.primary });
    zgui.pushStyleColor4f(.{ .idx = .button_active, .c = t.colors.primary });
    zgui.pushStyleColor4f(.{ .idx = .text, .c = t.colors.background });
    _ = zgui.button(label_z, .{ .w = 0.0, .h = 0.0 });
    zgui.popStyleColor(.{ .count = 4 });
    zgui.popStyleVar(.{ .count = 2 });
}
