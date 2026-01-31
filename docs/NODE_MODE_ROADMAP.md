# ZiggyStarClaw Node Mode Roadmap

## Overview

This document outlines the implementation plan for adding **node mode** to ZiggyStarClaw, allowing it to function as both an **operator client** (current) and a **capability node** (new) in the OpenClaw ecosystem.

### Node vs Operator

| Aspect | Operator | Node |
|--------|----------|------|
| **Role** | `operator` | `node` |
| **Purpose** | Control plane - chat, manage, approve | Capability host - execute commands |
| **Scopes** | `operator.read`, `operator.write`, `operator.admin`, etc. | (none - uses caps/commands) |
| **Caps** | Empty | `camera`, `canvas`, `screen`, `system`, etc. |
| **Commands** | Empty | `system.run`, `camera.snap`, `canvas.eval`, etc. |
| **Invokes** | Yes (calls node.invoke) | Yes (receives node.invoke) |

## Protocol Requirements

### 1. Connection Handshake (Node Mode)

Nodes connect to the same WebSocket endpoint but with different parameters:

```json
{
  "type": "req",
  "id": "<uuid>",
  "method": "connect",
  "params": {
    "minProtocol": 3,
    "maxProtocol": 3,
    "client": {
      "id": "ziggystarclaw-node",
      "version": "0.2.0",
      "platform": "linux|windows|android|wasm",
      "mode": "node",
      "displayName": "Ziggy Node (Linux)"
    },
    "role": "node",
    "scopes": [],
    "caps": ["system", "canvas", "screen"],
    "commands": [
      "system.run",
      "system.which",
      "system.notify",
      "system.execApprovals.get",
      "system.execApprovals.set",
      "canvas.present",
      "canvas.hide",
      "canvas.navigate",
      "canvas.eval",
      "canvas.snapshot",
      "screen.record"
    ],
    "permissions": {
      "screen.record": true,
      "system.run": true
    },
    "auth": { "token": "..." },
    "device": {
      "id": "<device-fingerprint>",
      "publicKey": "<base64-key>",
      "signature": "<signature>",
      "signedAt": 1737264000000,
      "nonce": "<server-nonce>"
    }
  }
}
```

### 2. Node.invoke Request Handling

Nodes receive `node.invoke` requests from the Gateway:

```json
{
  "type": "req",
  "id": "<request-id>",
  "method": "node.invoke",
  "params": {
    "command": "system.run",
    "params": {
      "command": ["/bin/sh", "-lc", "uname -a"],
      "cwd": "/home/user",
      "env": { "KEY": "value" },
      "timeoutMs": 30000
    },
    "idempotencyKey": "<uuid>"
  }
}
```

Response:
```json
{
  "type": "res",
  "id": "<request-id>",
  "ok": true,
  "payload": {
    "stdout": "Linux hostname 5.15.0...",
    "stderr": "",
    "exitCode": 0
  }
}
```

### 3. Error Codes

Nodes must return appropriate error codes:

| Error | Description |
|-------|-------------|
| `NODE_COMMAND_NOT_SUPPORTED` | Command not in advertised list |
| `NODE_BACKGROUND_UNAVAILABLE` | Command requires foreground (camera/canvas) |
| `CAMERA_DISABLED` | Camera capability disabled by user |
| `CAMERA_PERMISSION_REQUIRED` | Missing camera permission |
| `SCREEN_RECORDING_PERMISSION_REQUIRED` | Missing screen recording permission |
| `SYSTEM_RUN_DENIED` | Exec approval denied |
| `TIMEOUT` | Command execution timeout |

## Platform Capability Matrix

### Linux (Primary Target)

| Capability | Priority | Implementation Notes |
|------------|----------|---------------------|
| `system.run` | P0 | Execute shell commands with allowlist |
| `system.which` | P0 | Path resolution |
| `system.notify` | P1 | Desktop notifications (notify-send) |
| `system.execApprovals.get/set` | P0 | Read/write `~/.openclaw/exec-approvals.json` |
| `canvas.present` | P2 | Launch browser window (SDL/WebView) |
| `canvas.hide` | P2 | Close browser window |
| `canvas.navigate` | P2 | Navigate to URL |
| `canvas.eval` | P2 | Execute JavaScript |
| `canvas.snapshot` | P2 | Screenshot canvas |
| `screen.record` | P3 | Screen capture (ffmpeg) |

### Windows

| Capability | Priority | Implementation Notes |
|------------|----------|---------------------|
| `system.run` | P0 | CMD/PowerShell execution |
| `system.which` | P0 | `where.exe` equivalent |
| `system.notify` | P1 | Windows toast notifications |
| `system.execApprovals.get/set` | P0 | JSON config in `%APPDATA%` |
| `canvas.*` | P2 | Edge WebView2 integration |
| `screen.record` | P3 | DXGI/Desktop Duplication |

