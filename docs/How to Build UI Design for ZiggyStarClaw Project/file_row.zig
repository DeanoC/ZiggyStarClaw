// ZiggyStarClaw File Row Component
// Displays a file or folder in a list (Sources Management).

const std = @import("std");
const zgui = @import("zgui");
const theme = @import("theme_light.zig");

// =============================================================================
// File Row Types
// =============================================================================

pub const FileType = enum {
    folder,
    document,
    spreadsheet,
    image,
    code,
    pdf,
    generic,

    pub fn getIcon(self: FileType) []const u8 {
        return switch (self) {
            .folder => "📁",
            .document => "📄",
            .spreadsheet => "📊",
            .image => "🖼",
            .code => "💻",
            .pdf => "📕",
            .generic => "📎",
        };
    }

    pub fn getColor(self: FileType) [4]f32 {
        const colors = theme.light_colors;
        return switch (self) {
            .folder => colors.warning,
            .document => colors.primary,
            .spreadsheet => colors.success,
            .image => theme.rgba(156, 39, 176, 255), // Purple
            .code => colors.text_secondary,
            .pdf => colors.error,
            .generic => colors.text_secondary,
        };
    }
};

pub const FileStatus = enum {
    none,
    indexed,    // File has been indexed/processed
    pending,    // Waiting to be processed
    error,      // Processing failed
};

pub const FileRowData = struct {
    name: []const u8,
    file_type: FileType,
    status: FileStatus = .none,
    size: ?[]const u8 = null,
    modified: ?[]const u8 = null,
    expandable: bool = false,
    expanded: bool = false,
};

pub const FileRowAction = enum {
    none,
    clicked,
    double_clicked,
    toggle_expand,
};

// =============================================================================
// File Row Drawing
// =============================================================================

/// Draw a single file row.
pub fn draw(file: *FileRowData, selected: bool) FileRowAction {
    const colors = theme.light_colors;
    const spacing = theme.default_spacing;
    
    var action = FileRowAction.none;
    
    // Row background
    const row_bg = if (selected) theme.rgba(66, 133, 244, 30) else theme.rgba(0, 0, 0, 0);
    
    zgui.pushStyleColor(.header, row_bg);
    zgui.pushStyleColor(.header_hovered, theme.rgba(0, 0, 0, 10));
    zgui.pushStyleColor(.header_active, theme.rgba(0, 0, 0, 20));
    
    // Use Selectable for the row
    const flags = zgui.SelectableFlags{
        .span_all_columns = true,
        .allow_double_click = true,
    };
    
    // Build the row content
    zgui.beginGroup();
    
    // Expand/collapse indicator (if expandable)
    if (file.expandable) {
        const expand_icon = if (file.expanded) "▼" else "▶";
        zgui.pushStyleColor(.text, colors.text_secondary);
        if (zgui.smallButton(expand_icon)) {
            file.expanded = !file.expanded;
            action = .toggle_expand;
        }
        zgui.popStyleColor(1);
        zgui.sameLine(.{});
    }
    
    // File icon
    zgui.pushStyleColor(.text, file.file_type.getColor());
    zgui.textUnformatted(file.file_type.getIcon());
    zgui.popStyleColor(1);
    
    zgui.sameLine(.{ .spacing = spacing.sm });
    
    // File name
    zgui.pushStyleColor(.text, colors.text_primary);
    if (zgui.selectable(file.name, .{ .selected = selected, .flags = flags })) {
        action = .clicked;
        if (zgui.isMouseDoubleClicked(.left)) {
            action = .double_clicked;
        }
    }
    zgui.popStyleColor(1);
    
    // Status indicator (if any)
    if (file.status != .none) {
        zgui.sameLine(.{});
        drawStatusIndicator(file.status);
    }
    
    zgui.endGroup();
    
    zgui.popStyleColor(3);
    
    return action;
}

/// Draw a status indicator (checkmark, spinner, etc.)
fn drawStatusIndicator(status: FileStatus) void {
    const icon = switch (status) {
        .none => return,
        .indexed => "✓",
        .pending => "⏳",
        .error => "⚠",
    };
    
    const color = switch (status) {
        .none => theme.light_colors.text_secondary,
        .indexed => theme.light_colors.success,
        .pending => theme.light_colors.warning,
        .error => theme.light_colors.error,
    };
    
    zgui.pushStyleColor(.text, color);
    zgui.textUnformatted(icon);
    zgui.popStyleColor(1);
}

// =============================================================================
// File List Component
// =============================================================================

pub fn drawFileList(
    files: []FileRowData,
    selected_index: ?usize,
) ?usize {
    const colors = theme.light_colors;
    const spacing = theme.default_spacing;
    
    var new_selection = selected_index;
    
    for (files, 0..) |*file, i| {
        const is_selected = selected_index != null and selected_index.? == i;
        
        zgui.pushID(@intCast(i));
        const action = draw(file, is_selected);
        zgui.popID();
        
        if (action == .clicked or action == .double_clicked) {
            new_selection = i;
        }
        
        // Handle expanded children (for folders)
        if (file.expandable and file.expanded) {
            zgui.indent(.{ .indent_w = spacing.lg });
            // In a real implementation, draw child files here
            zgui.pushStyleColor(.text, colors.text_secondary);
            zgui.textUnformatted("(children would be rendered here)");
            zgui.popStyleColor(1);
            zgui.unindent(.{ .indent_w = spacing.lg });
        }
    }
    
    return new_selection;
}

// =============================================================================
// Source Category Row
// =============================================================================

pub const SourceType = enum {
    local,
    cloud,
    git,

    pub fn getIcon(self: SourceType) []const u8 {
        return switch (self) {
            .local => "📁",
            .cloud => "☁",
            .git => "🔗",
        };
    }
};

pub const SourceCategory = struct {
    name: []const u8,
    source_type: SourceType,
    active: bool = false,
};

pub fn drawSourceCategory(source: SourceCategory, selected: bool) bool {
    const colors = theme.light_colors;
    const spacing = theme.default_spacing;
    
    const bg_color = if (selected) colors.primary else theme.rgba(0, 0, 0, 0);
    const text_color = if (selected) colors.text_on_primary else colors.text_primary;
    
    zgui.pushStyleColor(.header, bg_color);
    zgui.pushStyleColor(.header_hovered, if (selected) colors.primary_light else theme.rgba(0, 0, 0, 10));
    zgui.pushStyleColor(.text, text_color);
    
    zgui.beginGroup();
    
    // Icon
    zgui.textUnformatted(source.source_type.getIcon());
    zgui.sameLine(.{ .spacing = spacing.sm });
    
    // Name
    const clicked = zgui.selectable(source.name, .{ .selected = selected });
    
    zgui.endGroup();
    
    zgui.popStyleColor(3);
    
    return clicked;
}
