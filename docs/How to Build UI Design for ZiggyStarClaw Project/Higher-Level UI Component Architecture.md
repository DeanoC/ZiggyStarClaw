# Higher-Level UI Component Architecture

## Overview

This document defines the architecture for implementing complex, higher-level UI components in ZiggyStarClaw: Node Editors, Chat Interfaces, and Media Viewers. These components build upon the foundational component library and share common infrastructure for state management, event handling, and rendering.

## Directory Structure

```
src/ui/
├── components/           # Base components (from previous guide)
├── views/               # Higher-level composed views
│   ├── node_editor/     # Node graph editor
│   │   ├── canvas.zig
│   │   ├── node.zig
│   │   ├── pin.zig
│   │   ├── link.zig
│   │   ├── selection.zig
│   │   └── context_menu.zig
│   ├── chat/            # Chat interface
│   │   ├── message_list.zig
│   │   ├── message_bubble.zig
│   │   ├── input_area.zig
│   │   ├── thread_view.zig
│   │   └── attachment.zig
│   └── media/           # Media viewers
│       ├── image_viewer.zig
│       ├── video_player.zig
│       ├── gallery.zig
│       └── document_viewer.zig
├── systems/             # Shared systems
│   ├── undo_redo.zig
│   ├── clipboard.zig
│   ├── drag_drop.zig
│   └── keyboard.zig
└── data/                # Data models
    ├── node_graph.zig
    ├── chat_history.zig
    └── media_collection.zig
```

## 1. Node Editor Architecture

### Data Model

```zig
pub const NodeGraph = struct {
    nodes: std.StringHashMap(Node),
    links: std.ArrayList(Link),
    
    pub const Node = struct {
        id: []const u8,
        type_id: []const u8,
        position: Vec2,
        size: Vec2,
        inputs: []Pin,
        outputs: []Pin,
        properties: std.StringHashMap(Property),
        collapsed: bool,
    };
    
    pub const Pin = struct {
        id: []const u8,
        name: []const u8,
        data_type: DataType,
        connected: bool,
    };
    
    pub const Link = struct {
        id: u64,
        source_node: []const u8,
        source_pin: []const u8,
        target_node: []const u8,
        target_pin: []const u8,
    };
    
    pub const DataType = enum {
        float,
        vec2,
        vec3,
        vec4,
        color,
        texture,
        geometry,
        any,
    };
};
```

### Canvas Component

```zig
pub const NodeCanvas = struct {
    graph: *NodeGraph,
    view: CanvasView,
    selection: Selection,
    interaction: InteractionState,
    style: CanvasStyle,
    
    pub const CanvasView = struct {
        offset: Vec2,      // Pan offset
        zoom: f32,         // Zoom level (0.1 to 4.0)
        grid_size: f32,    // Snap grid size
    };
    
    pub const InteractionState = union(enum) {
        idle,
        panning: Vec2,
        selecting_box: Rect,
        dragging_nodes: []const u8,
        creating_link: LinkDraft,
        context_menu: Vec2,
    };
    
    pub fn draw(self: *NodeCanvas, ctx: *DrawContext) CanvasAction;
    pub fn screenToCanvas(self: *NodeCanvas, screen_pos: Vec2) Vec2;
    pub fn canvasToScreen(self: *NodeCanvas, canvas_pos: Vec2) Vec2;
};
```

### Node Rendering

```zig
pub const NodeRenderer = struct {
    pub fn drawNode(
        ctx: *DrawContext,
        node: *const NodeGraph.Node,
        style: NodeStyle,
        state: NodeState,
    ) NodeAction {
        // 1. Draw node background (rounded rect with shadow)
        // 2. Draw header with title and collapse button
        // 3. Draw input pins on left
        // 4. Draw output pins on right
        // 5. Draw properties in body
        // 6. Handle interactions
    }
    
    pub fn drawPin(
        ctx: *DrawContext,
        pin: *const NodeGraph.Pin,
        position: Vec2,
        is_input: bool,
    ) PinAction;
    
    pub fn drawLink(
        ctx: *DrawContext,
        start: Vec2,
        end: Vec2,
        style: LinkStyle,
    ) void;
};
```

## 2. Chat Interface Architecture

### Data Model

