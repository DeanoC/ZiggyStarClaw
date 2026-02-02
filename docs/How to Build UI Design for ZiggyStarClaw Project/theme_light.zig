// ZiggyStarClaw Light Theme Implementation
// This file provides a complete light theme implementation based on the visual guide.
// It can be integrated into the existing theme.zig or used as a reference.

const std = @import("std");
const zgui = @import("zgui");

// =============================================================================
// Color Definitions
// =============================================================================

pub fn rgba(r: u8, g: u8, b: u8, a: u8) [4]f32 {
    return .{
        @as(f32, @floatFromInt(r)) / 255.0,
        @as(f32, @floatFromInt(g)) / 255.0,
        @as(f32, @floatFromInt(b)) / 255.0,
        @as(f32, @floatFromInt(a)) / 255.0,
    };
}

pub const Colors = struct {
    // Backgrounds
    background: [4]f32,
    surface: [4]f32,
    surface_elevated: [4]f32,
    
    // Primary palette (Google-inspired)
    primary: [4]f32,
    primary_light: [4]f32,
    primary_dark: [4]f32,
    
    // Semantic colors
    success: [4]f32,
    success_light: [4]f32,
    error: [4]f32,
    error_light: [4]f32,
    warning: [4]f32,
    warning_light: [4]f32,
    
    // Text
    text_primary: [4]f32,
    text_secondary: [4]f32,
    text_disabled: [4]f32,
    text_on_primary: [4]f32,
    
    // Borders and dividers
    border: [4]f32,
    divider: [4]f32,
    
    // Interactive states
    hover_overlay: [4]f32,
    pressed_overlay: [4]f32,
};

pub const light_colors = Colors{
    // Backgrounds
    .background = rgba(255, 255, 255, 255),
    .surface = rgba(245, 245, 245, 255),
    .surface_elevated = rgba(255, 255, 255, 255),
    
    // Primary palette (Google Blue)
    .primary = rgba(66, 133, 244, 255),
    .primary_light = rgba(100, 160, 255, 255),
    .primary_dark = rgba(30, 100, 200, 255),
    
    // Semantic colors
    .success = rgba(52, 168, 83, 255),
    .success_light = rgba(80, 200, 110, 255),
    .error = rgba(234, 67, 53, 255),
    .error_light = rgba(255, 100, 90, 255),
    .warning = rgba(251, 188, 4, 255),
    .warning_light = rgba(255, 210, 60, 255),
    
    // Text
    .text_primary = rgba(32, 33, 36, 255),
    .text_secondary = rgba(95, 99, 104, 255),
    .text_disabled = rgba(160, 164, 170, 255),
    .text_on_primary = rgba(255, 255, 255, 255),
    
    // Borders and dividers
    .border = rgba(218, 220, 224, 255),
    .divider = rgba(232, 234, 237, 255),
    
    // Interactive states
    .hover_overlay = rgba(0, 0, 0, 10),
    .pressed_overlay = rgba(0, 0, 0, 20),
};

// =============================================================================
// Typography
// =============================================================================

pub const Typography = struct {
    title_size: f32,
    heading_size: f32,
    body_size: f32,
    caption_size: f32,
};

pub const default_typography = Typography{
    .title_size = 22.0,
    .heading_size = 18.0,
    .body_size = 16.0,
    .caption_size = 12.0,
};

// =============================================================================
// Spacing and Radius
// =============================================================================

pub const Spacing = struct {
    xs: f32,
    sm: f32,
    md: f32,
    lg: f32,
    xl: f32,
};

pub const default_spacing = Spacing{
    .xs = 4.0,
    .sm = 8.0,
    .md = 16.0,
    .lg = 24.0,
    .xl = 32.0,
};

pub const Radius = struct {
    sm: f32,
    md: f32,
    lg: f32,
    full: f32,
};

pub const default_radius = Radius{
    .sm = 4.0,
    .md = 8.0,
    .lg = 12.0,
    .full = 9999.0,
};

// =============================================================================
// Theme Application
// =============================================================================

