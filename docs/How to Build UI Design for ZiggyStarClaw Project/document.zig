const std = @import("std");
const GapBuffer = @import("gap_buffer.zig").GapBuffer;

pub const Document = struct {
    buffer: GapBuffer,
    language: Language,
    file_path: ?[]const u8,
    allocator: std.mem.Allocator,

    pub const Language = enum {
        zig,
        markdown,
        plaintext,
    };

    pub fn init(allocator: std.mem.Allocator, language: Language, text: []const u8) !Document {
        return Document{
            .buffer = try GapBuffer.init(allocator, text),
            .language = language,
            .file_path = null,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Document) void {
        self.buffer.deinit();
        if (self.file_path) |path| {
            self.allocator.free(path);
        }
    }
};
