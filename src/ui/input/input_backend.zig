const std = @import("std");
const builtin = @import("builtin");
const input_state = @import("input_state.zig");
const imgui_input_bridge = if (builtin.abi.isAndroid())
    @import("imgui_input_bridge.zig")
else
    struct {
        pub fn collect(_: std.mem.Allocator, _: *input_state.InputQueue) void {}
    };
const sdl_input_backend = @import("sdl_input_backend.zig");
// The legacy GLFW backend is only used by the old WASM+ImGui path.
const glfw_input_backend = if (builtin.abi.isAndroid() and builtin.os.tag == .emscripten)
    @import("glfw_input_backend.zig")
else
    struct {
        pub fn collect(_: std.mem.Allocator, _: *input_state.InputQueue) void {}
    };

pub const Backend = struct {
    collectFn: *const fn (std.mem.Allocator, *input_state.InputQueue) void,

    pub fn collect(self: Backend, allocator: std.mem.Allocator, queue: *input_state.InputQueue) void {
        self.collectFn(allocator, queue);
    }
};

pub const imgui = Backend{
    .collectFn = if (builtin.abi.isAndroid()) imgui_input_bridge.collect else collectNoop,
};

pub const noop = Backend{
    .collectFn = collectNoop,
};

pub const sdl3 = Backend{
    .collectFn = sdl_input_backend.collect,
};

pub const glfw = Backend{
    .collectFn = if (builtin.abi.isAndroid() and builtin.os.tag == .emscripten) glfw_input_backend.collect else collectNoop,
};

fn collectNoop(_: std.mem.Allocator, _: *input_state.InputQueue) void {}
