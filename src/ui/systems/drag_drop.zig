const std = @import("std");
const zgui = @import("zgui");

pub const Rect = struct {
    min: [2]f32,
    max: [2]f32,

    pub fn contains(self: Rect, point: [2]f32) bool {
        return point[0] >= self.min[0] and point[0] <= self.max[0] and point[1] >= self.min[1] and point[1] <= self.max[1];
    }
};

pub const DragPayload = struct {
    source_id: []const u8,
    data_type: []const u8,
    data: ?*anyopaque = null,
    preview_fn: ?*const fn ([2]f32) void = null,
};

pub const DropTarget = struct {
    id: []const u8,
    bounds: Rect,
    accepts: []const []const u8,
    on_drop: ?*const fn (DragPayload) void = null,
};

pub const DragDropManager = struct {
    active_drag: ?DragPayload = null,
    drop_targets: std.ArrayList(DropTarget),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) DragDropManager {
        return .{
            .active_drag = null,
            .drop_targets = .empty,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *DragDropManager) void {
        self.drop_targets.deinit(self.allocator);
    }

    pub fn beginFrame(self: *DragDropManager) void {
        self.drop_targets.clearRetainingCapacity();
    }

    pub fn beginDrag(self: *DragDropManager, payload: DragPayload) void {
        self.active_drag = payload;
    }

    pub fn cancelDrag(self: *DragDropManager) void {
        self.active_drag = null;
    }

    pub fn registerDropTarget(self: *DragDropManager, target: DropTarget) !void {
        try self.drop_targets.append(self.allocator, target);
    }

    pub fn endDrag(self: *DragDropManager) ?DropTarget {
        const payload = self.active_drag orelse return null;
        const mouse = zgui.getMousePos();
        for (self.drop_targets.items) |target| {
            if (!target.bounds.contains(mouse)) continue;
            if (!acceptsType(target.accepts, payload.data_type)) continue;
            if (target.on_drop) |handler| {
                handler(payload);
            }
            self.active_drag = null;
            return target;
        }
        self.active_drag = null;
        return null;
    }

    pub fn drawPreview(self: *DragDropManager) void {
        if (self.active_drag) |payload| {
            if (payload.preview_fn) |preview| {
                preview(zgui.getMousePos());
            }
        }
    }
};

fn acceptsType(accepts: []const []const u8, data_type: []const u8) bool {
    for (accepts) |candidate| {
        if (std.mem.eql(u8, candidate, data_type)) return true;
    }
    return false;
}
