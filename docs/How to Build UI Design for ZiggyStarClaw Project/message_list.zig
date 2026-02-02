const std = @import("std");
const zgui = @import("zgui");
const ChatHistory = @import("chat_history.zig").ChatHistory;

pub const MessageList = struct {
    history: *ChatHistory,
    scroll_to_bottom: bool,

    pub fn init(history: *ChatHistory) MessageList {
        return .{
            .history = history,
            .scroll_to_bottom = true,
        };
    }

    pub fn draw(self: *MessageList, allocator: std.mem.Allocator) void {
        _ = allocator;
        const style = zgui.getStyle();
        zgui.beginChild("message_list", .{}, .{
            .flags = .{ .horizontal_scrollbar = true },
        });

        if (self.history.active_thread_idx) |active_idx| {
            const thread = &self.history.threads.items[active_idx];
            var last_role: ?ChatHistory.Message.Role = null;

            for (thread.messages.items) |message| {
                if (last_role == null or last_role.? != message.role) {
                    zgui.text(switch (message.role) {
                        .user => "User",
                        .assistant => "Assistant",
                        .system => "System",
                        .tool => "Tool",
                    });
                    zgui.separator();
                }
                last_role = message.role;

                switch (message.content) {
                    .text => |text| {
                        zgui.pushTextWrapPos(zgui.getContentRegionAvail()[0]);
                        zgui.text(text);
                        zgui.popTextWrapPos();
                    },
                    .code => |code_block| {
                        zgui.text(code_block.language);
                        zgui.inputTextMultiline("##code", .{
                            .buf = @constCast(code_block.code),
                            .flags = .{ .read_only = true },
                            .h = zgui.getTextLineHeight() * 10,
                        });
                    },
                }
                zgui.spacing();
            }
        }

        if (self.scroll_to_bottom) {
            zgui.setScrollHereY(1.0);
            self.scroll_to_bottom = false;
        }

        zgui.endChild();
    }
};
