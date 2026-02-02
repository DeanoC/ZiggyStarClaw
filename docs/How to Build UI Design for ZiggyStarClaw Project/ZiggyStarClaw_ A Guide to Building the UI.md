# ZiggyStarClaw: A Guide to Building the UI

**Author:** Manus AI
**Date:** February 01, 2026

## 1. Introduction

This document provides a comprehensive guide for implementing the user interface for the ZiggyStarClaw project, as specified in the `ZiggyStarClaw_UI_Visual_Guide_v2.pdf`. It covers the visual design, functional requirements, and a detailed plan for building a reusable component library in Zig. 

Two primary implementation strategies are explored:

1.  **Extending the Existing ImGui System**: Leveraging the project's current `zgui` (Dear ImGui) foundation to build custom-styled widgets that match the visual guide.
2.  **Direct Rendering Approach**: A lower-level alternative for maximum control, building the UI from scratch using a graphics API like WebGPU or OpenGL.

This guide aims to provide the architectural blueprint and practical code examples needed to create a beautiful, functional, and maintainable UI that aligns with the project's vision.

## 2. Visual Design & Theming

The visual identity of ZiggyStarClaw is clean, modern, and information-dense. The design system is based on a light theme with clear typography, rounded elements, and a structured layout that adapts from desktop to mobile.

### 2.1. Color Palette

The provided visual guide specifies a light mode theme. The existing codebase uses a dark theme. The architecture should be updated to support theme switching. The light theme palette is defined as follows:

| Color Role         | Hex       | RGBA              | Description                               |
|--------------------|-----------|-------------------|-------------------------------------------|
| **Background**     | `#FFFFFF` | `(255, 255, 255)` | Main window and content background        |
| **Surface**        | `#F5F5F5` | `(245, 245, 245)` | Card and panel backgrounds                |
| **Primary**        | `#4285F4` | `(66, 133, 244)`  | Google Blue: Active elements, buttons     |
| **Success/Approve**| `#34A853` | `(52, 168, 83)`   | Google Green: Success states, approve btn |
| **Error/Decline**  | `#EA4335` | `(234, 67, 53)`   | Google Red: Error states, decline btn     |
| **Warning**        | `#FBBC04` | `(251, 188, 4)`   | Google Yellow: In-progress, warnings    |
| **Text Primary**   | `#202124` | `(32, 33, 36)`    | Main text, headers                        |
| **Text Secondary** | `#5F6368` | `(95, 99, 104)`   | Subtitles, placeholder text, details      |
| **Border**         | `#DADCE0` | `(218, 220, 224)` | Borders for cards and inputs              |
| **Divider**        | `#E8EAED` | `(232, 234, 237)` | Separators and dividers                   |

### 2.2. Typography

The project already embeds the `Space Grotesk` font family, which aligns well with the modern aesthetic. The guide will utilize different font weights and sizes for a clear visual hierarchy.

- **Font Family**: Space Grotesk (Regular, SemiBold)
- **Title**: 22pt, SemiBold
- **Heading**: 18pt, SemiBold
- **Body**: 16pt, Regular
- **Caption**: 12pt, Regular

### 2.3. Layout and Spacing

The design relies on a consistent spacing system and rounded corners to create a soft, approachable feel.

- **Corner Radius**: 4px (small), 8px (medium), 12px (large)
- **Padding**: 8px, 16px, 24px
- **Shadows**: Subtle shadows on cards to create depth.
- **Layout**: The UI uses a responsive three-column layout on desktop (Sidebar, Main Content, Detail Panel) that collapses gracefully on smaller screens.

## 3. Core UI Architecture

At the heart of the UI implementation is the choice between leveraging an existing framework like Dear ImGui or building a custom rendering pipeline. ZiggyStarClaw already uses `zgui`, making it the path of least resistance. However, understanding the direct rendering approach is valuable for performance tuning and custom widget development.

