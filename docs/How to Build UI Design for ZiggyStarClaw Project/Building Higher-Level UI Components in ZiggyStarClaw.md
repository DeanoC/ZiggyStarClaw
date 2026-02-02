# Building Higher-Level UI Components in ZiggyStarClaw

**Author:** Manus AI
**Date:** February 01, 2026

## 1. Introduction

This guide provides a comprehensive overview and practical implementation patterns for building sophisticated, higher-level UI components within the ZiggyStarClaw project. Moving beyond basic widgets, we will explore the architecture and design of three complex UI systems that are common in creative and technical applications:

1.  **Node Editors**: For visual programming, creating graphs, and defining complex relationships.
2.  **Advanced Chat Interfaces**: For rich, threaded conversations with media and interactive elements.
3.  **Media Viewers**: For displaying and interacting with images, videos, and documents.

This document builds upon the foundational component library and theming system established in the previous UI guide. The primary goal is to provide a clear architectural blueprint that separates data from presentation, enabling the creation of robust, maintainable, and performant UI systems in Zig using the immediate mode paradigm.

## 2. Core Principle: Data Model vs. View

Before diving into specific components, it is crucial to reiterate the most important architectural principle: the strict separation of the **data model** from the **view** (the UI code). This concept is the key to managing the complexity of higher-level UIs.

As highlighted in the research by Guillaume Boissé [2], this separation is fundamental:

> "The main insight to take away in my opinion is the need to separate the data (what I’d call the data model) from the UI logic (often referred to as the view). Having such a separation naturally implies creating an interface for iterating the data inside your ‘project’ that can then be used both by the runtime... and the ImGui code, when running the editor."

-   **The Data Model**: This is the pure, UI-agnostic representation of your application's state. For a node editor, this would be a collection of nodes and links with their properties. For a chat interface, it's a structured list of messages. This model should contain no rendering code or UI-specific state.

-   **The View**: This is the immediate-mode GUI code that iterates over the data model each frame and renders the appropriate widgets. It holds transient UI state (e.g., scroll position, which window is focused) but does not own the core application data.

This separation provides numerous benefits, including easier state management, simplified serialization (saving/loading), straightforward implementation of undo/redo, and the ability to have multiple views of the same data.

## 3. Building a Node Editor

Node editors are powerful tools for visual programming and graph-based workflows. The architecture described here is inspired by established libraries like imnodes [1] and the practical implementation detailed by Guillaume Boissé [2].

### 3.1. Node Editor Data Model

The first step is to define a clear, UI-independent data structure for the node graph. This model will live in the `src/ui/data/` directory.

```zig
// src/ui/data/node_graph.zig
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
};
```

### 3.2. The Canvas Component

The canvas is the main view component that orchestrates the rendering and interaction of the node graph. It is responsible for panning, zooming, and managing the overall interaction state.

-   **State Management**: The canvas maintains its own view state (pan, zoom) but operates on a pointer to the external `NodeGraph` data model.
-   **Coordinate System**: It manages the transformation between screen coordinates (mouse position) and canvas coordinates (the world space where nodes exist).
-   **Interaction Logic**: It handles background dragging for panning, mouse wheel for zooming, and box selection.

### 3.3. Node and Pin Rendering

With the canvas in place, we can create functions to render the individual elements. These functions take a piece of the data model and draw it.

-   **Node Drawing**: A `drawNode` function takes a `Node` struct and renders it as a styled window or a custom-drawn rounded rectangle. It iterates through the node's pins and draws them.
-   **Pin Drawing**: A `drawPin` function renders a single input or output pin (typically a circle) and handles the logic for creating new links when a user clicks and drags from it.
-   **Link Drawing**: A `drawLink` function draws a Bézier curve between the screen positions of two connected pins.

### 3.4. Interaction Model

Interaction within an immediate mode node editor is a state machine managed by the canvas component.

