const std = @import("std");
const zgui = @import("zgui");
const theme = @import("theme.zig");
const components = @import("components/components.zig");

const ArtifactTab = enum {
    preview,
    edit,
};

var active_tab: ArtifactTab = .preview;
var edit_initialized = false;
var edit_buf: [4096:0]u8 = [_:0]u8{0} ** 4096;

pub fn draw() void {
    const opened = zgui.beginChild("ArtifactWorkspaceView", .{ .h = 0.0, .child_flags = .{ .border = true } });
    if (opened) {
        const t = theme.activeTheme();
        if (components.layout.header_bar.begin(.{ .title = "Artifact Workspace", .subtitle = "Preview & Edit" })) {
            components.layout.header_bar.end();
        }

        if (components.core.tab_bar.begin("ArtifactTabs")) {
            if (components.core.tab_bar.beginItem("Preview")) {
                active_tab = .preview;
                components.core.tab_bar.endItem();
            }
            if (components.core.tab_bar.beginItem("Edit")) {
                active_tab = .edit;
                components.core.tab_bar.endItem();
            }
            components.core.tab_bar.end();
        }

        zgui.dummy(.{ .w = 0.0, .h = t.spacing.sm });

        if (components.layout.scroll_area.begin(.{ .id = "ArtifactWorkspaceContent", .border = false })) {
            switch (active_tab) {
                .preview => drawPreview(t),
                .edit => drawEditor(),
            }
        }
        components.layout.scroll_area.end();

        zgui.separator();
        if (components.core.button.draw("Copy", .{ .variant = .secondary, .size = .small })) {}
        zgui.sameLine(.{ .spacing = t.spacing.sm });
        if (components.core.button.draw("Undo", .{ .variant = .ghost, .size = .small })) {}
        zgui.sameLine(.{ .spacing = t.spacing.sm });
        if (components.core.button.draw("Redo", .{ .variant = .ghost, .size = .small })) {}
        zgui.sameLine(.{ .spacing = t.spacing.sm });
        if (components.core.button.draw("Expand", .{ .variant = .secondary, .size = .small })) {}
    }
    zgui.endChild();
}

fn drawPreview(t: *const theme.Theme) void {
    if (components.layout.card.begin(.{ .title = "Report Summary", .id = "artifact_summary" })) {
        theme.push(.heading);
        zgui.text("Quarterly Performance Overview", .{});
        theme.pop();
        zgui.textWrapped(
            "This report summarizes sales performance, highlights key insights, and links supporting artifacts collected during the run.",
            .{},
        );
    }
    components.layout.card.end();

    zgui.dummy(.{ .w = 0.0, .h = t.spacing.sm });

    if (components.layout.card.begin(.{ .title = "Key Insights", .id = "artifact_insights" })) {
        zgui.bulletText("North America revenue is trending up 12% month-over-month.", .{});
        zgui.bulletText("Top competitor share declined after feature launch.", .{});
        zgui.bulletText("Pipeline risk concentrated in two enterprise accounts.", .{});
    }
    components.layout.card.end();

    zgui.dummy(.{ .w = 0.0, .h = t.spacing.sm });

    if (components.layout.card.begin(.{ .title = "Sales Performance (Chart)", .id = "artifact_chart" })) {
        zgui.textWrapped("Chart placeholder: bar chart of weekly sales performance.", .{});
        zgui.dummy(.{ .w = 0.0, .h = 120.0 });
    }
    components.layout.card.end();
}

fn drawEditor() void {
    if (!edit_initialized) {
        const seed =
            "## Report Summary\n\n" ++
            "Write a concise summary of the report findings.\n\n" ++
            "## Key Insights\n\n" ++
            "- Insight 1\n" ++
            "- Insight 2\n\n" ++
            "## Action Items\n\n" ++
            "- Follow up with sales leadership\n";
        fillBuffer(edit_buf[0..], seed);
        edit_initialized = true;
    }

    _ = zgui.inputTextMultiline("##ArtifactEditor", .{
        .buf = edit_buf[0.. :0],
        .h = 340.0,
        .flags = .{ .allow_tab_input = true },
    });
}

fn fillBuffer(buf: []u8, text: []const u8) void {
    const len = @min(text.len, buf.len - 1);
    std.mem.copyForwards(u8, buf[0..len], text[0..len]);
    buf[len] = 0;
    if (len + 1 < buf.len) {
        @memset(buf[len + 1 ..], 0);
    }
}