### 3.1. The Immediate Mode Paradigm

Both approaches will follow the principles of an Immediate Mode GUI (IMGUI). As researched in Ryan Fleury's articles [1], this paradigm simplifies UI development significantly:

> The widget hierarchy is constructed on every frame of an application's runtime, instead of being a stateful tree that must be carefully managed and mutated. This means it gracefully responds to changes in the hierarchy, which can be easily encoded.

This means our builder code for a widget is localized and simple. The logic for drawing, interaction, and state change is all in one place:

```zig
// Conceptual example
if (my_widgets.button("Click Me")) {
    // This code runs when the button is clicked in this frame
}
```

### 3.2. Strategy A: Extending the Existing ImGui System

This is the recommended primary strategy. It involves creating custom widget functions that wrap `zgui` calls, applying the visual theme, and managing state.

**Pros:**
- **Fast Development**: Builds on a mature, feature-rich library.
- **Cross-Platform**: `zgui` and its backends already handle platform differences.
- **Rich Feature Set**: Docking, tables, and complex inputs are already available.

**Cons:**
- **Styling Limitations**: Can be difficult to achieve pixel-perfect custom designs that deviate from ImGui's core rendering.
- **Dependency**: Relies on cimgui and C++ code.

### 3.3. Strategy B: Direct Rendering Approach

This strategy involves bypassing ImGui for specific components or even the entire UI, and drawing directly to the screen using a graphics API. The project's `zgpu` dependency (based on WebGPU/Dawn) makes this a viable, albeit more complex, option.

**Pros:**
- **Total Control**: Pixel-perfect rendering and complete control over layout and animation.
- **Performance**: Can be highly optimized for specific use cases.
- **No C++ Bloat**: A pure-Zig rendering pipeline is possible.

**Cons:**
- **High Complexity**: Requires implementing a custom rendering engine, layout system, and input handling.
- **More Code**: Features like text rendering, layout, and state management must be built from scratch.

This guide will provide implementation details for **both** strategies where applicable, allowing for a hybrid approach if needed.

## 4. Reusable Component Library

A robust and reusable component library is the cornerstone of a maintainable UI. Based on the analysis of the visual guide, we have identified a set of core, layout, navigation, and data-display components. The proposed file structure organizes these components logically within the `src/ui/components` directory.

### 4.1. Component Structure

The proposed structure separates components by their function, promoting modularity and ease of discovery.

```
src/ui/components/
├── core/            # Foundational elements (Button, Badge)
├── layout/          # Containers (Card, Sidebar, HeaderBar)
├── navigation/      # Navigation controls (TabBar, NavItem)
├── data/            # Data display (FileRow, ProgressStep)
├── feedback/        # User feedback (ApprovalCard, Toast)
└── composite/       # Complex, composed components (ProjectCard)
```

Each component will be implemented in its own Zig file, containing its data structures, styling options, and a `draw` function. This approach encapsulates the logic for each UI element, making them easy to test, reuse, and modify.

### 4.2. Core Component Interface

To ensure consistency, all components should share a common interface. A `Widget` struct can define the basic properties shared by all UI elements, such as a unique identifier, its bounding rectangle, style information, and its current interaction state.

```zig
// src/ui/components/core/widget.zig
pub const Widget = struct {
    id: u64,
    bounds: Rect,
    state: State,

    pub const State = enum {
        idle,     // Default state
        hovered,  // Mouse is over the widget
        pressed,  // Mouse button is down on the widget
        focused,  // Widget has keyboard focus
        disabled, // Widget is not interactive
    };
};
```

### 4.3. Component Implementation Examples

This section provides high-level implementation details for key components identified in the visual guide. Each component will have a `draw` function that takes a `DrawContext` and returns an action or state change.

#### Button Component

The button is the most fundamental interactive element. It needs to support different visual styles (variants), sizes, and states (enabled/disabled).

