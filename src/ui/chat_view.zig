const std = @import("std");
const zgui = @import("zgui");
const types = @import("../protocol/types.zig");

pub fn draw(messages: []const types.ChatMessage, stream_text: ?[]const u8, height: f32) void {
    const clamped = if (height > 60.0) height else 60.0;
    if (zgui.beginChild("ChatHistory", .{ .h = clamped, .child_flags = .{ .border = true } })) {
        const scroll_max = zgui.getScrollMaxY();
        const was_at_bottom = scroll_max <= 0.0 or zgui.getScrollY() >= (scroll_max - 4.0);
        var content_changed = false;

        const last_id_hash = if (messages.len > 0)
            std.hash.Wyhash.hash(0, messages[messages.len - 1].id)
        else
            0;
        const last_len = if (messages.len > 0) messages[messages.len - 1].content.len else 0;

        if (messages.len != last_message_count or last_id_hash != last_last_id_hash or last_len != last_last_len) {
            content_changed = true;
        }

        if (stream_text) |stream| {
            if (stream.len != last_stream_len) {
                content_changed = true;
            }
        } else if (last_stream_len != 0) {
            content_changed = true;
        }

        last_message_count = messages.len;
        last_last_id_hash = last_id_hash;
        last_last_len = last_len;
        last_stream_len = if (stream_text) |stream| stream.len else 0;

        const now_ms = std.time.milliTimestamp();
        var last_role: ?[]const u8 = null;

        for (messages) |msg| {
            if (last_role == null or !std.mem.eql(u8, last_role.?, msg.role)) {
                if (last_role != null) {
                    zgui.spacing();
                }
                renderGroupHeader(msg.role, now_ms, msg.timestamp);
                zgui.separator();
                last_role = msg.role;
            }
            zgui.textWrapped("{s}", .{msg.content});
        }
        if (stream_text) |stream| {
            zgui.separator();
            zgui.textColored(.{ 0.6, 0.7, 1.0, 1.0 }, "[assistant]", .{});
            zgui.sameLine(.{});
            zgui.textWrapped("{s}", .{stream});
        }

        if (content_changed and was_at_bottom) {
            zgui.setScrollHereY(.{ .center_y_ratio = 1.0 });
        }
    }
    zgui.endChild();
}

fn roleColor(role: []const u8) [4]f32 {
    if (std.mem.eql(u8, role, "assistant")) return .{ 0.5, 0.8, 1.0, 1.0 };
    if (std.mem.eql(u8, role, "system")) return .{ 0.8, 0.8, 0.6, 1.0 };
    return .{ 0.7, 0.7, 0.7, 1.0 };
}

fn roleLabel(role: []const u8) []const u8 {
    if (std.mem.eql(u8, role, "assistant")) return "Assistant";
    if (std.mem.eql(u8, role, "user")) return "You";
    if (std.mem.eql(u8, role, "system")) return "System";
    return role;
}

fn renderGroupHeader(role: []const u8, now_ms: i64, ts_ms: i64) void {
    const delta_ms = if (now_ms > ts_ms) now_ms - ts_ms else 0;
    const seconds = @as(u64, @intCast(@divTrunc(delta_ms, 1000)));
    const minutes = seconds / 60;
    const hours = minutes / 60;
    const days = hours / 24;
    const label = roleLabel(role);
    const color = roleColor(role);

    if (seconds < 60) {
        zgui.textColored(color, "{s} · {d}s ago", .{ label, seconds });
        return;
    }
    if (minutes < 60) {
        zgui.textColored(color, "{s} · {d}m ago", .{ label, minutes });
        return;
    }
    if (hours < 24) {
        zgui.textColored(color, "{s} · {d}h ago", .{ label, hours });
        return;
    }
    zgui.textColored(color, "{s} · {d}d ago", .{ label, days });
}

var last_message_count: usize = 0;
var last_last_id_hash: u64 = 0;
var last_last_len: usize = 0;
var last_stream_len: usize = 0;
