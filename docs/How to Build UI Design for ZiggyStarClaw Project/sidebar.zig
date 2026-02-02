// ZiggyStarClaw Sidebar Component
// The main navigation sidebar (Projects Overview).

const std = @import("std");
const zgui = @import("zgui");
const theme = @import("theme_light.zig");
const button = @import("button.zig");

// =============================================================================
// Sidebar Types
// =============================================================================

pub const NavItem = struct {
    icon: []const u8,
    label: []const u8,
    badge: ?u32 = null,
    active: bool = false,
};

pub const SidebarConfig = struct {
    width: f32 = 240.0,
    collapsed_width: f32 = 60.0,
    header_title: ?[]const u8 = null,
    show_add_button: bool = true,
    add_button_label: []const u8 = "+ New Project",
};

pub const SidebarAction = union(enum) {
    none,
    item_selected: usize,
    add_clicked,
    collapse_toggled,
};

// =============================================================================
// Sidebar Implementation
// =============================================================================

pub fn draw(
    items: []NavItem,
    selected_index: ?usize,
    collapsed: *bool,
    config: SidebarConfig,
) SidebarAction {
    const colors = theme.light_colors;
    const spacing = theme.default_spacing;
    const radius = theme.default_radius;
    
    var action = SidebarAction.none;
    
    const width = if (collapsed.*) config.collapsed_width else config.width;
    
    // Sidebar container
    zgui.pushStyleColor(.child_bg, colors.surface);
    zgui.pushStyleVar(.child_rounding, 0);
    zgui.pushStyleVar(.window_padding, .{ spacing.sm, spacing.md });
    
    if (zgui.beginChild("##sidebar", .{ .w = width, .h = 0, .border = false })) {
        // Header
        if (!collapsed.*) {
            if (config.header_title) |title| {
                zgui.pushStyleColor(.text, colors.text_primary);
                zgui.textUnformatted(title);
                zgui.popStyleColor(1);
                zgui.dummy(.{ .x = 0, .y = spacing.sm });
            }
        }
        
        // Navigation items
        for (items, 0..) |item, i| {
            const is_selected = selected_index != null and selected_index.? == i;
            
            zgui.pushID(@intCast(i));
            if (drawNavItem(item, is_selected, collapsed.*)) {
                action = .{ .item_selected = i };
            }
            zgui.popID();
        }
        
        // Spacer
        zgui.dummy(.{ .x = 0, .y = spacing.md });
        
        // Add button
        if (config.show_add_button and !collapsed.*) {
            zgui.pushStyleColor(.button, theme.rgba(0, 0, 0, 0));
            zgui.pushStyleColor(.button_hovered, theme.rgba(0, 0, 0, 10));
            zgui.pushStyleColor(.text, colors.primary);
            zgui.pushStyleVar(.frame_padding, .{ spacing.sm, spacing.xs });
            
            if (zgui.button(config.add_button_label, .{ .w = -1 })) {
                action = .add_clicked;
            }
            
            zgui.popStyleVar(1);
            zgui.popStyleColor(3);
        }
    }
    zgui.endChild();
    
    zgui.popStyleVar(2);
    zgui.popStyleColor(1);
    
    return action;
}

