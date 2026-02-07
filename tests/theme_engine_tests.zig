const std = @import("std");

const zsc = @import("ziggystarclaw");

test "theme engine loads example theme pack directory" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var engine = zsc.ui.theme_engine.ThemeEngine.init(allocator, zsc.ui.theme_engine.PlatformCaps.defaultForTarget());
    defer engine.deinit();

    try engine.loadAndApplyThemePackDir("docs/theme_engine/examples/zsc_clean");

    // Active theme should now be runtime (not the built-in compile-time defaults).
    const t = zsc.ui.theme.activeTheme();
    try std.testing.expect(t.spacing.xs > 0.0);
    try std.testing.expect(t.typography.body_size > 0.0);

    const ss = zsc.ui.theme_engine.runtime.getStyleSheet();
    try std.testing.expect(ss.button.primary.fill != null);
    if (ss.button.primary.fill) |c| {
        try std.testing.expectApproxEqAbs(t.colors.primary[0], c[0], 0.0001);
        try std.testing.expectApproxEqAbs(t.colors.primary[1], c[1], 0.0001);
        try std.testing.expectApproxEqAbs(t.colors.primary[2], c[2], 0.0001);
    }
}
