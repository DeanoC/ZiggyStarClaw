const std = @import("std");
const ws = @import("websocket");

pub const WebSocketClient = struct {
    allocator: std.mem.Allocator,
    url: []const u8,
    token: []const u8,
    is_connected: bool = false,
    conn: ?*anyopaque = null,

    pub fn init(allocator: std.mem.Allocator, url: []const u8, token: []const u8) WebSocketClient {
        return .{
            .allocator = allocator,
            .url = url,
            .token = token,
        };
    }

    pub fn connect(self: *WebSocketClient) !void {
        _ = ws;
        // TODO: Establish WSS connection and authenticate with token.
        self.is_connected = true;
    }

    pub fn send(self: *WebSocketClient, message: []const u8) !void {
        if (!self.is_connected) return error.NotConnected;
        _ = message;
        // TODO: Send message via websocket.
    }

    pub fn receive(self: *WebSocketClient) !?[]const u8 {
        if (!self.is_connected) return error.NotConnected;
        // TODO: Receive message from websocket.
        return null;
    }

    pub fn disconnect(self: *WebSocketClient) void {
        self.is_connected = false;
    }

    pub fn deinit(self: *WebSocketClient) void {
        _ = self;
    }
};