```zig
pub const ChatHistory = struct {
    threads: std.ArrayList(Thread),
    active_thread: ?usize,
    
    pub const Thread = struct {
        id: []const u8,
        title: ?[]const u8,
        messages: std.ArrayList(Message),
        created_at: i64,
        updated_at: i64,
    };
    
    pub const Message = struct {
        id: []const u8,
        role: Role,
        content: Content,
        timestamp: i64,
        attachments: ?[]Attachment,
        reactions: ?[]Reaction,
        status: MessageStatus,
        
        pub const Role = enum {
            user,
            assistant,
            system,
            tool,
        };
        
        pub const Content = union(enum) {
            text: []const u8,
            code: CodeBlock,
            rich: RichContent,
        };
        
        pub const MessageStatus = enum {
            sending,
            sent,
            delivered,
            error,
        };
    };
    
    pub const Attachment = struct {
        id: []const u8,
        kind: AttachmentKind,
        url: []const u8,
        name: ?[]const u8,
        size: ?u64,
        thumbnail_url: ?[]const u8,
    };
};
```

### Message List Component

```zig
pub const MessageList = struct {
    history: *ChatHistory,
    scroll_state: ScrollState,
    selection: ?MessageSelection,
    config: MessageListConfig,
    
    pub const ScrollState = struct {
        offset: f32,
        auto_scroll: bool,
        scroll_to_bottom_pending: bool,
    };
    
    pub const MessageListConfig = struct {
        show_timestamps: bool,
        show_avatars: bool,
        group_by_role: bool,
        show_tool_output: bool,
        max_image_width: f32,
        max_image_height: f32,
    };
    
    pub fn draw(self: *MessageList, ctx: *DrawContext, height: f32) MessageListAction;
    pub fn scrollToMessage(self: *MessageList, message_id: []const u8) void;
    pub fn scrollToBottom(self: *MessageList) void;
};
```

### Message Bubble Component

```zig
pub const MessageBubble = struct {
    pub fn draw(
        ctx: *DrawContext,
        message: *const ChatHistory.Message,
        config: BubbleConfig,
    ) BubbleAction {
        // 1. Draw role header with timestamp
        // 2. Draw content based on type
        // 3. Draw attachments
        // 4. Draw reactions bar
        // 5. Handle context menu
    }
    
    pub const BubbleConfig = struct {
        max_width: f32,
        show_avatar: bool,
        show_timestamp: bool,
        enable_selection: bool,
    };
    
    pub const BubbleAction = union(enum) {
        none,
        copy_text,
        view_attachment: []const u8,
        add_reaction: []const u8,
        reply,
    };
};
```

### Input Area Component

```zig
pub const ChatInputArea = struct {
    buffer: TextBuffer,
    attachments: std.ArrayList(PendingAttachment),
    state: InputState,
    
    pub const InputState = enum {
        idle,
        typing,
        uploading,
        disabled,
    };
    
    pub const PendingAttachment = struct {
        path: []const u8,
        name: []const u8,
        size: u64,
        upload_progress: ?f32,
    };
    
    pub fn draw(self: *ChatInputArea, ctx: *DrawContext) InputAction;
    pub fn addAttachment(self: *ChatInputArea, path: []const u8) !void;
    pub fn clear(self: *ChatInputArea) void;
};
```

## 3. Media Viewer Architecture

### Data Model

```zig
pub const MediaCollection = struct {
    items: std.ArrayList(MediaItem),
    current_index: ?usize,
    
    pub const MediaItem = struct {
        id: []const u8,
        media_type: MediaType,
        source: Source,
        metadata: Metadata,
        cache_state: CacheState,
        
        pub const MediaType = enum {
            image,
            video,
            audio,
            document,
        };
        
        pub const Source = union(enum) {
            url: []const u8,
            file_path: []const u8,
            data_uri: []const u8,
        };
        
        pub const Metadata = struct {
            width: ?u32,
            height: ?u32,
            duration: ?f64,
            file_size: ?u64,
            mime_type: ?[]const u8,
        };
    };
};
```

### Image Viewer Component

```zig
pub const ImageViewer = struct {
    image: ?*MediaCollection.MediaItem,
    view: ViewState,
    controls: ControlsState,
    
    pub const ViewState = struct {
        zoom: f32,
        offset: Vec2,
        rotation: f32,
        fit_mode: FitMode,
        
        pub const FitMode = enum {
            fit,
            fill,
            actual,
            custom,
        };
    };
    
    pub fn draw(self: *ImageViewer, ctx: *DrawContext, bounds: Rect) ImageViewerAction;
    pub fn zoomIn(self: *ImageViewer) void;
    pub fn zoomOut(self: *ImageViewer) void;
    pub fn resetView(self: *ImageViewer) void;
    pub fn rotate(self: *ImageViewer, degrees: f32) void;
};
```

