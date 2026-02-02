// ZiggyStarClaw Button Component
// A reusable button component with multiple variants and states.

const std = @import("std");
const zgui = @import("zgui");
const theme = @import("theme_light.zig");

// =============================================================================
// Button Types and Configuration
// =============================================================================

pub const ButtonVariant = enum {
    primary,    // Main action button (blue)
    secondary,  // Secondary action (gray outline)
    success,    // Approve/confirm action (green)
    danger,     // Decline/delete action (red)
    ghost,      // Minimal styling, text only
};

pub const ButtonSize = enum {
    small,
    medium,
    large,

    pub fn getHeight(self: ButtonSize) f32 {
        return switch (self) {
            .small => 28.0,
            .medium => 36.0,
            .large => 44.0,
        };
    }

    pub fn getPadding(self: ButtonSize) [2]f32 {
        return switch (self) {
            .small => .{ 12.0, 4.0 },
            .medium => .{ 16.0, 8.0 },
            .large => .{ 24.0, 12.0 },
        };
    }
};

pub const ButtonConfig = struct {
    variant: ButtonVariant = .primary,
    size: ButtonSize = .medium,
    disabled: bool = false,
    full_width: bool = false,
    icon: ?[]const u8 = null,  // Icon codepoint or name
};

// =============================================================================
// Style Helpers
// =============================================================================

const ButtonStyle = struct {
    background: [4]f32,
    background_hovered: [4]f32,
    background_active: [4]f32,
    text: [4]f32,
    border: [4]f32,
};

fn getStyleForVariant(variant: ButtonVariant) ButtonStyle {
    const colors = theme.light_colors;
    
    return switch (variant) {
        .primary => .{
            .background = colors.primary,
            .background_hovered = colors.primary_light,
            .background_active = colors.primary_dark,
            .text = colors.text_on_primary,
            .border = colors.primary,
        },
        .secondary => .{
            .background = theme.rgba(0, 0, 0, 0),
            .background_hovered = theme.rgba(0, 0, 0, 10),
            .background_active = theme.rgba(0, 0, 0, 20),
            .text = colors.text_primary,
            .border = colors.border,
        },
        .success => .{
            .background = colors.success,
            .background_hovered = colors.success_light,
            .background_active = theme.rgba(40, 150, 70, 255),
            .text = colors.text_on_primary,
            .border = colors.success,
        },
        .danger => .{
            .background = colors.error,
            .background_hovered = colors.error_light,
            .background_active = theme.rgba(200, 50, 40, 255),
            .text = colors.text_on_primary,
            .border = colors.error,
        },
        .ghost => .{
            .background = theme.rgba(0, 0, 0, 0),
            .background_hovered = theme.rgba(0, 0, 0, 10),
            .background_active = theme.rgba(0, 0, 0, 20),
            .text = colors.primary,
            .border = theme.rgba(0, 0, 0, 0),
        },
    };
}

// =============================================================================
// Button Drawing Functions
// =============================================================================

/// Draw a button with the specified label and configuration.
/// Returns true on the frame the button is clicked.
pub fn draw(label: []const u8, config: ButtonConfig) bool {
    const style = getStyleForVariant(config.variant);
    const padding = config.size.getPadding();
    const radius = theme.default_radius;
    
    // Apply disabled state
    if (config.disabled) {
        zgui.pushItemFlag(.{ .disabled = true });
        zgui.pushStyleVar(.alpha, 0.5);
    }
    
    // Push colors
    zgui.pushStyleColor(.button, style.background);
    zgui.pushStyleColor(.button_hovered, style.background_hovered);
    zgui.pushStyleColor(.button_active, style.background_active);
    zgui.pushStyleColor(.text, style.text);
    
    // Push style vars
    zgui.pushStyleVar(.frame_padding, padding);
    zgui.pushStyleVar(.frame_rounding, radius.md);
    
    // Handle border for secondary variant
    if (config.variant == .secondary) {
        zgui.pushStyleVar(.frame_border_size, 1.0);
        zgui.pushStyleColor(.border, style.border);
    }
    
    // Calculate size
    var size: zgui.Vec2 = .{ .x = 0, .y = config.size.getHeight() };
    if (config.full_width) {
        size.x = -1.0; // Fill available width
    }
    
    // Draw the button
    const clicked = zgui.buttonEx(label, size);
    
    // Pop styles in reverse order
    if (config.variant == .secondary) {
        zgui.popStyleColor(1);
        zgui.popStyleVar(1);
    }
    
    zgui.popStyleVar(2);
    zgui.popStyleColor(4);
    
    if (config.disabled) {
        zgui.popStyleVar(1);
        zgui.popItemFlag();
    }
    
    return clicked;
}

/// Convenience function for a primary button
pub fn primary(label: []const u8) bool {
    return draw(label, .{ .variant = .primary });
}

/// Convenience function for a secondary button
pub fn secondary(label: []const u8) bool {
    return draw(label, .{ .variant = .secondary });
}

/// Convenience function for an approve button
pub fn approve(label: []const u8) bool {
    return draw(label, .{ .variant = .success });
}

/// Convenience function for a decline button
pub fn decline(label: []const u8) bool {
    return draw(label, .{ .variant = .danger });
}

// =============================================================================
// Icon Button
// =============================================================================

pub fn iconButton(icon: []const u8, tooltip: ?[]const u8) bool {
    const colors = theme.light_colors;
    
    zgui.pushStyleColor(.button, theme.rgba(0, 0, 0, 0));
    zgui.pushStyleColor(.button_hovered, theme.rgba(0, 0, 0, 10));
    zgui.pushStyleColor(.button_active, theme.rgba(0, 0, 0, 20));
    zgui.pushStyleColor(.text, colors.text_secondary);
    zgui.pushStyleVar(.frame_padding, .{ 8.0, 8.0 });
    zgui.pushStyleVar(.frame_rounding, theme.default_radius.full);
    
    const clicked = zgui.button(icon, .{});
    
    zgui.popStyleVar(2);
    zgui.popStyleColor(4);
    
    if (tooltip) |tip| {
        if (zgui.isItemHovered(.{})) {
            zgui.setTooltip("{s}", .{tip});
        }
    }
    
    return clicked;
}

// =============================================================================
// Button Group (Approve/Decline pair)
// =============================================================================

pub const ButtonGroupResult = struct {
    approve_clicked: bool,
    decline_clicked: bool,
};

pub fn approvalButtonGroup() ButtonGroupResult {
    var result = ButtonGroupResult{
        .approve_clicked = false,
        .decline_clicked = false,
    };
    
    const spacing = theme.default_spacing;
    
    // Approve button
    result.approve_clicked = approve("Approve");
    
    zgui.sameLine(.{ .spacing = spacing.sm });
    
    // Decline button
    result.decline_clicked = decline("Decline");
    
    return result;
}
