const std = @import("std");

pub const ChatHistory = struct {
    threads: std.ArrayList(Thread),
    active_thread_idx: ?usize,

    pub const Thread = struct {
        id: []const u8,
        messages: std.ArrayList(Message),
    };

    pub const Message = struct {
        id: []const u8,
        role: Role,
        content: Content,
        timestamp: i64,

        pub const Role = enum { user, assistant, system, tool };
        pub const Content = union(enum) {
            text: []const u8,
            code: struct { language: []const u8, code: []const u8 },
        };
    };

    pub fn init(allocator: std.mem.Allocator) ChatHistory {
        return .{
            .threads = std.ArrayList(Thread).init(allocator),
            .active_thread_idx = null,
        };
    }

    pub fn deinit(self: *ChatHistory) void {
        for (self.threads.items) |*thread| {
            self.threads.allocator.free(thread.id);
            for (thread.messages.items) |*message| {
                self.threads.allocator.free(message.id);
                switch (message.content) {
                    .text => |text| self.threads.allocator.free(text),
                    .code => |code_block| {
                        self.threads.allocator.free(code_block.language);
                        self.threads.allocator.free(code_block.code);
                    },
                }
            }
            thread.messages.deinit();
        }
        self.threads.deinit();
    }
};
