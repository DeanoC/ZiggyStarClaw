const std = @import("std");
const zgui = @import("zgui");
const glfw = @import("zglfw");

pub fn init(
    allocator: std.mem.Allocator,
    window: *glfw.Window,
    device: *const anyopaque,
    swapchain_format: u32,
    depth_format: u32,
) void {
    zgui.init(allocator);
    zgui.styleColorsDark(zgui.getStyle());
    zgui.backend.init(
        @ptrCast(window),
        device,
        swapchain_format,
        depth_format,
    );
}

pub fn beginFrame(framebuffer_width: u32, framebuffer_height: u32) void {
    zgui.backend.newFrame(framebuffer_width, framebuffer_height);
}

pub fn render(pass: *const anyopaque) void {
    zgui.backend.draw(pass);
}

pub fn deinit() void {
    zgui.backend.deinit();
    zgui.deinit();
}

pub fn applyDpiScale(scale: f32) void {
    if (scale <= 0.0 or scale == 1.0) return;

    var cfg = zgui.FontConfig.init();
    cfg.size_pixels = 16.0 * scale;
    const font = zgui.io.addFontDefault(cfg);
    zgui.io.setDefaultFont(font);

    const style = zgui.getStyle();
    style.scaleAllSizes(scale);
}
