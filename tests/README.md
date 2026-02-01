# ZiggyStarClaw Node Tests

Automated testing for ZiggyStarClaw node mode.

## Quick Start

```bash
# Run all tests
./scripts/run-tests.sh

# Run specific tests
./scripts/run-tests.sh test_system

# Run unit tests only (no gateway needed)
python3 -m pytest tests/test_cli_unit.py -v

# Run integration tests (requires gateway)
python3 -m pytest tests/test_node.py -v
```

## Prerequisites

### Unit Tests
- Python 3.11+
- pytest
- ZiggyStarClaw CLI built (`zig build`)

### Integration Tests
- OpenClaw gateway running
- Xvfb for canvas tests
- Chrome/Chromium for canvas backend

```bash
# Install Python deps
pip3 install pytest pytest-asyncio requests websocket-client

# Start Xvfb
~/clawd/scripts/xvfb-service.sh start

# Ensure CLI is built
cd ~/ZiggyStarClaw && zig build
```

## Test Structure

```
tests/
├── conftest.py           # pytest configuration
├── test_cli_unit.py      # Unit tests (no gateway)
└── test_node.py          # Integration tests (needs gateway)
```

### Unit Tests (`test_cli_unit.py`)
- CLI binary validation
- Help text verification
- Basic argument parsing
- No external dependencies

### Integration Tests (`test_node.py`)
- Node lifecycle (start/connect/stop)
- System commands (run/which)
- Process management (spawn/poll/list)
- Canvas commands (present/navigate)
- Requires running OpenClaw gateway

## Test Configuration

Environment variables:
- `GATEWAY_URL` - WebSocket URL for gateway (default: ws://127.0.0.1:18789)
- `DISPLAY` - X11 display for canvas tests (default: :99)

## CI/CD

Tests run automatically on:
- Pull requests to `main`
- Pushes to `main` or `develop`

See `.github/workflows/node-tests.yml`

## Writing Tests

### Basic Test
```python
def test_example(gateway):
    response = gateway.invoke_node(
        "node-id",
        "system.run",
        {"command": ["echo", "hello"]}
    )
    assert response.get("ok")
```

### Canvas Test
```python
def test_canvas(canvas_node, gateway):
    response = gateway.invoke_node(
        canvas_node.node_id,
        "canvas.present",
        {}
    )
    assert response["payload"]["status"] == "visible"
```

## Troubleshooting

### Tests skipped
- Gateway not running → Start OpenClaw gateway
- Xvfb not running → `~/clawd/scripts/xvfb-service.sh start`
- CLI not built → `zig build`

### Connection refused
Ensure gateway is accessible:
```bash
curl http://127.0.0.1:18789/health
```