-   **File**: `src/ui/components/core/button.zig`
-   **Key Fields**: `label`, `icon`, `variant`, `size`, `disabled`
-   **Actions**: Returns `true` on the frame it is clicked.

#### Card Component

Cards are used as containers for related information, such as in the "Projects Overview" and "Approvals Inbox". They feature rounded corners and a subtle shadow to lift them from the background.

-   **File**: `src/ui/components/layout/card.zig`
-   **Key Fields**: `title`, `elevation`, `background_image`
-   **Usage**: Implemented as `begin()` and `end()` functions to wrap other content.

#### Sidebar Component

The primary navigation element, the sidebar contains a list of `NavItems` and indicates the active project. It should be collapsible to maximize content space.

-   **File**: `src/ui/components/layout/sidebar.zig`
-   **Key Fields**: `items`, `selected_index`, `collapsed`
-   **Actions**: Returns the index of the clicked `NavItem`.

#### ProgressStep Component

Used in the "Run Inspector", this component visually represents a single step in a multi-step process, showing its status (complete, in-progress, pending).

-   **File**: `src/ui/components/data/progress_step.zig`
-   **Key Fields**: `number`, `label`, `state`, `detail`
-   **Usage**: Drawn in a vertical list to show the full task flow.

## 5. Implementation Guide: ImGui Strategy

This section details how to implement the custom components by extending the existing `zgui` framework. The core idea is to wrap ImGui calls in our own functions, applying the custom theme and layout logic.

### 5.1. Theming with ImGui

The existing `theme.zig` file already demonstrates how to set ImGui colors and styles. To support the new light theme, we will create a `Theme` struct and functions to apply either a light or dark theme.

```zig
// src/ui/theme/theme.zig
pub const Theme = struct {
    colors: Colors,
    typography: Typography,
    // ... spacing, radius, etc.
};

pub fn applyTheme(theme: *const Theme) void {
    const style = zgui.getStyle();
    style.setColor(.text, theme.colors.text_primary);
    style.setColor(.window_bg, theme.colors.background);
    style.setColor(.frame_bg, theme.colors.surface);
    // ... set all other colors
    
    style.window_rounding = theme.radius.md;
    style.frame_rounding = theme.radius.sm;
}
```

### 5.2. Building a Custom Button

Here is a practical example of creating a custom button component that adheres to our design system, using `zgui`.

```zig
// src/ui/components/core/button.zig
const zgui = @import("zgui");
const theme = @import("../../theme/theme.zig");

pub fn draw(label: []const u8, variant: theme.ButtonVariant) bool {
    const colors = theme.active.colors;
    const style = theme.getButtonStyle(variant);

    // Push custom colors and styles
    zgui.pushStyleColor(.button, style.background);
    zgui.pushStyleColor(.button_hovered, style.background_hovered);
    zgui.pushStyleColor(.button_active, style.background_active);
    zgui.pushStyleColor(.text, style.foreground);
    zgui.pushStyleVar(.frame_rounding, theme.active.radius.md);
    
    // Defer popping the styles to ensure they are always removed
    defer zgui.popStyleColor(4);
    defer zgui.popStyleVar(1);

    // Draw the button and return its clicked state
    return zgui.button(label, .{});
}
```

This `button.draw` function can now be used throughout the application, ensuring all buttons are consistent with the theme. A similar wrapping approach can be used for all other components.

### 5.3. Creating the Card Layout

Cards can be implemented using a styled `ChildWindow` in ImGui. This provides a scrollable, bordered container.

```zig
// src/ui/components/layout/card.zig

pub fn begin(id: []const u8, size: zgui.Vec2) bool {
    const colors = theme.active.colors;
    zgui.pushStyleColor(.child_bg, colors.surface);
    zgui.pushStyleColor(.border, colors.border);
    zgui.pushStyleVar(.child_rounding, theme.active.radius.lg);
    zgui.pushStyleVar(.child_border_size, 1.0);

    return zgui.beginChild(id, .{ .size = size, .bordered = true });
}

pub fn end() {
    zgui.endChild();
    zgui.popStyleColor(2);
    zgui.popStyleVar(2);
}
```