1.  **Idle**: The default state. The canvas checks for hovers on nodes, pins, and links.
2.  **Dragging**: If the user clicks and drags a node, the canvas enters a `dragging_nodes` state. On each frame in this state, it updates the `position` of the selected nodes in the data model based on the mouse delta.
3.  **Linking**: If the user clicks and drags from a pin, the canvas enters a `creating_link` state. It stores the source pin ID and draws a link from that pin to the current mouse cursor position. If the user releases the mouse over a compatible pin, a new `Link` is created in the data model. If released elsewhere, the interaction is cancelled.
4.  **Panning**: If the user drags the canvas background, the `view.offset` is updated.

This separation of data and view logic makes the system predictable and easy to debug. The UI is simply a visual representation of the `NodeGraph` struct, and all interactions directly and safely manipulate that data.

## 4. Building an Advanced Chat Interface

The existing chat implementation in ZiggyStarClaw provides a solid foundation. To evolve this into a higher-level component, we will introduce more advanced features like threading, rich content, and explicit agent-specific UI patterns, as suggested by sources like Agentic Design [3].

### 4.1. Evolving the Chat Data Model

To support advanced features, the data model needs to be expanded to include concepts like threads, reactions, and structured content. This model should be defined in `src/ui/data/chat_history.zig`.

```zig
// src/ui/data/chat_history.zig
pub const ChatHistory = struct {
    threads: std.ArrayList(Thread),
    active_thread_idx: ?usize,

    pub const Thread = struct {
        id: []const u8,
        messages: std.ArrayList(Message),
    };

    pub const Message = struct {
        id: []const u8,
        role: Role,
        content: Content,
        timestamp: i64,
        attachments: ?[]Attachment,
        reactions: ?[]Reaction,

        pub const Role = enum { user, assistant, system, tool };
        pub const Content = union(enum) {
            text: []const u8,
            code: struct { language: []const u8, code: []const u8 },
        };
    };

    pub const Attachment = struct { /* ... */ };
    pub const Reaction = struct { /* ... */ };
};
```

### 4.2. The Message List Component

The `MessageList` is the core view responsible for rendering the conversation. Its primary challenge is performance when dealing with thousands of messages.

-   **Virtualization**: To handle long conversations efficiently, a virtualized list is essential. Instead of rendering all messages, the view only renders the items currently visible in the viewport, plus a small buffer. As the user scrolls, previously visible items are recycled and new ones are rendered. This keeps the number of active widgets low, ensuring high performance.
-   **Scroll Management**: The component must manage scroll state, including auto-scrolling to the bottom for new messages and restoring scroll position when switching between threads.
-   **Grouping**: Messages can be grouped by role or time to improve readability, as is already partially implemented in `chat_view.zig`.

### 4.3. Message Bubble Component

Each message is rendered inside a `MessageBubble`. This component is responsible for the visual presentation of a single `Message` from the data model.

-   **Content Rendering**: The bubble must be able to render different types of content from the `Message.Content` union, such as formatted text (with Markdown support), syntax-highlighted code blocks, and attachments.
-   **Agent-Specific Cues**: For messages from the `assistant` role, the bubble can include visual indicators of the agent's status (e.g., a 

## 5. Building a Media Viewer

Media viewers are essential for applications that handle images, videos, or documents. The architecture for a media viewer must prioritize performance, especially with large files and collections, and provide an intuitive user experience.

### 5.1. Media Viewer Data Model

A `MediaCollection` data model will represent a set of viewable items. This allows the viewer components to be agnostic of where the media comes from (e.g., a file system, a chat history, or a web URL).

```zig
// src/ui/data/media_collection.zig
pub const MediaCollection = struct {
    items: std.ArrayList(MediaItem),
    current_index: ?usize,

    pub const MediaItem = struct {
        id: []const u8,
        media_type: MediaType,
        source_url: []const u8,
        metadata: ?Metadata,

        pub const MediaType = enum { image, video, document };
        pub const Metadata = struct {
            width: ?u32,
            height: ?u32,
            duration: ?f64,
            file_size: ?u64,
        };
    };
};
```

### 5.2. Image Viewer Component

The image viewer is responsible for displaying a single image with interactive controls.

