const std = @import("std");
const zgui = @import("zgui");

var input_buf: [512:0]u8 = [_:0]u8{0} ** 512;

pub fn draw(allocator: std.mem.Allocator) ?[]u8 {
    var send = false;

    _ = zgui.inputTextMultiline("##message_input", .{
        .buf = input_buf[0.. :0],
        .h = 80.0,
        .flags = .{ .allow_tab_input = true },
    });

    if (zgui.button("Send", .{})) {
        send = true;
    }

    if (!send) return null;

    const text = std.mem.sliceTo(&input_buf, 0);
    if (text.len == 0) return null;

    const owned = allocator.dupe(u8, text) catch return null;
    input_buf[0] = 0;
    return owned;
}
