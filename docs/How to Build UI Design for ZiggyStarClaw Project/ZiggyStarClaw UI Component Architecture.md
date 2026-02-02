# ZiggyStarClaw UI Component Architecture

## Overview

This document defines the reusable component architecture for implementing the ZiggyStarClaw visual design. The architecture supports both Dear ImGui (via zgui) and direct rendering approaches.

## Component Hierarchy

```
src/ui/
├── components/           # Reusable UI components
│   ├── core/            # Foundation components
│   │   ├── button.zig
│   │   ├── icon_button.zig
│   │   ├── text_label.zig
│   │   ├── badge.zig
│   │   └── separator.zig
│   ├── layout/          # Layout containers
│   │   ├── card.zig
│   │   ├── sidebar.zig
│   │   ├── header_bar.zig
│   │   ├── split_pane.zig
│   │   └── scroll_area.zig
│   ├── navigation/      # Navigation components
│   │   ├── tab_bar.zig
│   │   ├── nav_item.zig
│   │   └── breadcrumb.zig
│   ├── data/            # Data display components
│   │   ├── list_item.zig
│   │   ├── file_row.zig
│   │   ├── progress_step.zig
│   │   └── agent_status.zig
│   ├── feedback/        # User feedback components
│   │   ├── approval_card.zig
│   │   ├── toast.zig
│   │   └── status_indicator.zig
│   └── composite/       # Higher-level composed components
│       ├── project_card.zig
│       ├── artifact_row.zig
│       ├── source_browser.zig
│       └── task_progress.zig
├── views/               # Full view implementations
│   ├── projects_view.zig
│   ├── sources_view.zig
│   ├── artifact_workspace.zig
│   ├── run_inspector.zig
│   └── approvals_inbox.zig
├── theme/               # Theming system
│   ├── colors.zig
│   ├── typography.zig
│   ├── spacing.zig
│   └── theme.zig
└── rendering/           # Rendering backends
    ├── imgui_renderer.zig
    └── direct_renderer.zig
```

## Core Component Interface

### Base Widget Trait
```zig
pub const Widget = struct {
    id: WidgetId,
    bounds: Rect,
    style: Style,
    state: WidgetState,
    
    pub const WidgetState = enum {
        idle,
        hovered,
        pressed,
        focused,
        disabled,
    };
};

pub const WidgetId = struct {
    hash: u64,
    
    pub fn from(src: std.builtin.SourceLocation) WidgetId {
        return .{ .hash = hashSourceLocation(src) };
    }
};
```

### Style System
```zig
pub const Style = struct {
    // Colors
    background: Color,
    foreground: Color,
    border: Color,
    accent: Color,
    
    // Dimensions
    padding: Insets,
    margin: Insets,
    border_width: f32,
    border_radius: f32,
    
    // Typography
    font: FontRole,
    font_size: f32,
    
    // Layout
    min_width: ?f32,
    min_height: ?f32,
    max_width: ?f32,
    max_height: ?f32,
};
```

## Component Specifications

### 1. Button Component
```zig
pub const Button = struct {
    pub const Variant = enum {
        primary,
        secondary,
        success,   // Approve
        danger,    // Decline
        ghost,
    };
    
    pub const Size = enum {
        small,
        medium,
        large,
    };
    
    label: []const u8,
    icon: ?Icon,
    variant: Variant,
    size: Size,
    disabled: bool,
    
    pub fn draw(self: *Button, ctx: *DrawContext) bool;
};
```

### 2. Card Component
```zig
pub const Card = struct {
    pub const Elevation = enum {
        flat,
        raised,
        floating,
    };
    
    title: ?[]const u8,
    subtitle: ?[]const u8,
    background_image: ?Texture,
    elevation: Elevation,
    
    pub fn begin(self: *Card, ctx: *DrawContext) void;
    pub fn end(self: *Card, ctx: *DrawContext) void;
};
```

### 3. Sidebar Component
```zig
pub const Sidebar = struct {
    width: f32,
    collapsed: bool,
    items: []NavItem,
    selected_index: ?usize,
    
    pub fn draw(self: *Sidebar, ctx: *DrawContext) ?usize;
};

pub const NavItem = struct {
    icon: Icon,
    label: []const u8,
    badge: ?Badge,
    children: ?[]NavItem,
};
```