-   **Zoom and Pan**: The core functionality involves managing a view transform (zoom and offset). User input (mouse wheel, dragging) updates this transform, and the image is rendered with the corresponding matrix.
-   **Fit Modes**: The viewer should support common fit modes like "Fit to Screen," "Fill Screen," and "Actual Size."
-   **Caching**: It will leverage the existing `image_cache.zig` system to manage texture loading and memory. The viewer requests an image from the cache, which handles the asynchronous loading and provides a texture handle when ready.

### 5.3. Video Player Component

Video playback requires integration with a backend library (like FFMpeg or a platform-specific API) to handle decoding and frame delivery.

-   **Playback State**: The component manages the playback state (playing, paused, seeking) and the current timestamp.
-   **Controls UI**: A controls overlay (for play/pause, scrubber, volume) is rendered on top of the video texture. The overlay fades out during playback and reappears on mouse movement.
-   **Texture Updates**: The video decoding backend provides new frames as textures, which are updated on the GPU each frame during playback.

### 5.4. Gallery Component

The gallery view displays a collection of media items, typically as thumbnails.

-   **Layouts**: It should support multiple layouts, such as a uniform grid, a masonry layout for items of different aspect ratios, or a carousel.
-   **Virtualization**: Like the chat message list, the gallery must use virtualization to efficiently display large collections. Only the thumbnails for visible items are rendered.
-   **Lazy Loading**: Thumbnails are loaded asynchronously as they scroll into view, using the same image caching system.

## 6. Shared Systems

To support these advanced components and ensure a cohesive user experience, a set of shared systems should be developed. These systems provide common functionality that can be used across different UI views.

### 6.1. Undo/Redo System

A robust undo/redo system is critical for complex applications. The Command pattern is a perfect fit for this.

-   **Command Stack**: Maintain two stacks: one for undo actions and one for redo actions.
-   **Command Interface**: Define a `Command` interface with `execute()` and `undo()` methods.
-   **Implementation**: When a user performs an action (e.g., moving a node, sending a message), create a command object that encapsulates the action and its inverse, execute it, and push it onto the undo stack. To undo, pop from the undo stack, call the command's `undo()` method, and push it onto the redo stack.

### 6.2. Drag and Drop System

A centralized drag-and-drop manager allows for rich interactions between different components (e.g., dragging a media item from a gallery into a node graph).

-   **Payload System**: When a drag operation starts, the source component provides a `DragPayload` containing the data being dragged and its type.
-   **Drop Targets**: Components can register themselves as `DropTarget`s, specifying the data types they accept.
-   **Manager Logic**: The manager tracks the active payload and, on mouse release, checks if the cursor is over a compatible drop target, notifying it if so.

### 6.3. Keyboard and Focus Management

A dedicated manager for keyboard shortcuts and input focus is essential for a professional-feeling application.

-   **Focus Ring**: Manage which component or widget currently has keyboard focus.
-   **Shortcut Registry**: Allow components to register keyboard shortcuts that are active when they or their children have focus.
-   **Event Propagation**: Handle the propagation of keyboard events, allowing focused components to consume an event or let it bubble up to a parent.

## 7. Conclusion

Building higher-level UI components in an immediate mode GUI framework like zgui requires a disciplined approach centered on the separation of data and view. By defining clear data models for each component and creating stateless, reusable view functions to render them, you can manage complexity and build powerful, interactive systems. The shared systems for undo/redo, drag-and-drop, and keyboard management provide the connective tissue that elevates a collection of components into a cohesive and professional application.

This guide provides the architectural blueprint. The next step is to implement these data models and view components, starting with the simplest pieces and progressively adding complexity.

## 8. References

[1] Nelarius. (n.d.). *imnodes Wiki*. GitHub. Retrieved February 1, 2026, from https://github.com/Nelarius/imnodes/wiki

[2] Boissé, G. (2023, September 28). *Visual node graph with ImGui*. Guillaume's graphics blog. Retrieved February 1, 2026, from https://gboisse.github.io/posts/node-graph/

[3] Agentic Design. (n.d.). *Chat Interface Patterns (CIP)*. Agentic Design. Retrieved February 1, 2026, from https://agentic-design.ai/patterns/ui-ux-patterns/chat-interface-patterns
