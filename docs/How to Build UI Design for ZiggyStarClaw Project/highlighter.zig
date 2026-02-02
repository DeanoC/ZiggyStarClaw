const std = @import("std");

pub const TokenKind = enum {
    keyword,
    identifier,
    string,
    number,
    comment,
    operator,
    punctuation,
    type_name,
    function_name,
    builtin,
    error,
    whitespace,
    default,
};

pub const Token = struct {
    start: usize,
    len: usize,
    kind: TokenKind,
};

pub const Highlighter = struct {
    allocator: std.mem.Allocator,
    line_cache: std.AutoHashMap(usize, std.ArrayList(Token)),

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .line_cache = std.AutoHashMap(usize, std.ArrayList(Token)).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        var it = self.line_cache.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.line_cache.deinit();
    }

    pub fn getTokensForLine(self: *Self, line_idx: usize, line_text: []const u8) !*const std.ArrayList(Token) {
        if (self.line_cache.get(line_idx)) |tokens| {
            return tokens;
        }

        var new_tokens = std.ArrayList(Token).init(self.allocator);
        errdefer new_tokens.deinit();

        // Simple Zig tokenizer example
        var cursor: usize = 0;
        while (cursor < line_text.len) {
            const start = cursor;
            if (std.ascii.isWhitespace(line_text[cursor])) {
                while (cursor < line_text.len and std.ascii.isWhitespace(line_text[cursor])) : (cursor += 1) {}
                try new_tokens.append(.{ .start = start, .len = cursor - start, .kind = .whitespace });
            } else if (std.ascii.isAlphabetic(line_text[cursor])) {
                while (cursor < line_text.len and std.ascii.isAlphanumeric(line_text[cursor])) : (cursor += 1) {}
                const word = line_text[start..cursor];
                const kind = if (isZigKeyword(word)) .keyword else .identifier;
                try new_tokens.append(.{ .start = start, .len = cursor - start, .kind = kind });
            } else if (line_text[cursor] == '"') {
                cursor += 1;
                while (cursor < line_text.len and line_text[cursor] != '"') : (cursor += 1) {}
                if (cursor < line_text.len) cursor += 1;
                try new_tokens.append(.{ .start = start, .len = cursor - start, .kind = .string });
            } else {
                cursor += 1;
                try new_tokens.append(.{ .start = start, .len = 1, .kind = .default });
            }
        }

        try self.line_cache.put(line_idx, new_tokens);
        return self.line_cache.get(line_idx).?;
    }

    pub fn invalidate(self: *Self, line_idx: usize) void {
        if (self.line_cache.fetchRemove(line_idx)) |entry| {
            entry.value.deinit();
        }
    }
};

fn isZigKeyword(word: []const u8) bool {
    return std.mem.eql(u8, word, "const") or
           std.mem.eql(u8, word, "var") or
           std.mem.eql(u8, word, "fn") or
           std.mem.eql(u8, word, "pub") or
           std.mem.eql(u8, word, "struct") or
           std.mem.eql(u8, word, "enum") or
           std.mem.eql(u8, word, "if") or
           std.mem.eql(u8, word, "else") or
           std.mem.eql(u8, word, "while") or
           std.mem.eql(u8, word, "for") or
           std.mem.eql(u8, word, "return");
}
