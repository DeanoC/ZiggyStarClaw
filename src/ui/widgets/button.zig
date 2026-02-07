const draw_context = @import("../draw_context.zig");
const input_state = @import("../input/input_state.zig");
const theme = @import("../theme.zig");
const colors = @import("../theme/colors.zig");
const theme_runtime = @import("../theme_engine/runtime.zig");

pub const Variant = enum {
    primary,
    secondary,
    ghost,
};

pub const Options = struct {
    disabled: bool = false,
    variant: Variant = .secondary,
    radius: ?f32 = null,
};

pub fn draw(
    ctx: *draw_context.DrawContext,
    rect: draw_context.Rect,
    label: []const u8,
    queue: *input_state.InputQueue,
    opts: Options,
) bool {
    const t = theme.activeTheme();
    const profile = theme_runtime.getProfile();
    const allow_hover = profile.allow_hover_states;
    const inside = rect.contains(queue.state.mouse_pos);
    const hovered = allow_hover and inside;
    const active = inside and queue.state.mouse_down_left;

    const ss = theme_runtime.getStyleSheet();
    const variant_style = switch (opts.variant) {
        .primary => ss.button.primary,
        .secondary => ss.button.secondary,
        .ghost => ss.button.ghost,
    };

    var clicked = false;
    if (!opts.disabled) {
        for (queue.events.items) |evt| {
            switch (evt) {
                .mouse_up => |mu| {
                    if (mu.button == .left and rect.contains(mu.pos)) {
                        clicked = true;
                    }
                },
                else => {},
            }
        }
    }

    const white: colors.Color = .{ 1.0, 1.0, 1.0, 1.0 };
    const transparent: colors.Color = .{ 0.0, 0.0, 0.0, 0.0 };
    const base_bg = switch (opts.variant) {
        .primary => variant_style.fill orelse t.colors.primary,
        .secondary => variant_style.fill orelse t.colors.surface,
        .ghost => variant_style.fill orelse transparent,
    };
    const hover_bg = switch (opts.variant) {
        .primary => colors.blend(base_bg, white, 0.12),
        .secondary => colors.blend(base_bg, t.colors.primary, 0.06),
        .ghost => colors.withAlpha(t.colors.primary, 0.08),
    };
    const active_bg = switch (opts.variant) {
        .primary => colors.blend(base_bg, white, 0.2),
        .secondary => colors.blend(base_bg, t.colors.primary, 0.12),
        .ghost => colors.withAlpha(t.colors.primary, 0.14),
    };

    var fill = base_bg;
    if (active) {
        fill = active_bg;
    } else if (hovered) {
        fill = hover_bg;
    }

    var text_color = t.colors.text_primary;
    if (opts.variant == .primary) {
        text_color = colors.rgba(255, 255, 255, 255);
    }
    if (variant_style.text) |override| {
        text_color = override;
    }
    var border = t.colors.border;
    if (variant_style.border) |override| {
        border = override;
    }
    if (hovered) {
        border = colors.blend(border, t.colors.primary, 0.2);
    }

    if (opts.disabled) {
        fill = colors.withAlpha(fill, 0.4);
        text_color = t.colors.text_secondary;
        border = colors.withAlpha(border, 0.6);
    }

    const radius = opts.radius orelse variant_style.radius orelse t.radius.sm;
    ctx.drawRoundedRect(rect, radius, .{
        .fill = fill,
        .stroke = border,
        .thickness = 1.0,
    });

    const text_w = ctx.measureText(label, 0.0)[0];
    const text_h = ctx.lineHeight();
    const pos = .{
        rect.min[0] + (rect.size()[0] - text_w) * 0.5,
        rect.min[1] + (rect.size()[1] - text_h) * 0.5,
    };
    ctx.drawText(label, pos, .{ .color = text_color });

    return clicked and !opts.disabled;
}
