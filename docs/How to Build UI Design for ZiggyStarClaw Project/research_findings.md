# Research Findings: Zig UI Implementation Approaches

## 1. Immediate Mode GUI (IMGUI) Architecture

### Core Concepts (from Ryan Fleury's article)
- **Two-layer architecture**: Core layer (common codepaths, helpers) + Builder code (concrete UI implementations)
- **Localized widget code**: All code for a widget (text, appearance, click handling) in one spot
- **Per-frame reconstruction**: Widget hierarchy rebuilt every frame instead of stateful tree management
- **Graceful hierarchy changes**: No explicit add/remove code needed for dynamic UI

### Key Pattern
```c
if(UI_Button("Hello, World!")) {
  // this code runs when button is clicked
}
```

### Layout Strategies
1. **Manual coordinates** - Simple but maintenance-heavy
2. **Layout offset tracking** - Better but adds noise
3. **Layout objects** - Cleaner, reusable layout logic
4. **Contextual state** - Selected layout as global/thread-local state
5. **Autolayout** - Widgets specify semantic size, system calculates positions

### Autolayout Approach
- Widgets specify **semantic size** (e.g., "text size", "percentage of parent", "fill remaining")
- Core computes actual pixel rectangles
- Supports parent-child relationships for nested layouts

## 2. ZiggyStarClaw Current Architecture

### Technology Stack
- **zgui**: Zig bindings for Dear ImGui
- **zgpu/zglfw**: WebGPU and GLFW bindings
- **Backends**: WebGPU (Dawn), OpenGL fallback
- **Platforms**: Linux, Windows, macOS, Android, WASM

### Existing UI Structure
- `theme.zig` - Color palette, typography, styling
- `panel_manager.zig` - Panel lifecycle management
- `workspace.zig` - Panel types (Chat, CodeEditor, ToolOutput, Control)
- `main_window.zig` - Main UI orchestration with docking
- `panels/` - Individual panel implementations

### Current Panel Types
1. **Chat** - Message history and input
2. **CodeEditor** - File editing with language support
3. **ToolOutput** - Command output display
4. **Control** - Settings, sessions, operator tabs

## 3. Alternative: DVUI (Native Zig GUI)

### Features
- Pure Zig implementation
- Immediate mode interface
- Multiple backends: SDL2/3, Raylib, Dx11, Web
- Built-in widgets: buttons, text entry, sliders, menus, etc.
- Touch support, accessibility, animations, themes

### Key Advantages
- No C dependencies for core
- Process every input event (good for low-fps)
- Composable widget functions

## 4. Direct Rendering Approach

### When to Use
- Maximum control over rendering
- Custom visual effects
- Performance-critical applications
- Learning/educational purposes

### Components Needed
1. **Vertex buffer management** - Quad generation for UI elements
2. **Texture atlas** - Font rendering, icons
3. **Shader programs** - Basic 2D rendering, effects
4. **Input handling** - Mouse/keyboard/touch events
5. **Layout engine** - Position calculation
6. **Hit testing** - Determine which element is under cursor

### Zig Libraries for Direct Rendering
- `zgpu` - WebGPU bindings (cross-platform)
- `zopengl` - OpenGL bindings
- `zglfw` - Window/input management
- `stb_truetype` - Font rendering

## 5. Component Architecture Recommendations

### For ZiggyStarClaw Visual Guide Components

| Component | ImGui Approach | Direct Rendering |
|-----------|---------------|------------------|
| WindowFrame | Custom title bar widget | Draw rounded rect + traffic lights |
| Sidebar | Child window + selectable list | Vertical layout container |
| ProjectCard | Custom widget with image bg | Textured quad + text overlay |
| FileListItem | Selectable with icon | Horizontal layout + icon texture |
| TabBar | zgui.beginTabBar | Custom tab button row |
| Button | zgui.button with styling | Rounded rect + text + hover state |
| ProgressStep | Custom widget | Circle + line + text |
| ApprovalCard | Group box + buttons | Card container + button pair |
| AgentStatusRow | Selectable + colored dot | Row layout + status indicator |
| ChartContainer | Plot widgets or custom | Vertex buffer for chart data |

### Reusable Component Pattern (Zig)
```zig
pub const Button = struct {
    label: []const u8,
    style: ButtonStyle,
    state: ButtonState,
    
    pub fn init(label: []const u8, style: ButtonStyle) Button {
        return .{ .label = label, .style = style, .state = .idle };
    }
    
    pub fn draw(self: *Button, ctx: *DrawContext) bool {
        // Calculate bounds
        // Handle input
        // Draw background, text
        // Return clicked state
    }
};
```

## 6. Theming System

### Current ZiggyStarClaw Theme (Dark)
- Background: rgba(20, 23, 26)
- Accent: rgba(229, 148, 59) - Orange
- Text: rgba(230, 233, 237)
- Border: rgba(43, 49, 58)
- Rounding: 6-8px

### Light Mode (from PDF)
- Background: White/Light gray
- Accent: Google-style colors (Blue, Red, Yellow, Green)
- Text: Dark gray/black
- Cards: Rounded corners, subtle shadows
