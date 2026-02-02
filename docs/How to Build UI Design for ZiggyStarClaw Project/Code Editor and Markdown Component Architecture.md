# Code Editor and Markdown Component Architecture

## Directory Structure

```
src/ui/
├── editors/
│   ├── code_editor/
│   │   ├── editor.zig           # Main editor component
│   │   ├── buffer.zig           # Text buffer (gap buffer/piece tree)
│   │   ├── cursor.zig           # Cursor and selection management
│   │   ├── highlighter.zig      # Syntax highlighting coordinator
│   │   ├── line_cache.zig       # Line metrics and layout cache
│   │   ├── gutter.zig           # Line numbers and markers
│   │   └── languages/
│   │       ├── zig.zig          # Zig tokenizer
│   │       ├── json.zig         # JSON tokenizer
│   │       ├── markdown.zig     # Markdown tokenizer
│   │       └── generic.zig      # Fallback tokenizer
│   └── markdown/
│       ├── editor.zig           # Markdown editor (source mode)
│       ├── viewer.zig           # Markdown renderer (preview mode)
│       ├── parser.zig           # Markdown parser
│       └── elements.zig         # Rendered element types
└── data/
    └── document.zig             # Shared document model
```

## 1. Code Editor Data Model

```zig
pub const Document = struct {
    buffer: TextBuffer,
    language: Language,
    file_path: ?[]const u8,
    encoding: Encoding,
    line_ending: LineEnding,
    
    pub const Language = enum {
        zig, c, cpp, json, markdown, glsl, hlsl, python, plain,
    };
    
    pub const Encoding = enum { utf8, utf16, ascii };
    pub const LineEnding = enum { lf, crlf, cr };
};
```

## 2. Text Buffer Interface

```zig
pub const TextBuffer = struct {
    // Core operations
    pub fn insert(self: *TextBuffer, pos: usize, text: []const u8) !void;
    pub fn delete(self: *TextBuffer, start: usize, end: usize) !void;
    pub fn getText(self: *TextBuffer, start: usize, end: usize) []const u8;
    
    // Line operations
    pub fn lineCount(self: *TextBuffer) usize;
    pub fn lineStart(self: *TextBuffer, line: usize) usize;
    pub fn lineEnd(self: *TextBuffer, line: usize) usize;
    pub fn lineAt(self: *TextBuffer, offset: usize) usize;
    
    // UTF-8 operations
    pub fn charCount(self: *TextBuffer) usize;
    pub fn offsetToChar(self: *TextBuffer, offset: usize) usize;
    pub fn charToOffset(self: *TextBuffer, char_idx: usize) usize;
};
```

## 3. Cursor and Selection

```zig
pub const Cursor = struct {
    position: Position,
    anchor: ?Position,        // For selection
    preferred_column: ?usize, // For vertical movement
    
    pub const Position = struct {
        line: usize,
        column: usize,
        offset: usize,        // Byte offset in buffer
    };
};

pub const Selection = struct {
    start: Cursor.Position,
    end: Cursor.Position,
    
    pub fn isEmpty(self: Selection) bool;
    pub fn normalize(self: Selection) Selection;
};

pub const CursorManager = struct {
    primary: Cursor,
    secondary: std.ArrayList(Cursor),  // Multi-cursor support
};
```

## 4. Syntax Highlighting

```zig
pub const Token = struct {
    start: usize,
    end: usize,
    kind: TokenKind,
};

pub const TokenKind = enum {
    keyword,
    identifier,
    string,
    number,
    comment,
    operator,
    punctuation,
    type_name,
    function_name,
    builtin,
    error,
    whitespace,
    default,
};

pub const Tokenizer = struct {
    pub fn tokenize(
        self: *Tokenizer,
        text: []const u8,
        tokens: *std.ArrayList(Token),
    ) void;
};

pub const Highlighter = struct {
    language: Document.Language,
    tokenizer: *Tokenizer,
    token_cache: LineTokenCache,
    
    pub fn getTokensForLine(self: *Highlighter, line: usize) []const Token;
    pub fn invalidateFrom(self: *Highlighter, line: usize) void;
};
```

## 5. Code Editor Component

