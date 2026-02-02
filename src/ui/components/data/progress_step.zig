const theme = @import("../../theme.zig");
const components = @import("../components.zig");

pub const State = enum {
    pending,
    active,
    complete,
    failed,
};

pub const Args = struct {
    label: []const u8,
    state: State = .pending,
};

pub fn draw(args: Args) void {
    const variant: components.core.badge.Variant = switch (args.state) {
        .pending => .neutral,
        .active => .primary,
        .complete => .success,
        .failed => .danger,
    };
    const filled = switch (args.state) {
        .pending => false,
        else => true,
    };
    _ = theme.activeTheme();
    components.core.badge.draw(args.label, .{
        .variant = variant,
        .filled = filled,
        .size = .small,
    });
}
