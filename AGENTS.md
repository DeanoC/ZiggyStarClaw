# MoltBot Zig Client - Build & Run

This repo uses the pinned Zig toolchain at `./.tools/zig-0.15.2/zig`.

## Native (Linux)

Build:
```bash
./.tools/zig-0.15.2/zig build
```

Run:
```bash
./zig-out/bin/moltbot-client
```

CLI:
```bash
./zig-out/bin/moltbot-cli
```

## Windows (cross-compile from Linux)

Build:
```bash
./.tools/zig-0.15.2/zig build -Dtarget=x86_64-windows-gnu
```

Artifacts:
```
zig-out/bin/moltbot-client.exe
zig-out/bin/moltbot-cli.exe
```

## WASM (Emscripten)

Load emsdk env (once per shell):
```bash
source ./scripts/emsdk-env.sh
```

Build:
```bash
./.tools/zig-0.15.2/zig build -Dwasm=true
```

Serve locally:
```bash
./scripts/serve-web.sh 8080
```

Open:
```
http://localhost:8080/moltbot-client.html
```

## Android (SDL + OpenGL ES)

Build APK:
```bash
./.tools/zig-0.15.2/zig build -Dandroid=true
```

APK output:
```
zig-out/bin/moltbot_android.apk
```

Install + run (from Windows PowerShell or any adb shell):
```powershell
adb install -r zig-out\bin\moltbot_android.apk
adb shell am start -S -W -n com.deanoc.moltbot/org.libsdl.app.SDLActivity
```

Logcat filter:
```powershell
adb logcat -v time MoltBot:D *:S
```
