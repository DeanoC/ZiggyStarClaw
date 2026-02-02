const std = @import("std");
const zgui = @import("zgui");
const state = @import("../../client/state.zig");
const types = @import("../../protocol/types.zig");
const components = @import("../components/components.zig");
const session_list = @import("../session_list.zig");
const theme = @import("../theme.zig");

pub const SessionPanelAction = session_list.SessionAction;

var split_state = components.layout.split_pane.SplitState{ .size = 260.0 };
var selected_file_index: ?usize = null;

pub fn draw(
    allocator: std.mem.Allocator,
    ctx: *state.ClientContext,
) SessionPanelAction {
    var action = SessionPanelAction{};
    const t = theme.activeTheme();
    const avail = zgui.getContentRegionAvail();
    if (split_state.size == 0.0) {
        split_state.size = @min(280.0, avail[0] * 0.35);
    }

    const split_args = components.layout.split_pane.Args{
        .id = "sessions_panel",
        .axis = .vertical,
        .primary_size = split_state.size,
        .min_primary = 220.0,
        .min_secondary = 260.0,
        .border = false,
        .padded = false,
    };

    components.layout.split_pane.begin(split_args, &split_state);
    if (components.layout.split_pane.beginPrimary(split_args, &split_state)) {
        action = session_list.draw(
            allocator,
            ctx.sessions.items,
            ctx.current_session,
            ctx.sessions_loading,
        );
        if (action.selected_key != null) {
            selected_file_index = null;
        }
    }
    components.layout.split_pane.endPrimary();
    components.layout.split_pane.handleSplitter(split_args, &split_state);
    if (components.layout.split_pane.beginSecondary(split_args, &split_state)) {
        if (components.layout.scroll_area.begin(.{ .id = "SessionDetails", .border = false })) {
            drawSessionDetails(allocator, ctx, t, &action);
        }
        components.layout.scroll_area.end();
    }
    components.layout.split_pane.endSecondary();
    components.layout.split_pane.end();

    return action;
}

fn drawSessionDetails(
    allocator: std.mem.Allocator,
    ctx: *state.ClientContext,
    t: *const theme.Theme,
    action: *SessionPanelAction,
) void {
    const selected_index = resolveSelectedSessionIndex(ctx);
    if (selected_index == null) {
        zgui.textDisabled("Select a session to see details.", .{});
        return;
    }

    const session = ctx.sessions.items[selected_index.?];
    const name = displayName(session);
    const description = session.label orelse session.kind;

    var categories_buf: [3]components.composite.project_card.Category = undefined;
    var categories_len: usize = 0;
    if (session.kind) |kind| {
        categories_buf[categories_len] = .{ .name = kind, .variant = .primary };
        categories_len += 1;
    }
    if (ctx.current_session != null and std.mem.eql(u8, ctx.current_session.?, session.key)) {
        categories_buf[categories_len] = .{ .name = "active", .variant = .success };
        categories_len += 1;
    }

    var artifacts_buf: [6]components.composite.project_card.Artifact = undefined;
    const artifacts = collectArtifacts(ctx.messages.items, &artifacts_buf);

    components.composite.project_card.draw(.{
        .id = "session_project_card",
        .name = name,
        .description = description,
        .categories = categories_buf[0..categories_len],
        .recent_artifacts = artifacts,
    });

    zgui.dummy(.{ .w = 0.0, .h = t.spacing.md });

    var sources_buf: [16]components.composite.source_browser.Source = undefined;
    var source_map: [16]usize = undefined;
    var sources_len: usize = 0;
    var selected_source: ?usize = null;
    for (ctx.sessions.items, 0..) |entry, idx| {
        if (sources_len >= sources_buf.len) break;
        sources_buf[sources_len] = .{
            .name = displayName(entry),
            .source_type = .local,
            .connected = ctx.current_session != null and std.mem.eql(u8, ctx.current_session.?, entry.key),
        };
        source_map[sources_len] = idx;
        if (selected_index.? == idx) {
            selected_source = sources_len;
        }
        sources_len += 1;
    }
    if (selected_source == null and sources_len > 0) {
        selected_source = 0;
    }

    var files_buf: [12]components.composite.source_browser.FileEntry = undefined;
    const files = collectFiles(ctx.messages.items, &files_buf);

    const source_action = components.composite.source_browser.draw(.{
        .id = "session_source_browser",
        .sources = sources_buf[0..sources_len],
        .selected_source = selected_source,
        .current_path = session.key,
        .files = files,
        .selected_file = selected_file_index,
    });
    if (source_action.select_source) |src_index| {
        if (src_index < sources_len) {
            const session_index = source_map[src_index];
            action.selected_key = allocator.dupe(u8, ctx.sessions.items[session_index].key) catch null;
            selected_file_index = null;
        }
    }
    if (source_action.select_file) |file_index| {
        if (file_index < files.len) {
            selected_file_index = file_index;
        }
    }
}

fn resolveSelectedSessionIndex(ctx: *state.ClientContext) ?usize {
    if (ctx.sessions.items.len == 0) return null;
    if (ctx.current_session) |key| {
        if (findSessionIndex(ctx.sessions.items, key)) |index| return index;
    }
    return 0;
}

fn findSessionIndex(sessions: []const types.Session, key: []const u8) ?usize {
    for (sessions, 0..) |session, idx| {
        if (std.mem.eql(u8, session.key, key)) return idx;
    }
    return null;
}

fn displayName(session: types.Session) []const u8 {
    return session.display_name orelse session.label orelse session.key;
}

fn collectArtifacts(
    messages: []const types.ChatMessage,
    buf: []components.composite.project_card.Artifact,
) []components.composite.project_card.Artifact {
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
                    .file_type = attachment.kind,
                    .status = message.role,
                };
                len += 1;
            }
        }
    }
    return buf[0..len];
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
