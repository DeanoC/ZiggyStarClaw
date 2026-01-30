const std = @import("std");
const builtin = @import("builtin");
const logger = @import("../utils/logger.zig");

pub const UpdateStatus = enum {
    idle,
    checking,
    up_to_date,
    update_available,
    failed,
    unsupported,
};

pub const UpdateState = struct {
    mutex: std.Thread.Mutex = .{},
    status: UpdateStatus = .idle,
    latest_version: ?[]const u8 = null,
    release_url: ?[]const u8 = null,
    error_message: ?[]const u8 = null,
    last_checked_ms: ?i64 = null,
    in_flight: bool = false,
    worker: ?std.Thread = null,

    pub fn deinit(self: *UpdateState, allocator: std.mem.Allocator) void {
        if (self.worker) |thread| {
            thread.join();
            self.worker = null;
        }
        self.clearLocked(allocator);
    }

    pub fn snapshot(self: *UpdateState) Snapshot {
        self.mutex.lock();
        defer self.mutex.unlock();
        return .{
            .status = self.status,
            .latest_version = self.latest_version,
            .release_url = self.release_url,
            .error_message = self.error_message,
            .last_checked_ms = self.last_checked_ms,
            .in_flight = self.in_flight,
        };
    }

    pub fn startCheck(
        self: *UpdateState,
        allocator: std.mem.Allocator,
        manifest_url: []const u8,
        current_version: []const u8,
    ) void {
        if (manifest_url.len == 0) {
            self.setError(allocator, "Update manifest URL is empty.");
            return;
        }
        if (builtin.target.os.tag == .emscripten) {
            self.setUnsupported(allocator);
            return;
        }

        self.mutex.lock();
        defer self.mutex.unlock();
        if (self.in_flight) return;

        self.clearLocked(allocator);
        self.status = .checking;
        self.in_flight = true;

        const url_copy = allocator.dupe(u8, manifest_url) catch {
            self.status = .failed;
            self.in_flight = false;
            return;
        };
        const version_copy = allocator.dupe(u8, current_version) catch {
            allocator.free(url_copy);
            self.status = .failed;
            self.in_flight = false;
            return;
        };

        const thread = std.Thread.spawn(.{}, checkThread, .{ self, allocator, url_copy, version_copy }) catch {
            allocator.free(url_copy);
            allocator.free(version_copy);
            self.status = .failed;
            self.in_flight = false;
            return;
        };
        self.worker = thread;
    }

    fn clearLocked(self: *UpdateState, allocator: std.mem.Allocator) void {
        if (self.latest_version) |value| {
            allocator.free(value);
        }
        if (self.release_url) |value| {
            allocator.free(value);
        }
        if (self.error_message) |value| {
            allocator.free(value);
        }
        self.latest_version = null;
        self.release_url = null;
        self.error_message = null;
    }

    fn setError(self: *UpdateState, allocator: std.mem.Allocator, message: []const u8) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.clearLocked(allocator);
        self.error_message = allocator.dupe(u8, message) catch null;
        self.status = .failed;
        self.last_checked_ms = std.time.milliTimestamp();
        self.in_flight = false;
    }

    fn setUnsupported(self: *UpdateState, allocator: std.mem.Allocator) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.clearLocked(allocator);
        self.status = .unsupported;
        self.error_message = allocator.dupe(u8, "Update checks are not supported in the web build.") catch null;
        self.last_checked_ms = std.time.milliTimestamp();
        self.in_flight = false;
    }
};

pub const Snapshot = struct {
    status: UpdateStatus,
    latest_version: ?[]const u8,
    release_url: ?[]const u8,
    error_message: ?[]const u8,
    last_checked_ms: ?i64,
    in_flight: bool,
};

fn checkThread(
    state: *UpdateState,
    allocator: std.mem.Allocator,
    manifest_url: []const u8,
    current_version: []const u8,
) void {
    defer allocator.free(manifest_url);
    defer allocator.free(current_version);

    const latest_version = checkForUpdates(allocator, manifest_url, current_version) catch |err| {
        logger.warn("Update check failed: {}", .{err});
        state.setError(allocator, @errorName(err));
        return;
    };

    state.mutex.lock();
    defer state.mutex.unlock();
    state.clearLocked(allocator);
    state.latest_version = latest_version.version;
    state.release_url = latest_version.release_url;
    state.last_checked_ms = std.time.milliTimestamp();
    state.in_flight = false;
    if (isNewerVersion(latest_version.version, current_version)) {
        state.status = .update_available;
    } else {
        state.status = .up_to_date;
    }
}

const UpdateInfo = struct {
    version: []const u8,
    release_url: ?[]const u8,
};

fn checkForUpdates(
    allocator: std.mem.Allocator,
    manifest_url: []const u8,
    current_version: []const u8,
) !UpdateInfo {
    _ = current_version;
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var body = std.Io.Writer.Allocating.init(allocator);
    defer body.deinit();

    const result = try client.fetch(.{
        .location = .{ .url = manifest_url },
        .method = .GET,
        .response_writer = &body.writer,
    });

    if (result.status != .ok) {
        return error.UpdateManifestFetchFailed;
    }

    const body_slice = body.written();

    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, body_slice, .{});
    defer parsed.deinit();

    if (parsed.value != .object) return error.UpdateManifestInvalid;
    const version_value = parsed.value.object.get("version") orelse return error.UpdateManifestMissingVersion;
    if (version_value != .string) return error.UpdateManifestInvalid;
    const version = version_value.string;
    if (version.len == 0) return error.UpdateManifestMissingVersion;

    var release_url: ?[]const u8 = null;
    if (parsed.value.object.get("release_url")) |rel| {
        if (rel == .string and rel.string.len > 0) {
            release_url = try allocator.dupe(u8, rel.string);
        }
    }

    return .{
        .version = try allocator.dupe(u8, version),
        .release_url = release_url,
    };
}

fn isNewerVersion(latest: []const u8, current: []const u8) bool {
    const latest_parts = parseVersion(latest);
    const current_parts = parseVersion(current);
    if (latest_parts[0] != current_parts[0]) return latest_parts[0] > current_parts[0];
    if (latest_parts[1] != current_parts[1]) return latest_parts[1] > current_parts[1];
    return latest_parts[2] > current_parts[2];
}

fn parseVersion(raw: []const u8) [3]u32 {
    var text = std.mem.trim(u8, raw, " \t\r\n");
    if (text.len > 0 and (text[0] == 'v' or text[0] == 'V')) {
        text = text[1..];
    }
    var parts: [3]u32 = .{ 0, 0, 0 };
    var it = std.mem.splitScalar(u8, text, '.');
    var idx: usize = 0;
    while (it.next()) |part| : (idx += 1) {
        if (idx >= parts.len) break;
        parts[idx] = std.fmt.parseInt(u32, part, 10) catch 0;
    }
    return parts;
}