This pattern of pushing styles, drawing the widget, and popping styles is fundamental to creating a custom-themed UI with Dear ImGui.

## 6. Implementation Guide: Direct Rendering Strategy

For ultimate control and performance, a direct rendering approach can be adopted. This involves drawing UI elements as simple geometric shapes (quads, lines, circles) and managing the entire rendering pipeline. This strategy is more involved but offers unparalleled flexibility.

### 6.1. Rendering Primitives

The foundation of a direct rendering UI is a set of functions for drawing basic primitives. The `DrawContext` introduced in the architecture section would be implemented to call these functions.

```zig
// src/ui/rendering/direct_renderer.zig
const zgpu = @import("zgpu");

pub const DirectBackend = struct {
    gctx: *zgpu.GraphicsContext,
    pipeline: zgpu.RenderPipeline,
    vertex_buffer: zgpu.Buffer,
    // ... other rendering resources

    pub fn drawRect(self: *DirectBackend, rect: Rect, color: Color) void {
        // 1. Generate vertices for the quad
        // 2. Update vertex buffer
        // 3. Set pipeline state
        // 4. Issue draw call
    }

    pub fn drawText(self: *DirectBackend, text: []const u8, pos: Vec2, font: *Font) void {
        // 1. Use a font rendering library (e.g., freetype) to get glyphs
        // 2. For each glyph, generate a textured quad
        // 3. Draw all quads in a single batch
    }
};
```

### 6.2. Building a Custom Button (Direct Rendering)

With direct rendering, a button is just a rounded rectangle with text. The `draw` function becomes responsible for everything: calculating bounds, checking for input, and drawing each visual layer.

```zig
// src/ui/components/core/button_direct.zig

pub fn draw(ctx: *DrawContext, id: u64, rect: Rect, label: []const u8) bool {
    const input = ctx.getInputState();
    var state = ctx.getWidgetState(id);
    var clicked = false;

    // 1. Hit testing
    if (rect.contains(input.mouse_pos)) {
        state = .hovered;
        if (input.mouse_left_pressed) {
            state = .pressed;
        } else if (input.mouse_left_released) {
            clicked = true;
        }
    } else {
        state = .idle;
    }

    // 2. Drawing
    const style = theme.getButtonStyleForState(state);
    ctx.renderer.drawRoundedRect(rect, theme.active.radius.md, style.background);
    ctx.renderer.drawText(label, rect.center(), style.foreground);
    
    // 3. Update state
    ctx.setWidgetState(id, state);
    
    return clicked;
}
```

This approach provides complete freedom but requires careful management of state, layout, and rendering details for every single component.

## 7. Conclusion and Recommendations

This guide has outlined two viable strategies for implementing the ZiggyStarClaw UI. The choice between them depends on the project's priorities.

-   **For rapid development and leveraging existing features**, the **ImGui Strategy** is strongly recommended. It aligns with the project's current technology stack and provides a clear path to implementing the visual design with minimal friction.

-   **For learning, maximum performance, or highly custom visual effects**, the **Direct Rendering Strategy** is a powerful alternative. It offers complete control at the cost of increased complexity.

A **hybrid approach** is also possible, where most of the UI is built with ImGui, but specific, performance-critical, or visually complex components (like custom charts) are implemented using direct rendering.

By following the proposed component architecture and theming system, the ZiggyStarClaw project can achieve a beautiful, functional, and maintainable user interface that fulfills the vision of the design guide.

## 8. References

[1] Fleury, R. (2022). *UI, Part 2: Every Single Frame (IMGUI)*. [https://www.rfleury.com/p/ui-part-2-build-it-every-frame-immediate](https://www.rfleury.com/p/ui-part-2-build-it-every-frame-immediate)
