# Testing Strategy

This document defines the test strategy for ZiggyStarClaw across native, UI, WASM, and Android targets.

## Goals

- Validate core protocol and client logic with fast unit tests.
- Provide deterministic, repeatable build + smoke checks for all platforms.
- Reduce UI regressions with compile checks and optional visual smoke tests.
- Keep tests runnable on developer machines and CI with clear prerequisites.

## Test Layers

### 1) Unit Tests (fast, deterministic)

**What**: Pure logic tests for protocol serialization, client state, and logging.

**Where**: `tests/` (e.g., `protocol_tests.zig`, `client_tests.zig`, `logger_tests.zig`, `ui_tests.zig`).

**Run**:
```bash
./.tools/zig-0.15.2/zig build test
```

**Notes**:
- `ui_tests.zig` is currently compile-only (no rendering backend).
- Keep these tests independent of network and filesystem where possible.

### 2) Build + Smoke Tests (cross-platform)

**What**: Ensure each target compiles and produces expected artifacts.

**Native**:
```bash
./.tools/zig-0.15.2/zig build
```

**Windows (cross-compile)**:
```bash
./.tools/zig-0.15.2/zig build -Dtarget=x86_64-windows-gnu
```

**WASM (Emscripten)**:
```bash
source ./scripts/emsdk-env.sh
./.tools/zig-0.15.2/zig build -Dwasm=true
```

**Android**:
```bash
ANDROID_SDK_ROOT=./.tools/android-sdk \
ANDROID_HOME=./.tools/android-sdk \
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
./.tools/zig-0.15.2/zig build -Dandroid=true
```

### 3) UI Tests (compile + smoke + optional visual)

**Compile-only (current)**:
- Ensures UI modules compile and link.
- Run via `zig build test`.

**Manual smoke checklist** (native / wasm / android):
- App starts without crash.
- Main window renders and updates.
- Settings view opens, inputs are editable, and buttons respond.
- Chat view renders messages and input field.
- Status bar updates connection state.

**Optional visual regression (future)**:
- Capture reference screenshots for key screens.
- Compare images in CI using a pixel-diff tool.
- This can be implemented later by adding a headless rendering path or by driving the app with scripted input.

### 4) WASM Browser Tests

**Minimum**: ensure build output exists and loads in browser.

**Manual**:
```bash
./scripts/serve-web.sh 8080
# open http://localhost:8080/ziggystarclaw-client.html
```

**Optional automation** (future):
- Use Playwright to load the page and confirm WebSocket connection + UI visibility.
- Verify a minimal UI element exists (e.g., Settings button or status text).

### 5) Android Device Tests

**Minimum**: build APK and install on a device/emulator.

**Install + run**:
```bash
adb install -r zig-out/bin/ziggystarclaw_android.apk
adb shell am start -S -W -n com.deanoc.ziggystarclaw/org.libsdl.app.SDLActivity
```

**Check logs**:
```bash
adb logcat -v time ZiggyStarClaw:D *:S
```

## Automation Scripts

New helper scripts in `scripts/`:

- `scripts/test-native.sh`: unit tests + native build
- `scripts/test-wasm.sh`: wasm build (requires emsdk)
- `scripts/test-android.sh`: android build (requires SDK/NDK)
- `scripts/test-all.sh`: runs native + windows + wasm + android (auto-skips missing toolchains)

## CI Suggestions (future)

- Run `scripts/test-all.sh` on Linux runners with emsdk + Android SDK preinstalled.
- For UI tests, start with screenshot comparisons only on nightly builds to reduce noise.
- Cache Zig and emsdk toolchains to speed up builds.

## Ownership

- Keep `tests/` fast and deterministic.
- Add integration tests as new subsystems are introduced (e.g., WebSocket connect/disconnect flows).
- Keep smoke tests up to date with UI feature changes.
