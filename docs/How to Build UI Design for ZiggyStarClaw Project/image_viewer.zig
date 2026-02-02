const std = @import("std");
const zgui = @import("zgui");
const MediaCollection = @import("media_collection.zig").MediaCollection;

pub const ImageViewer = struct {
    collection: *MediaCollection,
    view: ViewState,

    pub const ViewState = struct {
        zoom: f32 = 1.0,
        offset: [2]f32 = .{ 0.0, 0.0 },
        fit_mode: FitMode = .fit,

        pub const FitMode = enum { fit, fill, actual, custom };
    };

    pub fn init(collection: *MediaCollection) ImageViewer {
        return .{
            .collection = collection,
            .view = .{},
        };
    }

    pub fn draw(self: *ImageViewer, texture_id: ?zgui.TextureId) void {
        zgui.beginChild("image_viewer", .{}, .{
            .border = true,
        });

        const avail = zgui.getContentRegionAvail();

        if (texture_id) |tex| {
            // Calculate image size based on fit mode
            const img_size = switch (self.view.fit_mode) {
                .fit => self.calculateFitSize(avail, .{ 800, 600 }), // Placeholder for actual image size
                .fill => avail,
                .actual => .{ 800, 600 }, // Placeholder for actual image size
                .custom => .{ 800 * self.view.zoom, 600 * self.view.zoom },
            };

            // Center the image
            const cursor_pos = zgui.getCursorPos();
            const centered_pos: [2]f32 = .{
                cursor_pos[0] + (avail[0] - img_size[0]) / 2.0 + self.view.offset[0],
                cursor_pos[1] + (avail[1] - img_size[1]) / 2.0 + self.view.offset[1],
            };
            zgui.setCursorPos(centered_pos);

            zgui.image(tex, .{ .w = img_size[0], .h = img_size[1] });

            // Handle mouse input for panning
            if (zgui.isItemHovered(.{})) {
                const io = zgui.getIO();
                if (io.mouse_down[0]) {
                    self.view.offset[0] += io.mouse_delta[0];
                    self.view.offset[1] += io.mouse_delta[1];
                }
                // Handle mouse wheel for zooming
                if (io.mouse_wheel != 0) {
                    self.view.zoom = std.math.clamp(self.view.zoom + io.mouse_wheel * 0.1, 0.1, 10.0);
                    self.view.fit_mode = .custom;
                }
            }
        } else {
            zgui.text("No image loaded");
        }

        // Controls
        zgui.setCursorPos(.{ 10, avail[1] - 30 });
        if (zgui.button("Fit", .{})) {
            self.view.fit_mode = .fit;
            self.view.offset = .{ 0, 0 };
        }
        zgui.sameLine(.{});
        if (zgui.button("Fill", .{})) {
            self.view.fit_mode = .fill;
            self.view.offset = .{ 0, 0 };
        }
        zgui.sameLine(.{});
        if (zgui.button("1:1", .{})) {
            self.view.fit_mode = .actual;
            self.view.offset = .{ 0, 0 };
        }
        zgui.sameLine(.{});
        if (zgui.button("Reset", .{})) {
            self.view = .{};
        }

        zgui.endChild();
    }

    fn calculateFitSize(self: *ImageViewer, container: [2]f32, image: [2]f32) [2]f32 {
        _ = self;
        const scale_x = container[0] / image[0];
        const scale_y = container[1] / image[1];
        const scale = @min(scale_x, scale_y);
        return .{ image[0] * scale, image[1] * scale };
    }

    pub fn zoomIn(self: *ImageViewer) void {
        self.view.zoom = @min(self.view.zoom * 1.2, 10.0);
        self.view.fit_mode = .custom;
    }

    pub fn zoomOut(self: *ImageViewer) void {
        self.view.zoom = @max(self.view.zoom / 1.2, 0.1);
        self.view.fit_mode = .custom;
    }

    pub fn resetView(self: *ImageViewer) void {
        self.view = .{};
    }
};
