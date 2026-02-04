const zgui = @import("zgui");
const draw_context = @import("../draw_context.zig");

pub fn beginPanelInRect(
    label: [:0]const u8,
    rect: draw_context.Rect,
    flags: zgui.WindowFlags,
    open: *bool,
) bool {
    const size = rect.size();
    const width = @max(1.0, size[0]);
    const height = @max(1.0, size[1]);
    zgui.setNextWindowPos(.{ .x = rect.min[0], .y = rect.min[1], .cond = .always });
    zgui.setNextWindowSize(.{ .w = width, .h = height, .cond = .always });
    return zgui.begin(label, .{ .popen = open, .flags = flags });
}
