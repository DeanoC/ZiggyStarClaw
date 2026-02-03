const std = @import("std");
const zgui = @import("zgui");
const theme = @import("../../theme.zig");
const colors = @import("../../theme/colors.zig");
const components = @import("../components.zig");

pub const SourceType = enum {
    local,
    cloud,
    git,
};

pub const Source = struct {
    name: []const u8,
    source_type: SourceType = .local,
    connected: bool = true,
};

pub const FileEntry = struct {
    name: []const u8,
    language: ?[]const u8 = null,
    status: ?[]const u8 = null,
    dirty: bool = false,
};

pub const Args = struct {
    id: []const u8 = "source_browser",
    sources: []const Source = &[_]Source{},
    selected_source: ?usize = null,
    current_path: []const u8 = "",
    files: []const FileEntry = &[_]FileEntry{},
    selected_file: ?usize = null,
    sections: []const Section = &[_]Section{},
    split_state: ?*components.layout.split_pane.SplitState = null,
    show_add_source: bool = false,
};

pub const Action = struct {
    select_source: ?usize = null,
    select_file: ?usize = null,
    add_source: bool = false,
};

pub const Section = struct {
    name: []const u8,
    files: []const FileEntry,
    start_index: usize,
    expanded: *bool,
};

var default_split_state = components.layout.split_pane.SplitState{ .size = 220.0 };

fn sourceTypeLabel(source_type: SourceType) []const u8 {
    return switch (source_type) {
        .local => "local",
        .cloud => "cloud",
        .git => "git",
    };
}

fn sourceGroupLabel(source_type: SourceType) []const u8 {
    return switch (source_type) {
        .local => "Local Sources",
        .cloud => "Cloud Drives",
        .git => "Code Repos",
    };
}

fn drawFileRow(file: FileEntry, selected: bool, t: *const theme.Theme) bool {
    const cursor_screen = zgui.getCursorScreenPos();
    const cursor_local = zgui.getCursorPos();
    const avail = zgui.getContentRegionAvail();
    const row_height = zgui.getFrameHeight() + t.spacing.xs;
    _ = zgui.invisibleButton("##file_row", .{ .w = avail[0], .h = row_height });
    const hovered = zgui.isItemHovered(.{});
    const clicked = zgui.isItemClicked(.left);

    const draw_list = zgui.getWindowDrawList();
    if (selected or hovered) {
        const base = if (selected) t.colors.primary else t.colors.surface;
        const alpha: f32 = if (selected) 0.12 else 0.08;
        draw_list.addRectFilled(.{
            .pmin = cursor_screen,
            .pmax = .{ cursor_screen[0] + avail[0], cursor_screen[1] + row_height },
            .col = zgui.colorConvertFloat4ToU32(colors.withAlpha(base, alpha)),
            .rounding = t.radius.sm,
        });
    }

    const icon_size = row_height - t.spacing.xs * 2.0;
    const icon_pos = .{ cursor_screen[0] + t.spacing.xs, cursor_screen[1] + t.spacing.xs };
    draw_list.addRectFilled(.{
        .pmin = icon_pos,
        .pmax = .{ icon_pos[0] + icon_size, icon_pos[1] + icon_size },
        .col = zgui.colorConvertFloat4ToU32(colors.withAlpha(t.colors.primary, 0.18)),
        .rounding = 2.0,
    });

    var text_buf: [256]u8 = undefined;
    const name = if (file.language != null)
        std.fmt.bufPrint(&text_buf, "{s} ({s})", .{ file.name, file.language.? }) catch file.name
    else
        file.name;
    const text_pos = .{ icon_pos[0] + icon_size + t.spacing.sm, cursor_screen[1] + t.spacing.xs };
    draw_list.addText(text_pos, zgui.colorConvertFloat4ToU32(t.colors.text_primary), "{s}", .{name});

    if (file.status) |status| {
        if (std.ascii.eqlIgnoreCase(status, "indexed")) {
            drawCheckmark(draw_list, t, cursor_screen, avail[0], row_height);
        } else {
            drawStatusBadge(draw_list, t, status, cursor_screen, avail[0], row_height);
        }
    }

    zgui.setCursorPos(.{ cursor_local[0], cursor_local[1] + row_height + t.spacing.xs });
    zgui.dummy(.{ .w = 0.0, .h = 0.0 });
    return clicked;
}