### Android

| Capability | Priority | Implementation Notes |
|------------|----------|---------------------|
| `system.run` | P0 | Limited shell via Runtime.exec |
| `camera.snap` | P1 | Camera2 API integration |
| `camera.clip` | P2 | Video recording |
| `screen.record` | P2 | MediaProjection API |
| `location.get` | P2 | Fused Location Provider |
| `sms.send` | P3 | SMS Manager (with permission) |

### WASM (Web)

| Capability | Priority | Implementation Notes |
|------------|----------|---------------------|
| `canvas.*` | P2 | Browser canvas/WebGL |
| `system.run` | P3 | Limited via WebAssembly sandbox |

## Implementation Phases

### Phase 1: Core Node Infrastructure (Foundation)

**Goal:** Basic node mode with system command execution

**Tasks:**
1. **Node State Management**
   - Add `NodeContext` struct alongside `ClientContext`
   - Track node-specific state (capabilities, permissions, pending commands)
   - Store node config in `~/.openclaw/node.json`

2. **Connection Mode Selection**
   - Add `--node-mode` CLI flag
   - Modify connect handshake to use `role: "node"` when in node mode
   - Advertise `system.run`, `system.which` commands

3. **Node Request Handler**
   - Implement `handleNodeInvoke()` in event handler
   - Parse incoming `node.invoke` requests
   - Route to appropriate command handler

4. **System Command Execution**
   - Implement `system.run` with exec approval checks
   - Implement `system.which` for path resolution
   - Read allowlist from `~/.openclaw/exec-approvals.json`
   - Return stdout/stderr/exit code

5. **Exec Approvals Management**
   - Implement `system.execApprovals.get`
   - Implement `system.execApprovals.set`
   - JSON serialization for approvals file

**Deliverable:** ZiggyStarClaw can run as a headless node host executing approved shell commands

---

### Phase 2: Canvas & Visualization (UI Capabilities)

**Goal:** Browser-based canvas for agent visualization

**Tasks:**
1. **SDL + WebView Integration**
   - Add WebView dependency (or use SDL + embedded browser)
   - Create canvas window management
   - Handle window lifecycle (present/hide)

2. **Canvas Commands**
   - `canvas.present` - Open window with URL
   - `canvas.hide` - Close window
   - `canvas.navigate` - Change URL
   - `canvas.eval` - Execute JavaScript
   - `canvas.snapshot` - Screenshot (PNG/JPG)

3. **A2UI Support**
   - Implement `canvas.a2ui.push` for JSONL payloads
   - Implement `canvas.a2ui.reset`
   - Support v0.8 A2UI spec

4. **Platform Adaptation**
   - Linux: WebKitGTK or similar
   - Windows: WebView2
   - Android: Native WebView

**Deliverable:** Agent can display web content and receive canvas snapshots

---

### Phase 3: Screen Capture & Media (Advanced Capabilities)

**Goal:** Screen recording and media capture

**Tasks:**
1. **Screen Recording (Linux)**
   - FFmpeg integration for X11/Wayland capture
   - `screen.record` with duration/fps parameters
   - Return MP4 as base64

2. **Screen Recording (Windows)**
   - DXGI Desktop Duplication
   - Encode to MP4

3. **Camera Support (Android)**
   - Camera2 API for `camera.snap`
   - Video recording for `camera.clip`
   - Permission handling

4. **Location (Android)**
   - Fused Location Provider
   - `location.get` with accuracy settings

**Deliverable:** Rich media capture capabilities on supported platforms

---

### Phase 4: Platform-Specific Polish

**Goal:** Native platform integration

**Tasks:**
1. **System Notifications**
   - Linux: notify-send/D-Bus
   - Windows: Toast notifications
   - Android: NotificationManager

2. **Service/Daemon Mode**
   - systemd service file generation (Linux)
   - Windows Service wrapper
   - Background operation without GUI

3. **SMS (Android)**
   - `sms.send` implementation
   - Permission management

4. **Auto-Start**
   - Register for system boot (optional)
   - Reconnect on network change

**Deliverable:** Production-ready node host on all platforms

---

## Architecture Design

### Module Structure

```
src/
├── main_cli.zig           # CLI entry point (existing)
├── main_node.zig          # Node mode entry point
├── main_native.zig        # Native GUI (existing)
├── node/
│   ├── node_context.zig   # Node state management
│   ├── command_router.zig # Route invoke to handlers
│   ├── capabilities.zig   # Capability advertisement
│   └── config.zig         # Node config (node.json)
├── commands/
│   ├── system.zig         # system.run, system.which
│   ├── canvas.zig         # canvas.* commands
│   ├── screen.zig         # screen.record
│   ├── camera.zig         # camera.* (Android)
│   └── location.zig       # location.get (Android)
├── platform/
│   ├── native.zig         # Linux/Windows implementations
│   ├── android.zig        # Android-specific
│   └── wasm.zig           # Web platform stubs
└── protocol/
    ├── nodes.zig          # Node protocol types (existing)
    └── gateway.zig        # Gateway protocol (existing)
```

