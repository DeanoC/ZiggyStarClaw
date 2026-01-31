# Connecting to a server (Settings dialog)

ZiggyStarClaw talks to an OpenClaw server over WebSocket. The Settings dialog is the canonical place to configure it.

## Fields you must set
- **Server URL**: must be a WebSocket URL (`ws://` or `wss://`).
- **Token**: required if your server expects auth.

## Step-by-step (UI)
1) Open **Settings**.
2) Paste the **Server URL**.
3) Paste your **Token** (if required by the server).
4) Leave **Insecure TLS** off unless you know you need it.
5) Click **Apply** (or **Save**) and verify the connection state.

## What a valid URL looks like
Use one of these patterns (your host/port/path may differ):
- `wss://example.com:443/ws`
- `wss://example.com/ws`
- `ws://10.0.0.5:8787`

## Pitfalls to avoid
- **Copying a web page instead of a WebSocket URL.**  
  A link from GitHub/HTML is often an HTML page, not a real socket endpoint. Your URL must start with `ws://` or `wss://` and point to a server WebSocket path.
- **Missing the path.**  
  Many servers expect a path like `/ws`. If you only enter `wss://example.com`, the handshake can fail.
- **Using `https://` instead of `wss://`.**  
  `https://` is for web pages. WebSocket secure is `wss://`.
- **TLS certificate mismatch.**  
  If the server uses a self-signed certificate, you’ll need **Insecure TLS**. Only do this on trusted networks.
- **Token formatting.**  
  Tokens are often long strings; avoid accidental whitespace at the start/end.

## TLS / certificates
- For `wss://` connections, TLS verification is on by default.
- **Insecure TLS** skips certificate checks. Use only for testing or trusted private networks.

## If it doesn’t connect
1) Verify the URL begins with `ws://` or `wss://`.
2) Confirm the **path** is correct (ask your server operator).
3) Verify your token is valid and not expired.
4) Try **Insecure TLS** only if you trust the server.
5) Check [Troubleshooting](troubleshooting.md) for common errors.