### 4. FileRow Component
```zig
pub const FileRow = struct {
    pub const FileType = enum {
        folder,
        document,
        spreadsheet,
        image,
        code,
        generic,
    };
    
    name: []const u8,
    file_type: FileType,
    status: ?Status,
    size: ?[]const u8,
    modified: ?[]const u8,
    
    pub const Status = enum {
        indexed,
        pending,
        error,
    };
    
    pub fn draw(self: *FileRow, ctx: *DrawContext) FileRowAction;
};
```

### 5. ProgressStep Component
```zig
pub const ProgressStep = struct {
    pub const State = enum {
        pending,
        in_progress,
        complete,
        error,
    };
    
    number: u32,
    label: []const u8,
    state: State,
    detail: ?[]const u8,
    
    pub fn draw(self: *ProgressStep, ctx: *DrawContext) void;
};
```

### 6. ApprovalCard Component
```zig
pub const ApprovalCard = struct {
    title: []const u8,
    description: []const u8,
    agent_name: ?[]const u8,
    target: ?[]const u8,
    timestamp: ?i64,
    
    pub const Action = enum {
        none,
        approve,
        decline,
    };
    
    pub fn draw(self: *ApprovalCard, ctx: *DrawContext) Action;
};
```

### 7. AgentStatus Component
```zig
pub const AgentStatus = struct {
    pub const State = enum {
        ready,
        working,
        idle,
        error,
    };
    
    name: []const u8,
    role: []const u8,
    state: State,
    current_task: ?[]const u8,
    
    pub fn draw(self: *AgentStatus, ctx: *DrawContext) bool;
};
```

### 8. TabBar Component
```zig
pub const TabBar = struct {
    pub const TabStyle = enum {
        underline,
        pill,
        segment,
    };
    
    tabs: []Tab,
    selected: usize,
    style: TabStyle,
    
    pub const Tab = struct {
        label: []const u8,
        icon: ?Icon,
        badge: ?u32,
        closeable: bool,
    };
    
    pub fn draw(self: *TabBar, ctx: *DrawContext) TabAction;
};
```

### 9. ProjectCard Component (Composite)
```zig
pub const ProjectCard = struct {
    name: []const u8,
    description: ?[]const u8,
    background_gradient: ?Gradient,
    background_image: ?Texture,
    categories: []Category,
    recent_artifacts: []Artifact,
    
    pub const Category = struct {
        name: []const u8,
        icon: Icon,
    };
    
    pub const Artifact = struct {
        name: []const u8,
        file_type: FileRow.FileType,
        status: []const u8,
    };
    
    pub fn draw(self: *ProjectCard, ctx: *DrawContext) ProjectCardAction;
};
```

### 10. SourceBrowser Component (Composite)
```zig
pub const SourceBrowser = struct {
    sources: []Source,
    selected_source: ?usize,
    current_path: []const u8,
    files: []FileEntry,
    
    pub const Source = struct {
        name: []const u8,
        source_type: SourceType,
        connected: bool,
    };
    
    pub const SourceType = enum {
        local,
        cloud,
        git,
    };
    
    pub fn draw(self: *SourceBrowser, ctx: *DrawContext) SourceBrowserAction;
};
```

## Theme Definitions

