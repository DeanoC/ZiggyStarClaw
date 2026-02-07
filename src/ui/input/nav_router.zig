const nav = @import("nav.zig");

// Per-window navigation state is stored by the caller (WindowUiState).
// During drawing we set a global pointer so widgets can register focusable rects
// without threading a nav pointer through every call site.

var active_nav: ?*nav.NavState = null;

pub fn set(nav_state: ?*nav.NavState) void {
    active_nav = nav_state;
}

pub fn get() ?*nav.NavState {
    return active_nav;
}
