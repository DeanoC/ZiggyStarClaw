const state = @import("../client/state.zig");
const chat_view = @import("chat_view.zig");
const input_panel = @import("input_panel.zig");
const settings_view = @import("settings_view.zig");
const status_bar = @import("status_bar.zig");

pub fn draw(ctx: *state.ClientContext) void {
    // TODO: Implement layout with ImGui docking and panels.
    chat_view.draw(ctx.messages.items);
    _ = input_panel.draw();
    settings_view.draw();
    status_bar.draw(ctx.state, ctx.current_session, ctx.messages.items.len);
}
