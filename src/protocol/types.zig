const std = @import("std");

pub const ChatAttachment = struct {
    kind: []const u8,
    url: []const u8,
    name: ?[]const u8 = null,
};

pub const ChatMessage = struct {
    id: []const u8,
    role: []const u8,
    content: []const u8,
    timestamp: i64,
    attachments: ?[]ChatAttachment = null,
};

pub const Session = struct {
    key: []const u8,
    display_name: ?[]const u8 = null,
    label: ?[]const u8 = null,
    kind: ?[]const u8 = null,
    updated_at: ?i64 = null,
};

pub const SessionListResult = struct {
    sessions: ?[]Session = null,
};

pub const User = struct {
    id: []const u8,
    name: []const u8,
};

pub const ErrorEvent = struct {
    message: []const u8,
    code: ?[]const u8 = null,
};

pub const MessageEnvelope = struct {
    kind: []const u8,
    payload: std.json.Value,
};
