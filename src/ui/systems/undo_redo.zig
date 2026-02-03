const std = @import("std");

pub fn UndoRedoStack(comptime T: type) type {
    return struct {
        const Self = @This();

        undo_stack: std.ArrayList(Command),
        redo_stack: std.ArrayList(Command),
        max_history: usize,

        pub const Command = struct {
            name: []const u8,
            state_before: T,
            state_after: T,
        };

        pub fn init(allocator: std.mem.Allocator, max_history: usize) Self {
            return .{
                .undo_stack = std.ArrayList(Command).init(allocator),
                .redo_stack = std.ArrayList(Command).init(allocator),
                .max_history = max_history,
            };
        }

        pub fn deinit(self: *Self) void {
            self.undo_stack.deinit();
            self.redo_stack.deinit();
        }

        pub fn execute(self: *Self, command: Command) !void {
            self.redo_stack.clearRetainingCapacity();
            try self.undo_stack.append(command);
            while (self.undo_stack.items.len > self.max_history) {
                _ = self.undo_stack.orderedRemove(0);
            }
        }

        pub fn undo(self: *Self) ?T {
            if (self.undo_stack.items.len == 0) return null;
            const command = self.undo_stack.pop();
            self.redo_stack.append(command) catch return null;
            return command.state_before;
        }

        pub fn redo(self: *Self) ?T {
            if (self.redo_stack.items.len == 0) return null;
            const command = self.redo_stack.pop();
            self.undo_stack.append(command) catch return null;
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
