const std = @import("std");
const types = @import("../src/protocol/types.zig");

pub fn main() void {
    const msg = types.ChatMessage{
        .id = "example",
        .role = "user",
        .content = "hello from example",
        .timestamp = 0,
        .attachments = null,
    };
    std.log.info("Example message: {s}", .{msg.content});
}
