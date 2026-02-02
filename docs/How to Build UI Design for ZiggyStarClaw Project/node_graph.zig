const std = @import("std");

pub const NodeGraph = struct {
    nodes: std.StringHashMap(Node),
    links: std.ArrayList(Link),

    pub const Node = struct {
        id: []const u8,
        title: []const u8,
        position: [2]f32,
        inputs: []Pin,
        outputs: []Pin,
    };

    pub const Pin = struct {
        id: []const u8,
        name: []const u8,
        data_type: DataType,
    };

    pub const Link = struct {
        id: u64,
        start_pin: []const u8,
        end_pin: []const u8,
    };

    pub const DataType = enum { float, vector, color, texture };

    pub fn init(allocator: std.mem.Allocator) NodeGraph {
        return .{
            .nodes = std.StringHashMap(Node).init(allocator),
            .links = std.ArrayList(Link).init(allocator),
        };
    }

    pub fn deinit(self: *NodeGraph) void {
        // Deallocate nodes and their contents
        var it = self.nodes.iterator();
        while (it.next()) |entry| {
            self.nodes.allocator.free(entry.key_ptr.*);
            self.nodes.allocator.free(entry.value_ptr.id);
            self.nodes.allocator.free(entry.value_ptr.title);
            self.nodes.allocator.free(entry.value_ptr.inputs);
            self.nodes.allocator.free(entry.value_ptr.outputs);
        }
        self.nodes.deinit();
        self.links.deinit();
    }
};