### Video Player Component

```zig
pub const VideoPlayer = struct {
    video: ?*MediaCollection.MediaItem,
    playback: PlaybackState,
    controls: VideoControls,
    
    pub const PlaybackState = struct {
        playing: bool,
        current_time: f64,
        duration: f64,
        volume: f32,
        muted: bool,
        playback_rate: f32,
        buffered_ranges: []TimeRange,
    };
    
    pub const VideoControls = struct {
        show_controls: bool,
        controls_visible_until: i64,
        seeking: bool,
        seek_preview_time: ?f64,
    };
    
    pub fn draw(self: *VideoPlayer, ctx: *DrawContext, bounds: Rect) VideoPlayerAction;
    pub fn play(self: *VideoPlayer) void;
    pub fn pause(self: *VideoPlayer) void;
    pub fn seek(self: *VideoPlayer, time: f64) void;
    pub fn setVolume(self: *VideoPlayer, volume: f32) void;
};
```

### Gallery Component

```zig
pub const Gallery = struct {
    collection: *MediaCollection,
    layout: GalleryLayout,
    selection: std.ArrayList(usize),
    scroll_offset: f32,
    
    pub const GalleryLayout = union(enum) {
        grid: GridConfig,
        masonry: MasonryConfig,
        carousel: CarouselConfig,
        list: ListConfig,
    };
    
    pub const GridConfig = struct {
        columns: u32,
        item_size: f32,
        gap: f32,
    };
    
    pub fn draw(self: *Gallery, ctx: *DrawContext, bounds: Rect) GalleryAction;
    pub fn selectItem(self: *Gallery, index: usize) void;
    pub fn openItem(self: *Gallery, index: usize) void;
};
```

## 4. Shared Systems

### Undo/Redo System

```zig
pub const UndoRedoStack = struct {
    undo_stack: std.ArrayList(Command),
    redo_stack: std.ArrayList(Command),
    max_history: usize,
    
    pub const Command = struct {
        name: []const u8,
        undo_fn: *const fn (*anyopaque) void,
        redo_fn: *const fn (*anyopaque) void,
        data: *anyopaque,
    };
    
    pub fn execute(self: *UndoRedoStack, command: Command) void;
    pub fn undo(self: *UndoRedoStack) bool;
    pub fn redo(self: *UndoRedoStack) bool;
    pub fn canUndo(self: *UndoRedoStack) bool;
    pub fn canRedo(self: *UndoRedoStack) bool;
};
```

### Drag and Drop System

```zig
pub const DragDropManager = struct {
    active_drag: ?DragPayload,
    drop_targets: std.ArrayList(DropTarget),
    
    pub const DragPayload = struct {
        source_id: []const u8,
        data_type: []const u8,
        data: *anyopaque,
        preview_fn: ?*const fn (*DrawContext, Vec2) void,
    };
    
    pub const DropTarget = struct {
        id: []const u8,
        bounds: Rect,
        accepts: []const []const u8,
        on_drop: *const fn (DragPayload) void,
    };
    
    pub fn beginDrag(self: *DragDropManager, payload: DragPayload) void;
    pub fn endDrag(self: *DragDropManager) ?DropTarget;
    pub fn registerDropTarget(self: *DragDropManager, target: DropTarget) void;
};
```

## 5. Integration Example

```zig
// Main application integrating all higher-level components
pub const Application = struct {
    node_editor: NodeCanvas,
    chat: MessageList,
    media_viewer: ImageViewer,
    
    undo_redo: UndoRedoStack,
    drag_drop: DragDropManager,
    keyboard: KeyboardManager,
    
    pub fn draw(self: *Application, ctx: *DrawContext) void {
        // Layout with docking
        if (zgui.beginDockSpace("MainDockSpace")) {
            // Node editor panel
            if (zgui.begin("Node Editor")) {
                _ = self.node_editor.draw(ctx);
            }
            zgui.end();
            
            // Chat panel
            if (zgui.begin("Chat")) {
                _ = self.chat.draw(ctx, zgui.getContentRegionAvail()[1]);
            }
            zgui.end();
            
            // Media viewer panel
            if (zgui.begin("Media")) {
                const bounds = Rect.fromAvail(zgui.getContentRegionAvail());
                _ = self.media_viewer.draw(ctx, bounds);
            }
            zgui.end();
        }
        zgui.endDockSpace();
    }
};
```
