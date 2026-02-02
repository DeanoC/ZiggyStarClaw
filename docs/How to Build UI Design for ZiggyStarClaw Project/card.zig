// ZiggyStarClaw Card Component
// A container component for grouping related content with optional elevation.

const std = @import("std");
const zgui = @import("zgui");
const theme = @import("theme_light.zig");

// =============================================================================
// Card Types and Configuration
// =============================================================================

pub const CardElevation = enum {
    flat,      // No shadow, blends with background
    raised,    // Subtle shadow, slightly elevated
    floating,  // Prominent shadow, appears to float
};

pub const CardConfig = struct {
    title: ?[]const u8 = null,
    subtitle: ?[]const u8 = null,
    elevation: CardElevation = .raised,
    padding: ?[2]f32 = null,
    min_height: ?f32 = null,
    scrollable: bool = false,
};

// =============================================================================
// Card Implementation
// =============================================================================

/// Begin a card container. Must be paired with `end()`.
/// Returns true if the card content should be rendered.
pub fn begin(id: []const u8, size: [2]f32, config: CardConfig) bool {
    const colors = theme.light_colors;
    const spacing = theme.default_spacing;
    const radius = theme.default_radius;
    
    // Determine background color based on elevation
    const bg_color = switch (config.elevation) {
        .flat => colors.surface,
        .raised, .floating => colors.surface_elevated,
    };
    
    // Push card styles
    zgui.pushStyleColor(.child_bg, bg_color);
    zgui.pushStyleColor(.border, colors.border);
    zgui.pushStyleVar(.child_rounding, radius.lg);
    zgui.pushStyleVar(.child_border_size, if (config.elevation == .flat) 1.0 else 0.0);
    
    // Apply custom padding if specified
    const padding = config.padding orelse .{ spacing.md, spacing.md };
    zgui.pushStyleVar(.window_padding, padding);
    
    // Begin the child window
    const flags = zgui.WindowFlags{
        .no_scrollbar = !config.scrollable,
        .no_scroll_with_mouse = !config.scrollable,
    };
    
    const visible = zgui.beginChild(id, .{
        .w = size[0],
        .h = size[1],
        .border = config.elevation == .flat,
        .flags = flags,
    });
    
    // Draw title if provided
    if (visible) {
        if (config.title) |title| {
            drawCardHeader(title, config.subtitle);
        }
    }
    
    return visible;
}

/// End the card container. Must be called after `begin()`.
pub fn end() void {
    zgui.endChild();
    
    // Pop styles in reverse order
    zgui.popStyleVar(3);
    zgui.popStyleColor(2);
}

// =============================================================================
// Card Header
// =============================================================================

fn drawCardHeader(title: []const u8, subtitle: ?[]const u8) void {
    const colors = theme.light_colors;
    const spacing = theme.default_spacing;
    
    // Title
    zgui.pushStyleColor(.text, colors.text_primary);
    zgui.textUnformatted(title);
    zgui.popStyleColor(1);
    
    // Subtitle
    if (subtitle) |sub| {
        zgui.pushStyleColor(.text, colors.text_secondary);
        zgui.textUnformatted(sub);
        zgui.popStyleColor(1);
    }
    
    // Separator
    zgui.dummy(.{ .x = 0, .y = spacing.sm });
    zgui.separator();
    zgui.dummy(.{ .x = 0, .y = spacing.sm });
}

// =============================================================================
// Specialized Card Variants
// =============================================================================

/// A card with a gradient or image background (like the Project Card in the visual guide)
pub fn beginProjectCard(
    id: []const u8,
    size: [2]f32,
    title: []const u8,
) bool {
    const colors = theme.light_colors;
    const radius = theme.default_radius;
    
    // For a project card, we use a custom background
    // In a real implementation, this would support gradient or image backgrounds
    zgui.pushStyleColor(.child_bg, colors.primary);
    zgui.pushStyleColor(.text, colors.text_on_primary);
    zgui.pushStyleVar(.child_rounding, radius.lg);
    zgui.pushStyleVar(.window_padding, .{ 20.0, 20.0 });
    
    const visible = zgui.beginChild(id, .{
        .w = size[0],
        .h = size[1],
        .border = false,
    });
    
    if (visible) {
        // Draw project title
        zgui.textUnformatted(title);
    }
    
    return visible;
}

pub fn endProjectCard() void {
    zgui.endChild();
    zgui.popStyleVar(2);
    zgui.popStyleColor(2);
}

// =============================================================================
// Approval Card (Specialized)
// =============================================================================

pub const ApprovalAction = enum {
    none,
    approve,
    decline,
};

pub fn approvalCard(
    id: []const u8,
    title: []const u8,
    description: []const u8,
) ApprovalAction {
    const colors = theme.light_colors;
    const spacing = theme.default_spacing;
    const radius = theme.default_radius;
    
    var action = ApprovalAction.none;
    
    // Card container
    zgui.pushStyleColor(.child_bg, colors.surface_elevated);
    zgui.pushStyleVar(.child_rounding, radius.md);
    zgui.pushStyleVar(.window_padding, .{ spacing.md, spacing.md });
    
    if (zgui.beginChild(id, .{ .w = 0, .h = 0, .border = false, .flags = .{ .auto_resize_y = true } })) {
        // Title
        zgui.pushStyleColor(.text, colors.text_primary);
        zgui.textUnformatted(title);
        zgui.popStyleColor(1);
        
        // Description
        zgui.pushStyleColor(.text, colors.text_secondary);
        zgui.textWrapped("{s}", .{description});
        zgui.popStyleColor(1);
        
        zgui.dummy(.{ .x = 0, .y = spacing.sm });
        
        // Action buttons
        const button = @import("button.zig");
        const result = button.approvalButtonGroup();
        
        if (result.approve_clicked) {
            action = .approve;
        } else if (result.decline_clicked) {
            action = .decline;
        }
    }
    zgui.endChild();
    
    zgui.popStyleVar(2);
    zgui.popStyleColor(1);
    
    return action;
}