```zig
pub const CodeEditor = struct {
    document: *Document,
    cursor_manager: CursorManager,
    highlighter: Highlighter,
    gutter: Gutter,
    scroll: ScrollState,
    config: EditorConfig,
    undo_stack: UndoStack,
    
    pub const EditorConfig = struct {
        font: *Font,
        tab_size: u8,
        insert_spaces: bool,
        show_line_numbers: bool,
        show_whitespace: bool,
        word_wrap: bool,
        line_height: f32,
    };
    
    pub fn draw(self: *CodeEditor, ctx: *DrawContext) EditorAction;
    pub fn handleInput(self: *CodeEditor, event: InputEvent) void;
    pub fn insertText(self: *CodeEditor, text: []const u8) void;
    pub fn deleteSelection(self: *CodeEditor) void;
    pub fn undo(self: *CodeEditor) void;
    pub fn redo(self: *CodeEditor) void;
};
```

## 6. Markdown Parser

```zig
pub const MarkdownNode = union(enum) {
    document: Document,
    heading: Heading,
    paragraph: Paragraph,
    code_block: CodeBlock,
    inline_code: InlineCode,
    emphasis: Emphasis,
    strong: Strong,
    link: Link,
    image: Image,
    list: List,
    list_item: ListItem,
    blockquote: Blockquote,
    horizontal_rule,
    line_break,
    text: []const u8,
    
    pub const Heading = struct {
        level: u8,
        children: []MarkdownNode,
    };
    
    pub const CodeBlock = struct {
        language: ?[]const u8,
        code: []const u8,
    };
    
    pub const Link = struct {
        url: []const u8,
        title: ?[]const u8,
        children: []MarkdownNode,
    };
};

pub const MarkdownParser = struct {
    pub fn parse(
        allocator: std.mem.Allocator,
        source: []const u8,
    ) ![]MarkdownNode;
};
```

## 7. Markdown Viewer Component

```zig
pub const MarkdownViewer = struct {
    nodes: []MarkdownNode,
    scroll: ScrollState,
    config: ViewerConfig,
    link_callback: ?*const fn([]const u8) void,
    image_loader: *ImageLoader,
    
    pub const ViewerConfig = struct {
        base_font: *Font,
        heading_fonts: [3]*Font,
        code_font: *Font,
        base_color: [4]f32,
        link_color: [4]f32,
        code_bg_color: [4]f32,
        line_spacing: f32,
        paragraph_spacing: f32,
    };
    
    pub fn draw(self: *MarkdownViewer, ctx: *DrawContext) ViewerAction;
    pub fn setContent(self: *MarkdownViewer, source: []const u8) !void;
};
```

## 8. Markdown Editor Component

```zig
pub const MarkdownEditor = struct {
    code_editor: CodeEditor,
    viewer: MarkdownViewer,
    mode: Mode,
    split_ratio: f32,
    
    pub const Mode = enum {
        source,
        preview,
        split,
    };
    
    pub fn draw(self: *MarkdownEditor, ctx: *DrawContext) EditorAction;
    pub fn setMode(self: *MarkdownEditor, mode: Mode) void;
    pub fn toggleMode(self: *MarkdownEditor) void;
};
```

## 9. Color Scheme

```zig
pub const SyntaxColors = struct {
    keyword: [4]f32,
    identifier: [4]f32,
    string: [4]f32,
    number: [4]f32,
    comment: [4]f32,
    operator: [4]f32,
    type_name: [4]f32,
    function_name: [4]f32,
    builtin: [4]f32,
    error: [4]f32,
    background: [4]f32,
    line_number: [4]f32,
    selection: [4]f32,
    cursor: [4]f32,
    
    pub const dark_theme = SyntaxColors{
        .keyword = .{ 0.86, 0.56, 0.74, 1.0 },      // Pink
        .identifier = .{ 0.86, 0.86, 0.86, 1.0 },   // Light gray
        .string = .{ 0.72, 0.89, 0.63, 1.0 },       // Green
        .number = .{ 0.84, 0.73, 0.49, 1.0 },       // Orange
        .comment = .{ 0.50, 0.55, 0.50, 1.0 },      // Gray
        .operator = .{ 0.86, 0.86, 0.86, 1.0 },     // Light gray
        .type_name = .{ 0.56, 0.83, 0.90, 1.0 },    // Cyan
        .function_name = .{ 0.60, 0.80, 0.60, 1.0 },// Light green
        .builtin = .{ 0.94, 0.78, 0.46, 1.0 },      // Yellow
        .error = .{ 1.0, 0.4, 0.4, 1.0 },           // Red
        .background = .{ 0.12, 0.12, 0.14, 1.0 },   // Dark
        .line_number = .{ 0.40, 0.40, 0.45, 1.0 },  // Dim
        .selection = .{ 0.26, 0.40, 0.60, 0.5 },    // Blue transparent
        .cursor = .{ 0.90, 0.90, 0.90, 1.0 },       // White
    };
};
```