### Node State Machine

```
Disconnected
    ↓
Connecting (WS handshake)
    ↓
Authenticating (device pairing)
    ↓
Connected (idle, waiting for invoke)
    ↓
Executing (processing node.invoke)
    ↓
Connected (return to idle)
```

### Command Execution Flow

```
1. Receive node.invoke request
2. Validate command is in advertised list
3. Check exec approvals (for system.run)
4. Spawn process/thread for execution
5. Stream output (for long-running)
6. Return result or error
7. Clean up
```

## Configuration

### Node Config File (`~/.openclaw/node.json`)

```json
{
  "nodeId": "zsc-node-abc123",
  "deviceToken": "tkn_...",
  "displayName": "Ziggy Node (Linux)",
  "gatewayHost": "192.168.1.100",
  "gatewayPort": 18789,
  "tls": false,
  "capabilities": {
    "system": {
      "enabled": true,
      "allowlistPath": "~/.openclaw/exec-approvals.json"
    },
    "canvas": {
      "enabled": true,
      "defaultWidth": 1024,
      "defaultHeight": 768
    },
    "screen": {
      "enabled": false
    }
  },
  "permissions": {
    "screen.record": true
  }
}
```

### CLI Arguments (Node Mode)

```bash
# Run as node (foreground)
ziggystarclaw-cli --node-mode --host <gateway> --port 18789

# Run as node with specific capabilities
ziggystarclaw-cli --node-mode --caps system,canvas --display-name "Build Server"

# Install as service
ziggystarclaw-cli --node-mode --install-service

# Check node status
ziggystarclaw-cli --node-status
```

## Security Considerations

### 1. Exec Approvals (Mandatory)

- All `system.run` commands MUST be allowlisted
- Default deny - nothing runs without explicit approval
- Approvals stored locally, editable only by local user
- Gateway can request approval updates via `system.execApprovals.set`

### 2. Sandboxing

- Consider seccomp-bpf (Linux) for syscall filtering
- Windows: Job objects for process isolation
- Android: Already sandboxed by OS

### 3. Network Security

- Device identity with keypair authentication
- TLS for Gateway connection
- Certificate pinning support

### 4. Permission Model

| Capability | User Consent | OS Permission | Gateway Allow |
|------------|--------------|---------------|---------------|
| `system.run` | Config file | - | Device pairing |
| `canvas.*` | Runtime | - | Device pairing |
| `camera.*` | Settings | CAMERA | Device pairing |
| `screen.record` | Runtime | SCREEN_CAPTURE | Device pairing |
| `location.get` | Settings | LOCATION | Device pairing |

## Testing Strategy

### Unit Tests
- Command routing
- Exec approval parsing
- JSON protocol serialization

### Integration Tests
- Node handshake with mock Gateway
- Command execution with test scripts
- Canvas lifecycle (open/navigate/close)

### Platform Tests
- Linux: Ubuntu, Debian, Fedora
- Windows: Windows 10, 11
- Android: API 28+ (Android 9+)

## Success Criteria

1. **Phase 1 Complete:**
   - [ ] Can connect as node role
   - [ ] Responds to `system.run` with proper approval checks
   - [ ] Can execute simple shell commands
   - [ ] Handles errors correctly

2. **Phase 2 Complete:**
   - [ ] Canvas window opens and displays URL
   - [ ] Can execute JavaScript in canvas
   - [ ] Can take canvas snapshots
   - [ ] A2UI push works

3. **Phase 3 Complete:**
   - [ ] Screen recording returns valid MP4
   - [ ] Camera capture works (Android)
   - [ ] Location retrieval works (Android)

4. **Phase 4 Complete:**
   - [ ] Runs as background service
   - [ ] Auto-reconnects on network failure
   - [ ] Production-ready error handling

## Resources

### OpenClaw References
- [Gateway Protocol](https://docs.openclaw.ai/gateway/protocol)
- [Nodes Overview](https://docs.openclaw.ai/nodes)
- [Camera Capture](https://docs.openclaw.ai/nodes/camera)
- [Node Host CLI](https://docs.openclaw.ai/cli/node)

### Implementation References
- OpenClaw headless node host (TypeScript) - `/src/node/host/`
- OpenClaw protocol schema - `/src/gateway/protocol/schema.ts`
- ZiggyStarClaw event handler - `src/client/event_handler.zig`

---

**Document Version:** 1.0  
**Created:** 2026-01-31  
**Status:** Draft - Ready for implementation planning