/// Draw a single navigation item.
fn drawNavItem(item: NavItem, selected: bool, collapsed: bool) bool {
    const colors = theme.light_colors;
    const spacing = theme.default_spacing;
    const radius = theme.default_radius;
    
    // Item background
    const bg_color = if (selected) colors.primary else theme.rgba(0, 0, 0, 0);
    const bg_hovered = if (selected) colors.primary_light else theme.rgba(0, 0, 0, 10);
    const text_color = if (selected) colors.text_on_primary else colors.text_primary;
    
    zgui.pushStyleColor(.header, bg_color);
    zgui.pushStyleColor(.header_hovered, bg_hovered);
    zgui.pushStyleColor(.header_active, if (selected) colors.primary_dark else theme.rgba(0, 0, 0, 20));
    zgui.pushStyleVar(.frame_rounding, radius.md);
    zgui.pushStyleVar(.frame_padding, .{ spacing.sm, spacing.xs });
    
    var clicked = false;
    
    zgui.beginGroup();
    {
        // Icon
        zgui.pushStyleColor(.text, if (selected) colors.text_on_primary else colors.text_secondary);
        zgui.textUnformatted(item.icon);
        zgui.popStyleColor(1);
        
        if (!collapsed) {
            zgui.sameLine(.{ .spacing = spacing.sm });
            
            // Label
            zgui.pushStyleColor(.text, text_color);
            clicked = zgui.selectable(item.label, .{
                .selected = selected,
                .flags = .{ .span_all_columns = true },
            });
            zgui.popStyleColor(1);
            
            // Badge (if any)
            if (item.badge) |count| {
                zgui.sameLine(.{});
                drawBadge(count, selected);
            }
            
            // Active indicator
            if (item.active and !selected) {
                zgui.sameLine(.{});
                zgui.pushStyleColor(.text, colors.success);
                zgui.textUnformatted("●");
                zgui.popStyleColor(1);
            }
        } else {
            // In collapsed mode, just make the icon clickable
            if (zgui.isItemHovered(.{}) and zgui.isMouseClicked(.left)) {
                clicked = true;
            }
        }
    }
    zgui.endGroup();
    
    zgui.popStyleVar(2);
    zgui.popStyleColor(3);
    
    return clicked;
}

/// Draw a notification badge.
fn drawBadge(count: u32, on_primary: bool) void {
    const colors = theme.light_colors;
    const radius = theme.default_radius;
    
    const bg_color = if (on_primary) colors.text_on_primary else colors.error;
    const text_color = if (on_primary) colors.primary else colors.text_on_primary;
    
    zgui.pushStyleColor(.button, bg_color);
    zgui.pushStyleColor(.button_hovered, bg_color);
    zgui.pushStyleColor(.button_active, bg_color);
    zgui.pushStyleColor(.text, text_color);
    zgui.pushStyleVar(.frame_padding, .{ 6.0, 1.0 });
    zgui.pushStyleVar(.frame_rounding, radius.full);
    
    var buf: [16]u8 = undefined;
    const label = std.fmt.bufPrint(&buf, "{d}", .{count}) catch "?";
    _ = zgui.smallButton(label);
    
    zgui.popStyleVar(2);
    zgui.popStyleColor(4);
}

// =============================================================================
// Header Bar Component
// =============================================================================

pub const HeaderAction = enum {
    none,
    search_clicked,
    notifications_clicked,
};

pub fn drawHeaderBar(title: []const u8, notification_count: u32) HeaderAction {
    const colors = theme.light_colors;
    const spacing = theme.default_spacing;
    
    var action = HeaderAction.none;
    
    zgui.pushStyleColor(.child_bg, colors.background);
    zgui.pushStyleVar(.window_padding, .{ spacing.md, spacing.sm });
    
    if (zgui.beginChild("##header", .{ .w = 0, .h = 48.0, .border = false })) {
        // Title
        zgui.pushStyleColor(.text, colors.text_primary);
        zgui.textUnformatted(title);
        zgui.popStyleColor(1);
        
        // Right-aligned buttons
        const avail = zgui.getContentRegionAvail();
        zgui.sameLine(.{ .offset_from_start_x = avail[0] - 80.0 });
        
        // Search button
        if (button.iconButton("🔍", "Search")) {
            action = .search_clicked;
        }
        
        zgui.sameLine(.{});
        
        // Notifications button with badge
        zgui.beginGroup();
        if (button.iconButton("🔔", "Notifications")) {
            action = .notifications_clicked;
        }
        if (notification_count > 0) {
            // Overlay badge
            const pos = zgui.getCursorScreenPos();
            const draw_list = zgui.getWindowDrawList();
            // Draw badge circle
            draw_list.addCircleFilled(
                .{ pos[0] - 8.0, pos[1] - 24.0 },
                8.0,
                zgui.colorConvertFloat4ToU32(colors.error),
                12,
            );
        }
        zgui.endGroup();
    }
    zgui.endChild();
    
    zgui.popStyleVar(1);
    zgui.popStyleColor(1);
    
    return action;
}
