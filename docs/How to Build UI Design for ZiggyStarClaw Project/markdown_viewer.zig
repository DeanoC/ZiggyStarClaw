const std = @import("std");
const zgui = @import("zgui");

pub const MarkdownViewer = struct {
    allocator: std.mem.Allocator,
    text: []const u8,

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .text = "",
        };
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }

    pub fn setText(self: *Self, text: []const u8) void {
        self.text = text;
    }

    pub fn draw(self: *Self) void {
        // This is a simplified renderer. A real implementation would use a proper
        // parser (like MD4C) to build an AST and then render the nodes.

        var lines = std.mem.split(u8, self.text, "\n");
        while (lines.next()) |line| {
            const trimmed_line = std.mem.trim(u8, line, " \t\r");
            if (trimmed_line.len == 0) continue;

            if (std.mem.startsWith(u8, trimmed_line, "###")) {
                zgui.pushFont(zgui.getIO().font_default); // Placeholder for H3 font
                zgui.text(trimmed_line[4..]);
                zgui.popFont();
            } else if (std.mem.startsWith(u8, trimmed_line, "##")) {
                zgui.pushFont(zgui.getIO().font_default); // Placeholder for H2 font
                zgui.text(trimmed_line[3..]);
                zgui.popFont();
            } else if (std.mem.startsWith(u8, trimmed_line, "#")) {
                zgui.pushFont(zgui.getIO().font_default); // Placeholder for H1 font
                zgui.text(trimmed_line[2..]);
                zgui.popFont();
            } else if (std.mem.startsWith(u8, trimmed_line, "* ")) {
                zgui.bullet();
                zgui.text(trimmed_line[2..]);
            } else {
                zgui.text(trimmed_line);
            }
        }
    }
};
