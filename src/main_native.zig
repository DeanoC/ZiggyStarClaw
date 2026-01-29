const std = @import("std");
const builtin = @import("builtin");
const glfw = @import("zglfw");
const ui = @import("ui/main_window.zig");
const imgui = @import("ui/imgui_wrapper.zig");
const client_state = @import("client/state.zig");
const config = @import("client/config.zig");
const event_handler = @import("client/event_handler.zig");
const websocket_client = @import("client/websocket_client.zig");

extern fn zgui_opengl_load() c_int;
extern fn zgui_glViewport(x: c_int, y: c_int, w: c_int, h: c_int) void;
extern fn zgui_glClearColor(r: f32, g: f32, b: f32, a: f32) void;
extern fn zgui_glClear(mask: c_uint) void;

fn glfwErrorCallback(code: glfw.ErrorCode, desc: ?[*:0]const u8) callconv(.c) void {
    if (desc) |d| {
        std.log.err("GLFW error {d}: {s}", .{ @as(i32, @intCast(code)), d });
    } else {
        std.log.err("GLFW error {d}: (no description)", .{ @as(i32, @intCast(code)) });
    }
}

const MessageQueue = struct {
    mutex: std.Thread.Mutex = .{},
    items: std.ArrayList([]u8) = .empty,

    pub fn push(self: *MessageQueue, allocator: std.mem.Allocator, message: []u8) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        try self.items.append(allocator, message);
    }

    pub fn drain(self: *MessageQueue) std.ArrayList([]u8) {
        self.mutex.lock();
        defer self.mutex.unlock();
        const out = self.items;
        self.items = .empty;
        return out;
    }

    pub fn deinit(self: *MessageQueue, allocator: std.mem.Allocator) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        for (self.items.items) |message| {
            allocator.free(message);
        }
        self.items.deinit(allocator);
        self.items = .empty;
    }
};

const ReadLoop = struct {
    allocator: std.mem.Allocator,
    ws_client: *websocket_client.WebSocketClient,
    queue: *MessageQueue,
    stop: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    running: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
};

fn readLoopMain(loop: *ReadLoop) void {
    loop.running.store(true, .monotonic);
    defer loop.running.store(false, .monotonic);
    loop.ws_client.setReadTimeout(0);
    while (!loop.stop.load(.monotonic)) {
        const payload = loop.ws_client.receive() catch |err| {
            if (err == error.NotConnected or err == error.Closed) {
                return;
            }
            if (err == error.ReadFailed) {
                std.log.warn("WebSocket receive failed (thread): {}", .{err});
                loop.ws_client.disconnect();
                return;
            }
            std.log.err("WebSocket receive failed (thread): {}", .{err});
            loop.ws_client.disconnect();
            return;
        } orelse continue;

        loop.queue.push(loop.allocator, payload) catch {
            loop.allocator.free(payload);
            return;
        };
    }
}

fn startReadThread(loop: *ReadLoop, thread: *?std.Thread) !void {
    if (thread.* != null) return;
    loop.stop.store(false, .monotonic);
    thread.* = try std.Thread.spawn(.{}, readLoopMain, .{loop});
}

