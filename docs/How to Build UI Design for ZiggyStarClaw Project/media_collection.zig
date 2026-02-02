const std = @import("std");

pub const MediaCollection = struct {
    items: std.ArrayList(MediaItem),
    current_index: ?usize,

    pub const MediaItem = struct {
        id: []const u8,
        media_type: MediaType,
        source_url: []const u8,

        pub const MediaType = enum { image, video, document };
    };

    pub fn init(allocator: std.mem.Allocator) MediaCollection {
        return .{
            .items = std.ArrayList(MediaItem).init(allocator),
            .current_index = null,
        };
    }

    pub fn deinit(self: *MediaCollection) void {
        for (self.items.items) |*item| {
            self.items.allocator.free(item.id);
            self.items.allocator.free(item.source_url);
        }
        self.items.deinit();
    }
};
