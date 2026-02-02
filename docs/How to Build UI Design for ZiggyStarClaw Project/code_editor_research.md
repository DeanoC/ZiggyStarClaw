# Research Findings: Code Editor and Markdown Components

## 1. Existing ZiggyStarClaw Patterns

### Current Code Editor (code_editor_panel.zig)
- Uses zgui.inputTextMultiline for basic editing
- TextBuffer struct wraps ArrayList(u8) with null terminator
- Tracks version and last_modified_by (user vs AI)
- No syntax highlighting currently
- No line numbers

### TextBuffer Implementation
- Simple ArrayList-based buffer
- Supports set, ensureCapacity, syncFromInput
- Provides asZ() for null-terminated slice
- Provides slice() for regular slice

## 2. Text Buffer Data Structures

### Gap Buffer
- Simple to implement
- Emacs uses this approach
- O(1) for local edits, O(n) for cursor jumps
- NOT optimal for multi-cursor editing
- Good for single-cursor, localized editing

### Rope
- Tree-based structure
- O(log n) insertion/deletion anywhere
- Good for undo/redo (tree snapshots)
- Memory overhead from tree nodes
- Good for multi-cursor editing

### Piece Table
- Original buffer + append buffer + piece descriptors
- Microsoft Word used this historically
- Efficient for undo/redo
- Can degrade with very long edit sessions

### Piece Tree (VSCode approach)
- Piece table + red-black tree
- Best of rope and piece table
- O(log n) operations
- Efficient memory usage
- Excellent for multi-cursor editing
- **Recommended for ZiggyStarClaw**

## 3. Syntax Highlighting Approaches

### ImGuiColorTextEdit Features
- UTF-8 support
- Undo/redo built-in
- Fixed and variable-width fonts
- Extensible language definitions
- Error markers with tooltips
- Color palette support
- Whitespace indicators
- C/C++ has hand-written tokenizer (fast)
- Other languages use regex (slower, amortized)

### Tree-sitter
- Incremental parsing
- Very fast syntax highlighting
- Language-agnostic
- Used by Neovim, Helix, etc.
- More complex to integrate

### Simple Tokenizer Approach
- Hand-written lexer per language
- Fast for common languages
- Easier to implement in Zig
- Good for initial implementation

## 4. Markdown Rendering Approaches

### imgui_markdown (enkisoftware)
- Single-header library
- Supports: headers, emphasis, lists, links, images
- Requires C++11
- Simple but limited

### imgui_md (mekhontsev)
- Uses MD4C parser
- More complete Markdown support:
  - Tables
  - Strikethrough
  - Underline
  - HTML elements
  - Backslash escapes
- Subclass-based customization
- Font switching for headers/bold
- Image loading callback

### MD4C Parser
- Fast C Markdown parser
- SAX-like interface
- CommonMark compliant
- Can be wrapped in Zig

## 5. Key Implementation Decisions

### For Code Editor
1. **Buffer**: Start with gap buffer for simplicity, migrate to piece tree later
2. **Highlighting**: Hand-written tokenizer for common languages (Zig, C, JSON)
3. **Line Numbers**: Custom rendering in left margin
4. **Undo/Redo**: Command pattern with state snapshots

### For Markdown
1. **Parser**: Use MD4C or implement simple subset
2. **Rendering**: Custom ImGui rendering with font switching
3. **Edit Mode**: Toggle between source and preview
4. **Live Preview**: Side-by-side or split view

## 6. References

1. ImGuiColorTextEdit - https://github.com/BalazsJako/ImGuiColorTextEdit
2. imgui_markdown - https://github.com/enkisoftware/imgui_markdown
3. imgui_md - https://github.com/mekhontsev/imgui_md
4. MD4C Parser - https://github.com/mity/md4c
5. Text Editor Data Structures - https://cdacamar.github.io/data%20structures/algorithms/benchmarking/text%20editors/c++/editor-data-structures/
6. VSCode Piece Tree - https://github.com/microsoft/vscode-textbuffer