fn stopReadThread(loop: *ReadLoop, thread: *?std.Thread) void {
    if (thread.*) |handle| {
        loop.stop.store(true, .monotonic);
        loop.ws_client.disconnect();
        handle.join();
        thread.* = null;
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var cfg = try config.loadOrDefault(allocator, "moltbot_config.json");
    defer cfg.deinit(allocator);

    var ws_client = websocket_client.WebSocketClient.init(allocator, cfg.server_url, cfg.token, cfg.insecure_tls);
    ws_client.setReadTimeout(15_000);
    defer ws_client.deinit();

    _ = glfw.setErrorCallback(glfwErrorCallback);
    try glfw.init();
    defer glfw.terminate();

    glfw.windowHint(.client_api, .opengl_api);
    glfw.windowHint(.context_version_major, 3);
    glfw.windowHint(.context_version_minor, 3);
    glfw.windowHint(.opengl_profile, .opengl_core_profile);
    if (builtin.os.tag == .macos) {
        glfw.windowHint(.opengl_forward_compat, true);
    }

    const window = try glfw.Window.create(1280, 720, "MoltBot Client", null, null);
    defer window.destroy();

    glfw.makeContextCurrent(window);
    glfw.swapInterval(1);
    if (glfw.getCurrentContext() == null) {
        std.log.err("OpenGL context creation failed. If running under WSL, ensure WSLg or an X server with OpenGL is available.", .{});
        return error.OpenGLContextUnavailable;
    }
    const missing = zgui_opengl_load();
    if (missing != 0) {
        std.log.err("Failed to load {d} OpenGL function pointers via GLFW.", .{missing});
        return error.OpenGLLoaderFailed;
    }

    imgui.init(allocator, window);
    const scale = window.getContentScale();
    const dpi_scale: f32 = @max(scale[0], scale[1]);
    if (dpi_scale > 0.0) {
        imgui.applyDpiScale(dpi_scale);
    }
    defer imgui.deinit();

    var ctx = try client_state.ClientContext.init(allocator);
    defer ctx.deinit();

    var message_queue = MessageQueue{};
    defer message_queue.deinit(allocator);
    var read_loop = ReadLoop{
        .allocator = allocator,
        .ws_client = &ws_client,
        .queue = &message_queue,
    };
    var read_thread: ?std.Thread = null;
    defer stopReadThread(&read_loop, &read_thread);
    var should_reconnect = false;
    var reconnect_backoff_ms: u32 = 500;
    var next_reconnect_at_ms: i64 = 0;

    std.log.info("MoltBot client stub (native) loaded. Server: {s}", .{cfg.server_url});

    while (!window.shouldClose()) {
        glfw.pollEvents();

        if (read_thread != null and !read_loop.running.load(.monotonic)) {
            stopReadThread(&read_loop, &read_thread);
        }
        if (!ws_client.is_connected and ctx.state == .connected) {
            ctx.state = .disconnected;
            if (should_reconnect and next_reconnect_at_ms == 0) {
                const now_ms = std.time.milliTimestamp();
                next_reconnect_at_ms = now_ms + reconnect_backoff_ms;
                std.log.info("Reconnect scheduled in {d}ms", .{reconnect_backoff_ms});
            }
        }

        const win = window.getSize();
        const win_width: u32 = if (win[0] > 0) @intCast(win[0]) else 1;
        const win_height: u32 = if (win[1] > 0) @intCast(win[1]) else 1;

        const fb = window.getFramebufferSize();
        const fb_width: u32 = if (fb[0] > 0) @intCast(fb[0]) else 1;
        const fb_height: u32 = if (fb[1] > 0) @intCast(fb[1]) else 1;

        zgui_glViewport(0, 0, @intCast(fb_width), @intCast(fb_height));
        zgui_glClearColor(0.08, 0.08, 0.1, 1.0);
        zgui_glClear(0x00004000);

        var drained = message_queue.drain();
        defer {
            for (drained.items) |payload| {
                allocator.free(payload);
            }
            drained.deinit(allocator);
        }
        for (drained.items) |payload| {
            const update = event_handler.handleRawMessage(&ctx, payload) catch |err| blk: {
                std.log.err("Failed to handle server message: {}", .{err});
                break :blk null;
            };
            if (update) |auth_update| {
                defer auth_update.deinit(allocator);
                ws_client.storeDeviceToken(
                    auth_update.device_token,
                    auth_update.role,
                    auth_update.scopes,
                    auth_update.issued_at_ms,
                ) catch |err| {
                    std.log.warn("Failed to store device token: {}", .{err});
                };
            }
        }

        imgui.beginFrame(win_width, win_height, fb_width, fb_height);
        const ui_action = ui.draw(allocator, &ctx, &cfg, ws_client.is_connected);

        if (ui_action.config_updated) {
            ws_client.url = cfg.server_url;
            ws_client.token = cfg.token;
            ws_client.insecure_tls = cfg.insecure_tls;
        }

        if (ui_action.save_config) {
            config.save(allocator, "moltbot_config.json", cfg) catch |err| {
                std.log.err("Failed to save config: {}", .{err});
            };
        }

        if (ui_action.connect) {
            ctx.state = .connecting;
            ws_client.url = cfg.server_url;
            ws_client.token = cfg.token;
            ws_client.insecure_tls = cfg.insecure_tls;
            should_reconnect = true;
            reconnect_backoff_ms = 500;
            next_reconnect_at_ms = 0;
            ws_client.connect() catch |err| {
                std.log.err("WebSocket connect failed: {}", .{err});
                ctx.state = .error_state;
            };
            if (ws_client.is_connected) {
                ctx.state = .connected;
                startReadThread(&read_loop, &read_thread) catch |err| {
                    std.log.err("Failed to start read thread: {}", .{err});
                };
            }
        }

        if (ui_action.disconnect) {
            stopReadThread(&read_loop, &read_thread);
            ws_client.disconnect();
            should_reconnect = false;
            next_reconnect_at_ms = 0;
            reconnect_backoff_ms = 500;
            ctx.state = .disconnected;
        }

        if (ui_action.send_message) |message| {
            defer allocator.free(message);
            if (ws_client.is_connected) {
                ws_client.send(message) catch |err| {
                    std.log.err("Failed to send message: {}", .{err});
                };
            } else {
                std.log.warn("Cannot send message while disconnected", .{});
            }
        }

        if (should_reconnect and !ws_client.is_connected and read_thread == null) {
            const now_ms = std.time.milliTimestamp();
            if (next_reconnect_at_ms == 0 or now_ms >= next_reconnect_at_ms) {
                ctx.state = .connecting;
                ws_client.url = cfg.server_url;
                ws_client.token = cfg.token;
                ws_client.insecure_tls = cfg.insecure_tls;
                ws_client.connect() catch |err| {
                    std.log.err("WebSocket reconnect failed: {}", .{err});
                    ctx.state = .error_state;
                };
                if (ws_client.is_connected) {
                    ctx.state = .connected;
                    reconnect_backoff_ms = 500;
                    next_reconnect_at_ms = 0;
                    startReadThread(&read_loop, &read_thread) catch |err| {
                        std.log.err("Failed to start read thread: {}", .{err});
                    };
                } else {
                    next_reconnect_at_ms = now_ms + reconnect_backoff_ms;
                    const grown = reconnect_backoff_ms + reconnect_backoff_ms / 2;
                    reconnect_backoff_ms = if (grown > 15_000) 15_000 else grown;
                    std.log.info("Reconnect scheduled in {d}ms", .{reconnect_backoff_ms});
                }
            }
        }

        imgui.endFrame();

        window.swapBuffers();
    }
}
