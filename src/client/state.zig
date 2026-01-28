const std = @import("std");
const types = @import("../protocol/types.zig");

pub const ClientState = enum {
    disconnected,
    connecting,
    authenticating,
    connected,
    error_state,
};

pub const ClientContext = struct {
    allocator: std.mem.Allocator,
    state: ClientState,
    current_session: ?[]const u8,
    messages: std.ArrayList(types.ChatMessage),
    users: std.ArrayList(types.User),

    pub fn init(allocator: std.mem.Allocator) !ClientContext {
        return .{
            .allocator = allocator,
            .state = .disconnected,
            .current_session = null,
            .messages = std.ArrayList(types.ChatMessage).empty,
            .users = std.ArrayList(types.User).empty,
        };
    }

    pub fn deinit(self: *ClientContext) void {
        self.messages.deinit(self.allocator);
        self.users.deinit(self.allocator);
    }
};
