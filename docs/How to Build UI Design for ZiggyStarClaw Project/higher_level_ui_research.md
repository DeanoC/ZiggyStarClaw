# Research Findings: Higher-Level UI Components

## 1. Node Editor Architecture

### Core Concepts (from imnodes and Guillaume's blog)

**Immediate Mode Node Graph Pattern:**
- Main state (nodes, pins, links) lives in user's data structures
- Map internal state to UI elements via `BeginNode`, `EndNode`, `BeginInputAttribute`, `BeginOutputAttribute`, `EndAttribute`, `Link` calls
- Library is a reflection of user's state - nodes/links created/deleted by modifying user data
- Behind the scenes: node/pin/link identity retained frame-to-frame
- Node positions, editor panning, depth order tracked automatically

**Key Architectural Insight (Guillaume Boissé):**
> "The main insight to take away is the need to separate the data (data model) from the UI logic (view). Having such a separation naturally implies creating an interface for iterating the data inside your 'project' that can then be used both by the runtime and the ImGui code."

**Node Types Pattern:**
1. **Root Node** - Graph traversal starting point
2. **Data Node** - Represents data of a given type
3. **Component Node** - Attached to data nodes to modify them

**Data Model Components:**
- Assets: Imported resources (models, textures, etc.)
- Layers: Grouping nodes for organization
- Nodes: Belong to layers, executed by runtime
- Ranges: Time segments for when resources are active
- Properties: Node values, colors, links to assets/other nodes

### Implementation Requirements
1. Canvas with pan/zoom
2. Node rendering with title, inputs, outputs
3. Connection system (bezier curves)
4. Hit testing for nodes, pins, connections
5. Drag and drop for nodes and connections
6. Selection system (single and multi)
7. Context menus for node creation
8. Undo/redo support

## 2. Chat Interface Architecture

### Existing ZiggyStarClaw Patterns (from chat_view.zig)
- Message list with auto-scroll to bottom
- Role-based message grouping with headers
- Timestamp display (relative time)
- Select/copy mode toggle
- Tool output filtering
- Image attachment support with caching
- Context menu for message actions

### Chat Interface Patterns (from Agentic Design)

**Core Components:**
1. **Threading System** - Conversation branching & merging logic
2. **Rich Content** - Documents, code, images, interactive widgets
3. **Agent Features** - Thinking indicators & source citations
4. **Collaboration** - Real-time presence & message reactions
5. **Context Management** - Thread preservation & summarization

**Flow:** user_message → thread_routing → content_rendering → agent_response → context_update

**Best Practices:**
- Support threaded conversations for topic exploration
- Show agent thinking process with visual indicators
- Integrate rich media (documents, code, images)
- Provide source citations with expandable details
- Enable message reactions and collaborative editing

**Anti-Patterns:**
- Force linear conversation flow only
- Hide agent reasoning process from users
- Limit to text-only interactions
- Lose context when switching between threads

### Key Metrics
- Thread Engagement: Active branches per conversation
- Content Interaction: Rich media usage & sharing rate
- Context Retention: Thread switching without loss

## 3. Media Viewer Architecture

### Existing ZiggyStarClaw Patterns (from image_cache.zig)
- Async image loading with thread pool
- Texture caching with LRU eviction
- Data URI decoding support
- WASM and native fetch paths
- Texture upload to GPU
- Memory budget management (64MB default)

### Media Viewer Components

**Image Viewer:**
- Zoom controls (fit, fill, 1:1, custom)
- Pan/drag navigation
- Thumbnail strip/gallery view
- Lazy loading for large collections
- Format support (PNG, JPG, GIF, WebP)

**Video Player:**
- Play/pause/seek controls
- Timeline scrubber
- Volume control
- Fullscreen toggle
- Frame-by-frame navigation
- Playback speed control

**Document Viewer:**
- PDF rendering
- Page navigation
- Zoom controls
- Text selection
- Search functionality

### Implementation Patterns

**Virtualization:**
- Only render visible items
- Recycle DOM/widgets
- Bidirectional scrolling support
- Placeholder loading states

**Caching Strategy:**
- Memory cache for recent items
- Disk cache for persistence
- Prefetch adjacent items
- Eviction based on LRU + size

## 4. Component Integration Points

### Shared Infrastructure
- Event system for cross-component communication
- Undo/redo stack
- Clipboard integration
- Drag and drop between components
- Keyboard shortcuts

### State Management
- Centralized state store
- Component-local state for UI
- Persistence layer for save/load
- History tracking for undo/redo

## 5. References

1. imnodes Wiki - https://github.com/Nelarius/imnodes/wiki
2. Guillaume Boissé - Visual node graph with ImGui - https://gboisse.github.io/posts/node-graph/
3. Agentic Design - Chat Interface Patterns - https://agentic-design.ai/patterns/ui-ux-patterns/chat-interface-patterns
4. ZiggyStarClaw existing code - chat_view.zig, image_cache.zig
