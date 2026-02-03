const std = @import("std");

pub fn UndoRedoStack(comptime T: type) type {
    return struct {
        const Self = @This();

        undo_stack: std.ArrayList(Command),
        redo_stack: std.ArrayList(Command),
        max_history: usize,
        allocator: std.mem.Allocator,

        pub const Command = struct {
            name: []const u8,
            state_before: T,
            state_after: T,
        };

        pub fn init(allocator: std.mem.Allocator, max_history: usize) Self {
            return .{
                .undo_stack = .empty,
                .redo_stack = .empty,
                .max_history = max_history,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.undo_stack.deinit(self.allocator);
            self.redo_stack.deinit(self.allocator);
        }

        pub fn execute(self: *Self, command: Command) !void {
            self.redo_stack.clearRetainingCapacity();
            try self.undo_stack.append(self.allocator, command);
            while (self.undo_stack.items.len > self.max_history) {
                _ = self.undo_stack.orderedRemove(0);
            }
        }

        pub fn undo(self: *Self) ?T {
            if (self.undo_stack.items.len == 0) return null;
            const command = self.undo_stack.pop() orelse return null;
            self.redo_stack.append(self.allocator, command) catch return null;
            return command.state_before;
        }

        pub fn redo(self: *Self) ?T {
            if (self.redo_stack.items.len == 0) return null;
            const command = self.redo_stack.pop() orelse return null;
            self.undo_stack.append(self.allocator, command) catch return null;
            return command.state_after;
        }

        pub fn canUndo(self: *Self) bool {
            return self.undo_stack.items.len > 0;
        }

        pub fn canRedo(self: *Self) bool {
            return self.redo_stack.items.len > 0;
        }

        pub fn clear(self: *Self) void {
            self.undo_stack.clearRetainingCapacity();
            self.redo_stack.clearRetainingCapacity();
        }
    };
}
