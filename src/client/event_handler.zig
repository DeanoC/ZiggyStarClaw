const std = @import("std");
const state = @import("state.zig");
const gateway = @import("../protocol/gateway.zig");
const messages = @import("../protocol/messages.zig");

pub const AuthUpdate = struct {
    device_token: []const u8,
    role: ?[]const u8 = null,
    scopes: ?[]const []const u8 = null,
    issued_at_ms: ?i64 = null,

    pub fn deinit(self: *const AuthUpdate, allocator: std.mem.Allocator) void {
        allocator.free(self.device_token);
        if (self.role) |role| {
            allocator.free(role);
        }
        if (self.scopes) |scopes| {
            for (scopes) |scope| {
                allocator.free(scope);
            }
            allocator.free(scopes);
        }
    }
};

pub fn handleRawMessage(ctx: *state.ClientContext, raw: []const u8) !?AuthUpdate {
    var parsed = std.json.parseFromSlice(std.json.Value, ctx.allocator, raw, .{}) catch |err| {
        std.log.warn("Unparsed server message ({s}): {s}", .{ @errorName(err), raw });
        return null;
    };
    defer parsed.deinit();

    const value = parsed.value;
    if (value != .object) {
        std.log.warn("Unexpected server message (non-object): {s}", .{raw});
        return null;
    }

    const obj = value.object;
    const type_value = obj.get("type") orelse {
        std.log.warn("Server message missing type: {s}", .{raw});
        return null;
    };
    if (type_value != .string) {
        std.log.warn("Server message has non-string type: {s}", .{raw});
        return null;
    }

    const frame_type = type_value.string;

    if (std.mem.eql(u8, frame_type, "event")) {
        var frame = messages.parsePayload(ctx.allocator, value, gateway.GatewayEventFrame) catch |err| {
            std.log.warn("Unparsed event frame ({s}): {s}", .{ @errorName(err), raw });
            return null;
        };
        defer frame.deinit();

        if (std.mem.eql(u8, frame.value.event, "connect.challenge")) {
            std.log.info("Gateway connect challenge received", .{});
            return null;
        }

        if (std.mem.eql(u8, frame.value.event, "device.pair.requested")) {
            std.log.warn("Gateway pairing required: {s}", .{raw});
            return null;
        }

        std.log.debug("Gateway event: {s}", .{frame.value.event});
        return null;
    }

    if (std.mem.eql(u8, frame_type, "res")) {
        var frame = messages.parsePayload(ctx.allocator, value, gateway.GatewayResponseFrame) catch |err| {
            std.log.warn("Unparsed response frame ({s}): {s}", .{ @errorName(err), raw });
            return null;
        };
        defer frame.deinit();

        if (!frame.value.ok) {
            if (frame.value.@"error") |err| {
                std.log.err("Gateway request failed ({s}): {s}", .{ err.code, err.message });
                if (err.details) |details| {
                    if (details == .object) {
                        if (details.object.get("requestId")) |request_id| {
                            if (request_id == .string) {
                                std.log.warn("Pairing request id: {s}", .{request_id.string});
                            }
                        }
                    }
                }
            } else {
                std.log.err("Gateway request failed: {s}", .{raw});
            }
            ctx.state = .error_state;
            return null;
        }

        if (frame.value.payload) |payload| {
            if (payload == .object) {
                const payload_type = payload.object.get("type");
                if (payload_type != null and payload_type.? == .string and
                    std.mem.eql(u8, payload_type.?.string, "hello-ok"))
                {
                    ctx.state = .connected;
                    std.log.info("Gateway connected", .{});
                    if (try extractAuthUpdate(ctx.allocator, payload)) |update| {
                        return update;
                    }
                }
            }
        }
        return null;
    }

    std.log.debug("Unhandled gateway frame: {s}", .{raw});
    return null;
}

pub fn handleConnectionState(ctx: *state.ClientContext, new_state: state.ClientState) void {
    ctx.state = new_state;
}

fn extractAuthUpdate(allocator: std.mem.Allocator, payload: std.json.Value) !?AuthUpdate {
    if (payload != .object) return null;
    const auth_val = payload.object.get("auth") orelse return null;
    if (auth_val != .object) return null;
    const auth_obj = auth_val.object;
    const token_val = auth_obj.get("deviceToken") orelse return null;
    if (token_val != .string) return null;

    const token = try allocator.dupe(u8, token_val.string);
    const role = if (auth_obj.get("role")) |role_val| blk: {
        if (role_val == .string) break :blk try allocator.dupe(u8, role_val.string);
        break :blk null;
    } else null;

    var scopes_list: ?[]const []const u8 = null;
    if (auth_obj.get("scopes")) |scopes_val| {
        if (scopes_val == .array) {
            const items = scopes_val.array.items;
            var list = std.ArrayList([]const u8).empty;
            errdefer {
                for (list.items) |item| {
                    allocator.free(item);
                }
                list.deinit(allocator);
            }
            for (items) |item| {
                if (item != .string) continue;
                try list.append(allocator, try allocator.dupe(u8, item.string));
            }
            scopes_list = try list.toOwnedSlice(allocator);
            list.deinit(allocator);
        }
    }

    return AuthUpdate{
        .device_token = token,
        .role = role,
        .scopes = scopes_list,
        .issued_at_ms = if (auth_obj.get("issuedAtMs")) |issued_val|
            if (issued_val == .integer) issued_val.integer else null
        else
            null,
    };
}
