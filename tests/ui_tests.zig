const std = @import("std");
const moltbot = @import("moltbot");

const chat_view = moltbot.ui.chat_view;
const types = moltbot.protocol.types;

test "ui chat view stub" {
    const msg = types.ChatMessage{
        .id = "m1",
        .role = "assistant",
        .content = "ok",
        .timestamp = 2,
        .attachments = null,
    };
    const messages = [_]types.ChatMessage{msg};
    chat_view.draw(messages[0..]);
    try std.testing.expect(true);
}
