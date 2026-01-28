const std = @import("std");
const moltbot = @import("moltbot");

const messages = moltbot.protocol.messages;
const types = moltbot.protocol.types;

test "serialize/deserialize chat message" {
    const allocator = std.testing.allocator;
    const msg = types.ChatMessage{
        .id = "m1",
        .role = "user",
        .content = "hello",
        .timestamp = 1,
        .attachments = null,
    };

    const json = try messages.serializeMessage(allocator, msg);
    defer allocator.free(json);

    var parsed = try messages.deserializeMessage(allocator, json, types.ChatMessage);
    defer parsed.deinit();

    try std.testing.expectEqualStrings(msg.id, parsed.value.id);
    try std.testing.expectEqualStrings(msg.role, parsed.value.role);
    try std.testing.expectEqualStrings(msg.content, parsed.value.content);
    try std.testing.expectEqual(msg.timestamp, parsed.value.timestamp);
}
