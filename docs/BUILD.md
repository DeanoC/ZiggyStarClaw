# Build

## Requirements

- Zig 0.15.2+
- For WASM: Emscripten SDK installed under `.tools/emsdk`

## Native Build

```bash
zig build
zig build run
```

## Tests

```bash
zig build test
```

## WASM Build (Emscripten via zemscripten)

```bash
# Install emsdk once (if not already installed)
./.tools/emsdk/emsdk install latest
./.tools/emsdk/emsdk activate latest

# Build
zig build -Dwasm=true
```

Outputs are installed under `zig-out/web/` (HTML/JS/WASM).