pub fn applyLightTheme() void {
    const style = zgui.getStyle();
    const colors = light_colors;
    const spacing = default_spacing;
    const radius = default_radius;

    // General style settings
    style.alpha = 1.0;
    style.disabled_alpha = 0.5;
    style.window_padding = .{ spacing.md, spacing.md };
    style.frame_padding = .{ spacing.sm, spacing.xs };
    style.item_spacing = .{ spacing.sm, spacing.sm };
    style.item_inner_spacing = .{ spacing.xs, spacing.xs };
    style.cell_padding = .{ spacing.sm, spacing.xs };
    style.indent_spacing = spacing.lg;
    style.scrollbar_size = 12.0;
    style.grab_min_size = 12.0;

    // Rounding
    style.window_rounding = radius.lg;
    style.child_rounding = radius.md;
    style.popup_rounding = radius.md;
    style.frame_rounding = radius.sm;
    style.scrollbar_rounding = radius.full;
    style.grab_rounding = radius.sm;
    style.tab_rounding = radius.sm;

    // Borders
    style.window_border_size = 1.0;
    style.child_border_size = 1.0;
    style.popup_border_size = 1.0;
    style.frame_border_size = 0.0;
    style.tab_border_size = 0.0;

    // Colors
    style.setColor(.text, colors.text_primary);
    style.setColor(.text_disabled, colors.text_disabled);
    style.setColor(.window_bg, colors.background);
    style.setColor(.child_bg, colors.surface);
    style.setColor(.popup_bg, colors.surface_elevated);
    style.setColor(.border, colors.border);
    style.setColor(.border_shadow, rgba(0, 0, 0, 0));
    style.setColor(.frame_bg, colors.surface);
    style.setColor(.frame_bg_hovered, rgba(0, 0, 0, 10));
    style.setColor(.frame_bg_active, rgba(0, 0, 0, 20));
    style.setColor(.title_bg, colors.surface);
    style.setColor(.title_bg_active, colors.surface);
    style.setColor(.title_bg_collapsed, colors.surface);
    style.setColor(.menu_bar_bg, colors.surface);
    style.setColor(.scrollbar_bg, colors.surface);
    style.setColor(.scrollbar_grab, colors.border);
    style.setColor(.scrollbar_grab_hovered, colors.text_secondary);
    style.setColor(.scrollbar_grab_active, colors.text_primary);
    style.setColor(.check_mark, colors.primary);
    style.setColor(.slider_grab, colors.primary);
    style.setColor(.slider_grab_active, colors.primary_dark);
    style.setColor(.button, colors.primary);
    style.setColor(.button_hovered, colors.primary_light);
    style.setColor(.button_active, colors.primary_dark);
    style.setColor(.header, colors.surface);
    style.setColor(.header_hovered, rgba(0, 0, 0, 10));
    style.setColor(.header_active, rgba(0, 0, 0, 20));
    style.setColor(.separator, colors.divider);
    style.setColor(.separator_hovered, colors.primary);
    style.setColor(.separator_active, colors.primary_dark);
    style.setColor(.resize_grip, rgba(66, 133, 244, 50));
    style.setColor(.resize_grip_hovered, rgba(66, 133, 244, 150));
    style.setColor(.resize_grip_active, colors.primary);
    style.setColor(.input_text_cursor, colors.primary);
    style.setColor(.tab_hovered, rgba(0, 0, 0, 10));
    style.setColor(.tab, colors.surface);
    style.setColor(.tab_selected, colors.background);
    style.setColor(.tab_selected_overline, colors.primary);
    style.setColor(.tab_dimmed, colors.surface);
    style.setColor(.tab_dimmed_selected, colors.background);
    style.setColor(.tab_dimmed_selected_overline, rgba(66, 133, 244, 128));
    style.setColor(.docking_preview, rgba(66, 133, 244, 70));
    style.setColor(.docking_empty_bg, colors.surface);
    style.setColor(.plot_lines, colors.primary);
    style.setColor(.plot_lines_hovered, colors.primary_light);
    style.setColor(.plot_histogram, colors.success);
    style.setColor(.plot_histogram_hovered, colors.success_light);
    style.setColor(.table_header_bg, colors.surface);
    style.setColor(.table_border_strong, colors.border);
    style.setColor(.table_border_light, colors.divider);
    style.setColor(.table_row_bg, colors.background);
    style.setColor(.table_row_bg_alt, colors.surface);
    style.setColor(.text_link, colors.primary);
    style.setColor(.text_selected_bg, rgba(66, 133, 244, 70));
    style.setColor(.tree_lines, colors.border);
    style.setColor(.drag_drop_target, rgba(66, 133, 244, 220));
    style.setColor(.nav_cursor, rgba(66, 133, 244, 200));
    style.setColor(.nav_windowing_highlight, rgba(66, 133, 244, 170));
    style.setColor(.nav_windowing_dim_bg, rgba(0, 0, 0, 80));
    style.setColor(.modal_window_dim_bg, rgba(0, 0, 0, 110));
}
