const std = @import("std");
const zgui = @import("zgui");

pub fn init(allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = zgui;
    // TODO: initialize zgui and configure ImGui settings.
}

pub fn beginFrame() void {
    // TODO: zgui.newFrame()
}

pub fn endFrame() void {
    // TODO: zgui.render()
}

pub fn deinit() void {
    // TODO: zgui.deinit()
}
