const zgui = @import("zgui");
const theme = @import("../../theme.zig");

pub fn begin(id: [:0]const u8) bool {
    const t = theme.activeTheme();
    zgui.pushStyleVar2f(.{ .idx = .item_spacing, .v = .{ t.spacing.sm, t.spacing.xs } });
    zgui.pushStyleVar2f(.{ .idx = .frame_padding, .v = .{ t.spacing.sm, t.spacing.xs } });
    if (!zgui.beginTabBar(id, .{})) {
        zgui.popStyleVar(.{ .count = 2 });
        return false;
    }
    return true;
}

pub fn end() void {
    zgui.endTabBar();
    zgui.popStyleVar(.{ .count = 2 });
}

pub fn beginItem(label: [:0]const u8) bool {
    return zgui.beginTabItem(label, .{});
}

pub fn endItem() void {
    zgui.endTabItem();
}