fn drawStatusBadge(
    draw_list: zgui.DrawList,
    t: *const theme.Theme,
    label: []const u8,
    row_pos: [2]f32,
    row_width: f32,
    row_height: f32,
) void {
    const label_size = zgui.calcTextSize(label, .{});
    const padding = .{ t.spacing.xs, t.spacing.xs * 0.5 };
    const badge_size = .{
        label_size[0] + padding[0] * 2.0,
        label_size[1] + padding[1] * 2.0,
    };
    const x = row_pos[0] + row_width - badge_size[0] - t.spacing.sm;
    const y = row_pos[1] + (row_height - badge_size[1]) * 0.5;
    const variant = if (std.ascii.eqlIgnoreCase(label, "indexed"))
        t.colors.success
    else if (std.ascii.eqlIgnoreCase(label, "pending"))
        t.colors.warning
    else
        t.colors.primary;
    const bg = colors.withAlpha(variant, 0.18);
    const border = colors.withAlpha(variant, 0.4);
    draw_list.addRectFilled(.{
        .pmin = .{ x, y },
        .pmax = .{ x + badge_size[0], y + badge_size[1] },
        .col = zgui.colorConvertFloat4ToU32(bg),
        .rounding = t.radius.lg,
    });
    draw_list.addRect(.{
        .pmin = .{ x, y },
        .pmax = .{ x + badge_size[0], y + badge_size[1] },
        .col = zgui.colorConvertFloat4ToU32(border),
        .rounding = t.radius.lg,
    });
    draw_list.addText(
        .{ x + padding[0], y + padding[1] },
        zgui.colorConvertFloat4ToU32(variant),
        "{s}",
        .{label},
    );
}

fn drawCheckmark(draw_list: zgui.DrawList, t: *const theme.Theme, row_pos: [2]f32, row_width: f32, row_height: f32) void {
    const size = row_height * 0.35;
    const x = row_pos[0] + row_width - size - t.spacing.sm;
    const y = row_pos[1] + (row_height - size) * 0.5;
    const color = zgui.colorConvertFloat4ToU32(t.colors.success);
    draw_list.addLine(.{
        .p1 = .{ x, y + size * 0.6 },
        .p2 = .{ x + size * 0.4, y + size },
        .col = color,
        .thickness = 2.0,
    });
    draw_list.addLine(.{
        .p1 = .{ x + size * 0.4, y + size },
        .p2 = .{ x + size, y },
        .col = color,
        .thickness = 2.0,
    });
}

