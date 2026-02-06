const std = @import("std");
const ui_build = @import("../ui_build.zig");
const use_imgui = ui_build.use_imgui;
const input_state = @import("input_state.zig");
const imgui_input_bridge = if (use_imgui)
    @import("imgui_input_bridge.zig")
else
    struct {
        pub fn collect(_: std.mem.Allocator, _: *input_state.InputQueue) void {}
    };
const sdl_input_backend = @import("sdl_input_backend.zig");

pub const Backend = struct {
    collectFn: *const fn (std.mem.Allocator, *input_state.InputQueue) void,

    pub fn collect(self: Backend, allocator: std.mem.Allocator, queue: *input_state.InputQueue) void {
        self.collectFn(allocator, queue);
    }
};

pub const imgui = Backend{
    .collectFn = if (use_imgui) imgui_input_bridge.collect else collectNoop,
};

pub const noop = Backend{
    .collectFn = collectNoop,
};

pub const sdl3 = Backend{
    .collectFn = sdl_input_backend.collect,
};

pub const glfw = Backend{
    // Legacy WASM path used GLFW; keep as noop for now.
    .collectFn = collectNoop,
};

fn collectNoop(_: std.mem.Allocator, _: *input_state.InputQueue) void {}
