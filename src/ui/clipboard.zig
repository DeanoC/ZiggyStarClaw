const std = @import("std");
const sdl = @import("../platform/sdl3.zig").c;

var cached: ?[:0]u8 = null;

pub fn setTextZ(text: [:0]const u8) void {
    _ = sdl.SDL_SetClipboardText(text.ptr);
}

pub fn getTextZ() [:0]const u8 {
    if (cached) |buf| {
        std.heap.page_allocator.free(buf);
        cached = null;
    }
    const raw = sdl.SDL_GetClipboardText();
    if (raw == null) return "";
    const slice = std.mem.span(raw);
    cached = std.heap.page_allocator.dupeZ(u8, slice) catch null;
    sdl.SDL_free(raw);
    return cached orelse "";
}