pub fn draw(args: Args) Action {
    var action = Action{};
    const t = theme.activeTheme();
    var split_state = args.split_state orelse &default_split_state;
    if (split_state.size == 0.0) {
        split_state.size = 220.0;
    }

    const split_args = components.layout.split_pane.Args{
        .id = args.id,
        .axis = .vertical,
        .primary_size = split_state.size,
        .min_primary = 180.0,
        .min_secondary = 220.0,
        .border = true,
        .padded = true,
    };

    components.layout.split_pane.begin(split_args, split_state);
    if (components.layout.split_pane.beginPrimary(split_args, split_state)) {
        theme.push(.heading);
        zgui.text("Sources", .{});
        theme.pop();
        zgui.dummy(.{ .w = 0.0, .h = t.spacing.xs });

        var sources_id_buf: [96]u8 = undefined;
        const sources_id = std.fmt.bufPrint(&sources_id_buf, "{s}_sources", .{args.id}) catch "sources";
        if (components.layout.scroll_area.begin(.{ .id = sources_id, .height = 0.0, .border = true })) {
            if (args.sources.len == 0) {
                zgui.textDisabled("No sources available.", .{});
            } else {
                var last_type: ?SourceType = null;
                for (args.sources, 0..) |source, idx| {
                    zgui.pushIntId(@intCast(idx));
                    defer zgui.popId();
                    if (last_type == null or last_type.? != source.source_type) {
                        if (last_type != null) {
                            zgui.dummy(.{ .w = 0.0, .h = t.spacing.xs });
                        }
                        theme.push(.heading);
                        zgui.text("{s}", .{sourceGroupLabel(source.source_type)});
                        theme.pop();
                        zgui.separator();
                        last_type = source.source_type;
                    }
                    var label_buf: [196]u8 = undefined;
                    const status = if (source.connected) "connected" else "offline";
                    const label = std.fmt.bufPrint(
                        &label_buf,
                        "{s} ({s}, {s})",
                        .{ source.name, sourceTypeLabel(source.source_type), status },
                    ) catch source.name;
                    const selected = args.selected_source != null and args.selected_source.? == idx;
                    if (components.data.list_item.draw(.{
                        .label = label,
                        .selected = selected,
                    })) {
                        action.select_source = idx;
                    }
                }
            }
        }
        components.layout.scroll_area.end();
        if (args.show_add_source) {
            zgui.dummy(.{ .w = 0.0, .h = t.spacing.sm });
            if (components.core.button.draw("+ Add Source", .{ .variant = .secondary, .size = .small })) {
                action.add_source = true;
            }
        }
    }
    components.layout.split_pane.endPrimary();

    components.layout.split_pane.handleSplitter(split_args, split_state);

    if (components.layout.split_pane.beginSecondary(split_args, split_state)) {
        if (args.current_path.len > 0) {
            if (components.core.button.draw("Project Files ▾", .{ .variant = .secondary, .size = .small })) {}
            zgui.sameLine(.{ .spacing = t.spacing.sm });
            zgui.textDisabled("{s}", .{args.current_path});
            zgui.separator();
        }

        var files_id_buf: [96]u8 = undefined;
        const files_id = std.fmt.bufPrint(&files_id_buf, "{s}_files", .{args.id}) catch "files";
        if (components.layout.scroll_area.begin(.{ .id = files_id, .height = 0.0, .border = true })) {
            if (args.sections.len > 0) {
                for (args.sections, 0..) |section, section_idx| {
                    zgui.pushIntId(@intCast(section_idx));
                    defer zgui.popId();
                    var header_buf: [128]u8 = undefined;
                    const header_label = std.fmt.bufPrint(
                        &header_buf,
                        "{s} {s}",
                        .{ if (section.expanded.*) "v" else ">", section.name },
                    ) catch section.name;
                    const header_z = zgui.formatZ("{s}##section_{s}", .{ header_label, section.name });
                    theme.push(.heading);
                    if (zgui.selectable(header_z, .{ .selected = section.expanded.* })) {
                        section.expanded.* = !section.expanded.*;
                    }
                    theme.pop();
                    if (section.expanded.*) {
                        for (section.files, 0..) |file, idx| {
                            zgui.pushIntId(@intCast(idx));
                            defer zgui.popId();
                            const global_index = section.start_index + idx;
                            const selected = args.selected_file != null and args.selected_file.? == global_index;
                            if (drawFileRow(file, selected, t)) {
                                action.select_file = global_index;
                            }
                        }
                        if (section_idx + 1 < args.sections.len) {
                            zgui.dummy(.{ .w = 0.0, .h = t.spacing.xs });
                        }
                    }
                }
            } else if (args.files.len == 0) {
                zgui.textDisabled("No files in this source.", .{});
            } else {
                for (args.files, 0..) |file, idx| {
                    zgui.pushIntId(@intCast(idx));
                    defer zgui.popId();
                    const selected = args.selected_file != null and args.selected_file.? == idx;
                    if (drawFileRow(file, selected, t)) {
                        action.select_file = idx;
                    }
                }
            }
        }
        components.layout.scroll_area.end();
    }
    components.layout.split_pane.endSecondary();
    components.layout.split_pane.end();
    return action;
}
