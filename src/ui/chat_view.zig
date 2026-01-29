const std = @import("std");
const zgui = @import("zgui");
const types = @import("../protocol/types.zig");

pub fn draw(messages: []const types.ChatMessage, stream_text: ?[]const u8, height: f32) void {
    const clamped = if (height > 60.0) height else 60.0;
    if (zgui.beginChild("ChatHistory", .{ .h = clamped, .child_flags = .{ .border = true } })) {
        for (messages) |msg| {
            zgui.textColored(roleColor(msg.role), "[{s}]", .{msg.role});
            zgui.sameLine(.{});
            zgui.textWrapped("{s}", .{msg.content});
        }
        if (stream_text) |stream| {
            zgui.separator();
            zgui.textColored(.{ 0.6, 0.7, 1.0, 1.0 }, "[assistant]", .{});
            zgui.sameLine(.{});
            zgui.textWrapped("{s}", .{stream});
        }
    }
    zgui.endChild();
}

fn roleColor(role: []const u8) [4]f32 {
    if (std.mem.eql(u8, role, "assistant")) return .{ 0.5, 0.8, 1.0, 1.0 };
    if (std.mem.eql(u8, role, "system")) return .{ 0.8, 0.8, 0.6, 1.0 };
    return .{ 0.7, 0.7, 0.7, 1.0 };
}
