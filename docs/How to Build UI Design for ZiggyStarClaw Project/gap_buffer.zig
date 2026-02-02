const std = @import("std");

pub const GapBuffer = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    buffer: []u8,
    gap_start: usize,
    gap_end: usize,

    pub fn init(allocator: std.mem.Allocator, initial_text: []const u8) !Self {
        const initial_capacity = @max(initial_text.len * 2, 64);
        var self = Self{
            .allocator = allocator,
            .buffer = try allocator.alloc(u8, initial_capacity),
            .gap_start = 0,
            .gap_end = initial_capacity,
        };
        errdefer self.deinit();

        try self.insert(0, initial_text);
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.buffer);
    }

    pub fn len(self: *const Self) usize {
        return self.buffer.len - (self.gap_end - self.gap_start);
    }

    pub fn insert(self: *Self, pos: usize, text: []const u8) !void {
        try self.moveGapTo(pos);
        if (text.len > (self.gap_end - self.gap_start)) {
            try self.growGap(text.len);
        }

        @memcpy(self.buffer[self.gap_start..], text);
        self.gap_start += text.len;
    }

    pub fn delete(self: *Self, pos: usize, len: usize) !void {
        try self.moveGapTo(pos + len);
        self.gap_start -= len;
    }

    pub fn getText(self: *Self, start: usize, end: usize) ![]u8 {
        const result = try self.allocator.alloc(u8, end - start);
        errdefer self.allocator.free(result);

        var cursor = start;
        var write_idx: usize = 0;
        while (cursor < end) {
            if (cursor >= self.gap_start and cursor < self.gap_end) {
                cursor = self.gap_end;
                continue;
            }
            result[write_idx] = self.buffer[cursor];
            write_idx += 1;
            cursor += 1;
        }
        return result;
    }

    fn moveGapTo(self: *Self, pos: usize) !void {
        if (pos == self.gap_start) return;

        if (pos < self.gap_start) {
            const len = self.gap_start - pos;
            const new_gap_end = self.gap_end - len;
            @memmove(self.buffer[new_gap_end..], self.buffer[pos..self.gap_start]);
            self.gap_start = pos;
            self.gap_end = new_gap_end;
        } else {
            const len = pos - self.gap_start;
            const new_gap_start = self.gap_start + len;
            @memmove(self.buffer[self.gap_start..], self.buffer[self.gap_end..new_gap_start]);
            self.gap_start = new_gap_start;
            self.gap_end = self.gap_end + len;
        }
    }

    fn growGap(self: *Self, min_growth: usize) !void {
        const new_capacity = @max(self.buffer.len * 2, self.buffer.len + min_growth);
        const new_buffer = try self.allocator.alloc(u8, new_capacity);
        errdefer self.allocator.free(new_buffer);

        @memcpy(new_buffer[0..self.gap_start], self.buffer[0..self.gap_start]);

        const tail_len = self.buffer.len - self.gap_end;
        const new_gap_end = new_capacity - tail_len;
        @memcpy(new_buffer[new_gap_end..], self.buffer[self.gap_end..]);

        self.allocator.free(self.buffer);
        self.buffer = new_buffer;
        self.gap_end = new_gap_end;
    }
};
