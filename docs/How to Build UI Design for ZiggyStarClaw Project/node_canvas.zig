const std = @import("std");
const zgui = @import("zgui");
const NodeGraph = @import("node_graph.zig").NodeGraph;

pub const NodeCanvas = struct {
    graph: *NodeGraph,
    view: CanvasView,
    interaction: InteractionState,

    pub const CanvasView = struct {
        offset: [2]f32 = .{ 0.0, 0.0 },
        zoom: f32 = 1.0,
    };

    pub const InteractionState = union(enum) {
        idle,
        panning: [2]f32,
        dragging_node: struct { id: []const u8, offset: [2]f32 },
        linking: struct { start_pin_id: []const u8 },
    };

    pub fn init(graph: *NodeGraph) NodeCanvas {
        return .{
            .graph = graph,
            .view = .{},
            .interaction = .idle,
        };
    }

    pub fn draw(self: *NodeCanvas, allocator: std.mem.Allocator) void {
        _ = allocator;
        zgui.beginChild("node_canvas", .{}, .{
            .border = true,
            .flags = .{ .no_move = true },
        });

        const p = zgui.getCursorScreenPos();
        const avail = zgui.getContentRegionAvail();
        const canvas_bb = .{ p[0], p[1], p[0] + avail[0], p[1] + avail[1] };

        const dl = zgui.getWindowDrawList();
        dl.addRectFilled(canvas_bb[0..2], canvas_bb[2..4], zgui.colorConvertFloat4ToU32(.{ 0.1, 0.1, 0.1, 1.0 }));

        self.drawGrid(canvas_bb);

        // Interaction logic would go here
        // e.g., handle mouse input for panning, zooming, dragging

        // Node rendering logic would go here
        var node_it = self.graph.nodes.iterator();
        while (node_it.next()) |entry| {
            const node = entry.value_ptr;
            const node_pos_screen = self.canvasToScreen(node.position);
            const node_size = .{ 150.0, 80.0 };
            const node_bb = .{ node_pos_screen[0], node_pos_screen[1], node_pos_screen[0] + node_size[0], node_pos_screen[1] + node_size[1] };

            dl.addRectFilled(node_bb[0..2], node_bb[2..4], zgui.colorConvertFloat4ToU32(.{ 0.2, 0.2, 0.25, 1.0 }), 4.0);
            dl.addText(node_pos_screen, zgui.colorConvertFloat4ToU32(.{ 1, 1, 1, 1 }), node.title);
        }

        zgui.endChild();
    }

    fn drawGrid(self: *NodeCanvas, bb: [4]f32) void {
        const dl = zgui.getWindowDrawList();
        const grid_size = 64.0 * self.view.zoom;
        const num_x = @ceil((bb[2] - bb[0]) / grid_size);
        const num_y = @ceil((bb[3] - bb[1]) / grid_size);

        const start_x = @floor(self.view.offset[0] / grid_size) * grid_size - self.view.offset[0];
        const start_y = @floor(self.view.offset[1] / grid_size) * grid_size - self.view.offset[1];

        var i: f32 = 0.0;
        while (i < num_x) : (i += 1.0) {
            const x = bb[0] + start_x + i * grid_size;
            dl.addLine(.{ x, bb[1] }, .{ x, bb[3] }, zgui.colorConvertFloat4ToU32(.{ 0.15, 0.15, 0.15, 1.0 }), 1.0);
        }

        i = 0.0;
        while (i < num_y) : (i += 1.0) {
            const y = bb[1] + start_y + i * grid_size;
            dl.addLine(.{ bb[0], y }, .{ bb[2], y }, zgui.colorConvertFloat4ToU32(.{ 0.15, 0.15, 0.15, 1.0 }), 1.0);
        }
    }

    pub fn canvasToScreen(self: *NodeCanvas, pos: [2]f32) [2]f32 {
        const p = zgui.getCursorScreenPos();
        return .{ p[0] + pos[0] * self.view.zoom + self.view.offset[0], p[1] + pos[1] * self.view.zoom + self.view.offset[1] };
    }

    pub fn screenToCanvas(self: *NodeCanvas, pos: [2]f32) [2]f32 {
        const p = zgui.getCursorScreenPos();
        return .{ (pos[0] - p[0] - self.view.offset[0]) / self.view.zoom, (pos[1] - p[1] - self.view.offset[1]) / self.view.zoom };
    }
};
