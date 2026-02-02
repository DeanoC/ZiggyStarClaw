const std = @import("std");
const zgui = @import("zgui");
const state = @import("../client/state.zig");
const types = @import("../protocol/types.zig");
const theme = @import("theme.zig");
const components = @import("components/components.zig");

pub const SourcesViewAction = struct {
    select_session: ?[]u8 = null,
};

var selected_source_index: ?usize = null;
var selected_file_index: ?usize = null;
var split_state = components.layout.split_pane.SplitState{ .size = 240.0 };

pub fn draw(allocator: std.mem.Allocator, ctx: *state.ClientContext) SourcesViewAction {
    var action = SourcesViewAction{};
    const opened = zgui.beginChild("SourcesView", .{ .h = 0.0, .child_flags = .{ .border = true } });
    if (opened) {
        const t = theme.activeTheme();
        if (components.layout.header_bar.begin(.{ .title = "Sources", .subtitle = "Indexed Content" })) {
            if (components.core.button.draw("Add Source", .{ .variant = .secondary, .size = .small })) {
                // Placeholder for future action.
            }
            components.layout.header_bar.end();
        }

        zgui.dummy(.{ .w = 0.0, .h = t.spacing.sm });

        var sources_buf: [24]components.composite.source_browser.Source = undefined;
        var sources_map: [24]?usize = undefined;
        var sources_len: usize = 0;

        addSource(&sources_buf, &sources_map, &sources_len, .{
            .name = "Local Files",
            .source_type = .local,
            .connected = true,
        }, null);

        for (ctx.sessions.items, 0..) |session, idx| {
            if (sources_len >= sources_buf.len) break;
            const name = displayName(session);
            addSource(&sources_buf, &sources_map, &sources_len, .{
                .name = name,
                .source_type = .local,
                .connected = ctx.current_session != null and std.mem.eql(u8, ctx.current_session.?, session.key),
            }, idx);
        }

        addSource(&sources_buf, &sources_map, &sources_len, .{
            .name = "Cloud Drives",
            .source_type = .cloud,
            .connected = false,
        }, null);
        addSource(&sources_buf, &sources_map, &sources_len, .{
            .name = "Code Repos",
            .source_type = .git,
            .connected = false,
        }, null);

        const active_index = resolveSelectedIndex(ctx, sources_map[0..sources_len]);

        var files_buf: [16]components.composite.source_browser.FileEntry = undefined;
        var fallback = fallbackFiles();
        var files = collectFiles(ctx.messages.items, &files_buf);
        if (active_index == null or sources_map[active_index.?] == null) {
            files = fallback[0..];
        }

        const current_path = if (active_index != null) blk: {
            if (sources_map[active_index.?]) |session_index| {
                break :blk ctx.sessions.items[session_index].key;
            }
            break :blk sources_buf[active_index.?].name;
        } else "";

        const source_action = components.composite.source_browser.draw(.{
            .id = "sources_browser",
            .sources = sources_buf[0..sources_len],
            .selected_source = active_index,
            .current_path = current_path,
            .files = files,
            .selected_file = selected_file_index,
            .split_state = &split_state,
        });

        if (source_action.select_source) |idx| {
            if (idx < sources_len) {
                selected_source_index = idx;
                if (sources_map[idx]) |session_index| {
                    const session_key = ctx.sessions.items[session_index].key;
                    action.select_session = allocator.dupe(u8, session_key) catch null;
                }
            }
        }

        if (source_action.select_file) |idx| {
            selected_file_index = idx;
        }
    }
    zgui.endChild();
    return action;
}

fn addSource(
    buf: []components.composite.source_browser.Source,
    map: []?usize,
    len: *usize,
    source: components.composite.source_browser.Source,
    session_index: ?usize,
) void {
    if (len.* >= buf.len) return;
    buf[len.*] = source;
    map[len.*] = session_index;
    len.* += 1;
}

fn resolveSelectedIndex(ctx: *state.ClientContext, map: []?usize) ?usize {
    if (map.len == 0) {
        selected_source_index = null;
        return null;
    }
    if (selected_source_index) |idx| {
        if (idx < map.len) return idx;
        selected_source_index = null;
    }
    if (ctx.current_session) |key| {
        for (map, 0..) |session_idx, idx| {
            if (session_idx) |value| {
                if (std.mem.eql(u8, ctx.sessions.items[value].key, key)) {
                    selected_source_index = idx;
                    return idx;
                }
            }
        }
    }
    selected_source_index = 0;
    return 0;
}

fn displayName(session: types.Session) []const u8 {
    return session.display_name orelse session.label orelse session.key;
}

fn collectFiles(
    messages: []const types.ChatMessage,
    buf: []components.composite.source_browser.FileEntry,
) []components.composite.source_browser.FileEntry {
    var len: usize = 0;
    var index: usize = messages.len;
    while (index > 0 and len < buf.len) : (index -= 1) {
        const message = messages[index - 1];
        if (message.attachments) |attachments| {
            for (attachments) |attachment| {
                if (len >= buf.len) break;
                const name = attachment.name orelse attachment.url;
                buf[len] = .{
                    .name = name,
                    .language = attachment.kind,
                    .status = message.role,
                    .dirty = false,
                };
                len += 1;
            }
        }
    }
    return buf[0..len];
}

fn fallbackFiles() [4]components.composite.source_browser.FileEntry {
    return .{
        .{ .name = "proposal.docx", .language = "docx", .status = "indexed" },
        .{ .name = "data.csv", .language = "csv", .status = "indexed" },
        .{ .name = "image.png", .language = "png", .status = "pending" },
        .{ .name = "notes.md", .language = "md", .status = "indexed" },
    };
}
