// ZiggyStarClaw Progress Step Component
// Displays a single step in a multi-step task flow (Run Inspector).

const std = @import("std");
const zgui = @import("zgui");
const theme = @import("theme_light.zig");

// =============================================================================
// Progress Step Types
// =============================================================================

pub const StepState = enum {
    pending,      // Not yet started
    in_progress,  // Currently executing
    complete,     // Successfully finished
    error,        // Failed with error
};

pub const ProgressStep = struct {
    number: u32,
    label: []const u8,
    state: StepState,
    detail: ?[]const u8 = null,
};

// =============================================================================
// Icon Helpers
// =============================================================================

fn getStateIcon(state: StepState) []const u8 {
    return switch (state) {
        .pending => "○",      // Empty circle
        .in_progress => "◐",  // Half-filled circle (or use spinner)
        .complete => "✓",     // Checkmark
        .error => "✗",        // X mark
    };
}

fn getStateColor(state: StepState) [4]f32 {
    const colors = theme.light_colors;
    return switch (state) {
        .pending => colors.text_disabled,
        .in_progress => colors.warning,
        .complete => colors.success,
        .error => colors.error,
    };
}

// =============================================================================
// Progress Step Drawing
// =============================================================================

/// Draw a single progress step.
pub fn draw(step: ProgressStep) void {
    const colors = theme.light_colors;
    const spacing = theme.default_spacing;
    
    const state_color = getStateColor(step.state);
    const icon = getStateIcon(step.state);
    
    // Begin horizontal layout
    zgui.beginGroup();
    
    // Step indicator (icon)
    zgui.pushStyleColor(.text, state_color);
    zgui.textUnformatted(icon);
    zgui.popStyleColor(1);
    
    zgui.sameLine(.{ .spacing = spacing.sm });
    
    // Step number and label
    zgui.beginGroup();
    {
        // Label
        const label_color = if (step.state == .pending) colors.text_disabled else colors.text_primary;
        zgui.pushStyleColor(.text, label_color);
        zgui.text("{d}. {s}", .{ step.number, step.label });
        zgui.popStyleColor(1);
        
        // Status badge
        zgui.sameLine(.{});
        drawStatusBadge(step.state);
        
        // Detail text (if any)
        if (step.detail) |detail| {
            zgui.pushStyleColor(.text, colors.text_secondary);
            zgui.textUnformatted(detail);
            zgui.popStyleColor(1);
        }
    }
    zgui.endGroup();
    
    zgui.endGroup();
}

/// Draw a status badge (e.g., "Complete", "In Progress")
fn drawStatusBadge(state: StepState) void {
    const colors = theme.light_colors;
    const radius = theme.default_radius;
    
    const badge_text = switch (state) {
        .pending => return, // No badge for pending
        .in_progress => "In Progress",
        .complete => "Complete",
        .error => "Error",
    };
    
    const badge_bg = switch (state) {
        .pending => colors.surface,
        .in_progress => theme.rgba(251, 188, 4, 40),  // Warning with alpha
        .complete => theme.rgba(52, 168, 83, 40),    // Success with alpha
        .error => theme.rgba(234, 67, 53, 40),       // Error with alpha
    };
    
    const badge_text_color = getStateColor(state);
    
    // Draw badge as a small colored label
    zgui.pushStyleColor(.button, badge_bg);
    zgui.pushStyleColor(.button_hovered, badge_bg);
    zgui.pushStyleColor(.button_active, badge_bg);
    zgui.pushStyleColor(.text, badge_text_color);
    zgui.pushStyleVar(.frame_padding, .{ 8.0, 2.0 });
    zgui.pushStyleVar(.frame_rounding, radius.full);
    
    _ = zgui.smallButton(badge_text);
    
    zgui.popStyleVar(2);
    zgui.popStyleColor(4);
}

// =============================================================================
// Progress Step List
// =============================================================================

/// Draw a vertical list of progress steps with connecting lines.
pub fn drawStepList(steps: []const ProgressStep) void {
    const colors = theme.light_colors;
    const spacing = theme.default_spacing;
    
    for (steps, 0..) |step, i| {
        draw(step);
        
        // Draw connecting line (except for last step)
        if (i < steps.len - 1) {
            // Vertical spacing with line
            zgui.dummy(.{ .x = 0, .y = spacing.xs });
            
            // Draw vertical line
            const cursor_pos = zgui.getCursorScreenPos();
            const draw_list = zgui.getWindowDrawList();
            
            const line_x = cursor_pos[0] + 6.0; // Align with icon center
            const line_start_y = cursor_pos[1];
            const line_end_y = line_start_y + spacing.md;
            
            draw_list.addLine(
                .{ line_x, line_start_y },
                .{ line_x, line_end_y },
                zgui.colorConvertFloat4ToU32(colors.border),
                1.0,
            );
            
            zgui.dummy(.{ .x = 0, .y = spacing.md });
        }
    }
}

// =============================================================================
// Task Progress Panel (Composite)
// =============================================================================

pub const TaskProgressConfig = struct {
    title: []const u8 = "Task Progress",
    show_logs_button: bool = true,
};

pub const TaskProgressAction = enum {
    none,
    view_logs,
};

/// Draw a complete task progress panel (as shown in Run Inspector).
pub fn drawTaskProgressPanel(
    steps: []const ProgressStep,
    current_step_detail: ?[]const u8,
    config: TaskProgressConfig,
) TaskProgressAction {
    const colors = theme.light_colors;
    const spacing = theme.default_spacing;
    
    var action = TaskProgressAction.none;
    
    // Panel header
    zgui.pushStyleColor(.text, colors.text_primary);
    zgui.textUnformatted(config.title);
    zgui.popStyleColor(1);
    
    zgui.separator();
    zgui.dummy(.{ .x = 0, .y = spacing.sm });
    
    // Step list
    drawStepList(steps);
    
    zgui.dummy(.{ .x = 0, .y = spacing.md });
    zgui.separator();
    zgui.dummy(.{ .x = 0, .y = spacing.sm });
    
    // Current step details section
    zgui.pushStyleColor(.text, colors.text_primary);
    zgui.textUnformatted("Current Step Details");
    zgui.popStyleColor(1);
    
    if (current_step_detail) |detail| {
        zgui.pushStyleColor(.text, colors.text_secondary);
        zgui.textWrapped("{s}", .{detail});
        zgui.popStyleColor(1);
    }
    
    zgui.dummy(.{ .x = 0, .y = spacing.md });
    
    // View Logs button
    if (config.show_logs_button) {
        const button = @import("button.zig");
        if (button.secondary("View Logs")) {
            action = .view_logs;
        }
    }
    
    return action;
}