### Light Theme (from PDF)
```zig
pub const light_theme = Theme{
    .colors = .{
        .background = rgba(255, 255, 255, 255),
        .surface = rgba(245, 245, 245, 255),
        .primary = rgba(66, 133, 244, 255),    // Google Blue
        .secondary = rgba(52, 168, 83, 255),   // Google Green
        .error = rgba(234, 67, 53, 255),       // Google Red
        .warning = rgba(251, 188, 4, 255),     // Google Yellow
        .text_primary = rgba(32, 33, 36, 255),
        .text_secondary = rgba(95, 99, 104, 255),
        .border = rgba(218, 220, 224, 255),
        .divider = rgba(232, 234, 237, 255),
    },
    .typography = .{
        .font_family = "Space Grotesk",
        .heading_size = 22.0,
        .body_size = 16.0,
        .caption_size = 12.0,
    },
    .spacing = .{
        .xs = 4.0,
        .sm = 8.0,
        .md = 16.0,
        .lg = 24.0,
        .xl = 32.0,
    },
    .radius = .{
        .sm = 4.0,
        .md = 8.0,
        .lg = 12.0,
        .full = 9999.0,
    },
    .shadows = .{
        .sm = Shadow{ .blur = 2.0, .spread = 0.0, .offset_y = 1.0 },
        .md = Shadow{ .blur = 4.0, .spread = 0.0, .offset_y = 2.0 },
        .lg = Shadow{ .blur = 8.0, .spread = 0.0, .offset_y = 4.0 },
    },
};
```

## Rendering Abstraction

### DrawContext Interface
```zig
pub const DrawContext = struct {
    backend: Backend,
    theme: *const Theme,
    viewport: Rect,
    clip_stack: std.ArrayList(Rect),
    
    pub const Backend = union(enum) {
        imgui: *ImGuiBackend,
        direct: *DirectBackend,
    };
    
    // Primitive drawing
    pub fn drawRect(self: *DrawContext, rect: Rect, style: RectStyle) void;
    pub fn drawRoundedRect(self: *DrawContext, rect: Rect, radius: f32, style: RectStyle) void;
    pub fn drawText(self: *DrawContext, text: []const u8, pos: Vec2, style: TextStyle) void;
    pub fn drawIcon(self: *DrawContext, icon: Icon, pos: Vec2, size: f32, color: Color) void;
    pub fn drawImage(self: *DrawContext, texture: Texture, rect: Rect) void;
    pub fn drawLine(self: *DrawContext, from: Vec2, to: Vec2, width: f32, color: Color) void;
    
    // Clipping
    pub fn pushClip(self: *DrawContext, rect: Rect) void;
    pub fn popClip(self: *DrawContext) void;
    
    // Input
    pub fn isHovered(self: *DrawContext, rect: Rect) bool;
    pub fn isClicked(self: *DrawContext, rect: Rect) bool;
    pub fn isDragging(self: *DrawContext, rect: Rect) bool;
};
```

## View Implementations

### Projects Overview View
```zig
pub const ProjectsView = struct {
    sidebar: Sidebar,
    project_card: ?ProjectCard,
    recent_artifacts: std.ArrayList(Artifact),
    
    pub fn init(allocator: std.mem.Allocator) ProjectsView;
    pub fn deinit(self: *ProjectsView) void;
    pub fn draw(self: *ProjectsView, ctx: *DrawContext) ProjectsViewAction;
};
```

### Run Inspector View
```zig
pub const RunInspectorView = struct {
    steps: std.ArrayList(ProgressStep),
    current_step: usize,
    logs_visible: bool,
    log_content: TextBuffer,
    
    pub fn draw(self: *RunInspectorView, ctx: *DrawContext) RunInspectorAction;
};
```

### Approvals Inbox View
```zig
pub const ApprovalsInboxView = struct {
    approvals: std.ArrayList(ApprovalCard),
    filter: ApprovalFilter,
    
    pub const ApprovalFilter = enum {
        all,
        pending,
        resolved,
    };
    
    pub fn draw(self: *ApprovalsInboxView, ctx: *DrawContext) ApprovalsAction;
};
```

## Implementation Priority

### Phase 1: Core Components
1. Button (all variants)
2. Card
3. TabBar
4. FileRow
5. Badge

### Phase 2: Layout Components
1. Sidebar
2. HeaderBar
3. SplitPane
4. ScrollArea

### Phase 3: Data Components
1. ProgressStep
2. AgentStatus
3. ApprovalCard
4. ListItem

### Phase 4: Composite Components
1. ProjectCard
2. SourceBrowser
3. TaskProgress
4. ArtifactRow

### Phase 5: Views
1. ProjectsView
2. SourcesView
3. RunInspectorView
4. ApprovalsInboxView
5. ArtifactWorkspaceView
