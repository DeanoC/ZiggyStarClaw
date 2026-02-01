#!/usr/bin/env python3
"""
ZiggyStarClaw Node Test Framework

Integration tests for ZiggyStarClaw node mode.
Requires:
- OpenClaw gateway running (or mock)
- Xvfb for canvas tests
- ZiggyStarClaw CLI built

Usage:
    pytest tests/ -v
    pytest tests/test_node.py -v -k "test_system"
    pytest tests/ --gateway-url ws://localhost:18789
"""

import asyncio
import json
import os
import pytest
import subprocess
import tempfile
import time
import websocket
from pathlib import Path
from typing import Optional, Dict, Any

# =============================================================================
# Configuration
# =============================================================================

class TestConfig:
    """Test configuration"""
    GATEWAY_URL = os.environ.get("GATEWAY_URL", "ws://127.0.0.1:18789")
    ZIGGY_CLI = Path.home() / "ZiggyStarClaw" / "zig-out" / "bin" / "ziggystarclaw-cli"
    XVFB_DISPLAY = ":99"
    TEST_TIMEOUT = 30
    NODE_START_TIMEOUT = 5

# =============================================================================
# Fixtures
# =============================================================================

@pytest.fixture(scope="session")
def ziggy_cli() -> Path:
    """Ensure CLI binary exists"""
    cli = TestConfig.ZIGGY_CLI
    if not cli.exists():
        pytest.skip(f"CLI not found: {cli}")
    return cli

@pytest.fixture(scope="session")
def xvfb_running():
    """Ensure Xvfb is running for canvas tests"""
    display = TestConfig.XVFB_DISPLAY
    result = subprocess.run(
        ["pgrep", "-f", f"Xvfb {display}"],
        capture_output=True
    )
    if result.returncode != 0:
        pytest.skip(f"Xvfb not running on {display}. Run: ~/clawd/scripts/xvfb-service.sh start")
    os.environ["DISPLAY"] = display
    yield display

@pytest.fixture(scope="session")
def gateway_available():
    """Check if OpenClaw gateway is available"""
    url = TestConfig.GATEWAY_URL.replace("ws://", "http://")
    try:
        import urllib.request
        urllib.request.urlopen(f"{url}/health", timeout=2)
    except Exception as e:
        pytest.skip(f"Gateway not available at {url}: {e}")

@pytest.fixture
def temp_dir():
    """Provide temporary directory"""
    with tempfile.TemporaryDirectory() as tmp:
        yield Path(tmp)

# =============================================================================
# Node Process Fixture
# =============================================================================

class NodeProcess:
    """Manages a ZiggyStarClaw node process for testing"""
    
    def __init__(self, node_id: str, config: Dict[str, Any] = None):
        self.node_id = node_id
        self.config = config or {}
        self.process: Optional[subprocess.Popen] = None
        self.log_file: Optional[Path] = None
        self._log_content = []
        
    def start(self) -> bool:
        """Start the node process"""
        # Create temp log file
        self.log_file = Path(tempfile.mktemp(suffix=".log", prefix="zsc-node-"))
        
        # Build config file - pass all settings via config file
        config_path = self._write_config()
        
        # Note: node-mode arguments are passed after --node-mode flag
        # The main_cli passes args[1..] to parseNodeOptions
        cmd = [
            str(TestConfig.ZIGGY_CLI),
            "--node-mode",
            "--config", str(config_path),
            "--log-level", "debug",
        ]
        
        # Start process
        self.process = subprocess.Popen(
            cmd,
            stdout=open(self.log_file, "w"),
            stderr=subprocess.STDOUT,
        )
        
        # Wait for connection
        time.sleep(TestConfig.NODE_START_TIMEOUT)
        
        return self.is_running
    
    def stop(self):
        """Stop the node process"""
        if self.process:
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()
    
    @property
    def is_running(self) -> bool:
        """Check if process is running"""
        return self.process is not None and self.process.poll() is None
    
    def get_logs(self) -> str:
        """Get log content"""
        if self.log_file and self.log_file.exists():
            return self.log_file.read_text()
        return ""
    
    def _write_config(self) -> Path:
        """Write node config file"""
        config = {
            "node_id": self.node_id,
            "display_name": f"Test-{self.node_id}",
            "gateway_host": TestConfig.GATEWAY_URL.replace("ws://", "").rsplit(":", 1)[0],
            "gateway_port": 18789,
            "system_enabled": True,
            "canvas_enabled": self.config.get("canvas_enabled", False),
            "canvas_backend": self.config.get("canvas_backend", "none"),
            "exec_approvals_path": "~/.openclaw/exec-approvals.json",
        }
        
        config_path = Path(tempfile.mktemp(suffix=".json", prefix="zsc-config-"))
        config_path.write_text(json.dumps(config))
        return config_path


@pytest.fixture
def node_process(temp_dir):
    """Provide a started node process"""
    node_id = f"test-node-{int(time.time())}"
    node = NodeProcess(node_id)
    
    if not node.start():
        pytest.fail(f"Failed to start node: {node.get_logs()}")
    
    yield node
    
    node.stop()
    if node.log_file:
        # Print logs on failure
        print(f"\n=== Node Logs ({node.node_id}) ===")
        print(node.get_logs()[-2000:])  # Last 2000 chars


@pytest.fixture
def canvas_node(temp_dir, xvfb_running):
    """Provide a node with canvas enabled"""
    node_id = f"test-canvas-node-{int(time.time())}"
    node = NodeProcess(node_id, config={
        "canvas_enabled": True,
        "canvas_backend": "chrome",
    })
    
    if not node.start():
        pytest.fail(f"Failed to start canvas node: {node.get_logs()}")
    
    yield node
    
    node.stop()


# =============================================================================
# Gateway Client
# =============================================================================

class GatewayClient:
    """Client for interacting with OpenClaw gateway"""
    
    def __init__(self, url: str = None):
        self.url = url or TestConfig.GATEWAY_URL
        self.ws: Optional[websocket.WebSocket] = None
        
    def connect(self):
        """Connect to gateway"""
        self.ws = websocket.create_connection(self.url, timeout=10)
        
    def disconnect(self):
        """Disconnect from gateway"""
        if self.ws:
            self.ws.close()
            self.ws = None
    
    def invoke_node(self, node_id: str, command: str, params: Dict = None) -> Dict:
        """Invoke a node command"""
        if not self.ws:
            self.connect()
        
        request = {
            "type": "req",
            "id": f"test-{int(time.time())}",
            "method": "node.invoke",
            "params": {
                "nodeId": node_id,
                "command": command,
                "params": params or {},
            }
        }
        
        self.ws.send(json.dumps(request))
        response = self.ws.recv()
        return json.loads(response)
    
    def list_nodes(self) -> list:
        """List connected nodes"""
        if not self.ws:
            self.connect()
        
        request = {
            "type": "req",
            "id": f"test-{int(time.time())}",
            "method": "nodes.list",
            "params": {}
        }
        
        self.ws.send(json.dumps(request))
        response = self.ws.recv()
        data = json.loads(response)
        return data.get("payload", {}).get("nodes", [])


@pytest.fixture
def gateway():
    """Provide connected gateway client"""
    client = GatewayClient()
    try:
        client.connect()
        yield client
    finally:
        client.disconnect()


# =============================================================================
# Helper Functions
# =============================================================================

def wait_for_condition(condition_fn, timeout: float = 10, interval: float = 0.5):
    """Wait for a condition to be true"""
    start = time.time()
    while time.time() - start < timeout:
        if condition_fn():
            return True
        time.sleep(interval)
    return False


# =============================================================================
# Tests
# =============================================================================

class TestNodeLifecycle:
    """Test node connection and lifecycle"""
    
    def test_node_starts_and_connects(self, node_process, gateway):
        """Test that node starts and appears in gateway"""
        # Wait for node to register
        time.sleep(2)
        
        # List nodes and find ours
        nodes = gateway.list_nodes()
        node_ids = [n.get("id") for n in nodes]
        
        assert node_process.node_id in node_ids, \
            f"Node {node_process.node_id} not found in {node_ids}"
    
    def test_node_process_running(self, node_process):
        """Test that node process stays running"""
        assert node_process.is_running, "Node process died"
        time.sleep(2)
        assert node_process.is_running, "Node process died after 2s"


class TestSystemCommands:
    """Test system.* commands"""
    
    def test_system_run_echo(self, node_process, gateway):
        """Test system.run with echo command"""
        time.sleep(2)  # Wait for registration
        
        response = gateway.invoke_node(
            node_process.node_id,
            "system.run",
            {"command": ["echo", "hello world"]}
        )
        
        assert response.get("ok"), f"Command failed: {response}"
        payload = response.get("payload", {})
        assert "hello world" in payload.get("stdout", "")
    
    def test_system_run_with_cwd(self, node_process, gateway, temp_dir):
        """Test system.run with working directory"""
        time.sleep(2)
        
        test_file = temp_dir / "test.txt"
        test_file.write_text("test content")
        
        response = gateway.invoke_node(
            node_process.node_id,
            "system.run",
            {
                "command": ["cat", "test.txt"],
                "cwd": str(temp_dir)
            }
        )
        
        assert response.get("ok"), f"Command failed: {response}"
        payload = response.get("payload", {})
        assert "test content" in payload.get("stdout", "")
    
    def test_system_which(self, node_process, gateway):
        """Test system.which command"""
        time.sleep(2)
        
        response = gateway.invoke_node(
            node_process.node_id,
            "system.which",
            {"name": "ls"}
        )
        
        assert response.get("ok"), f"Command failed: {response}"
        payload = response.get("payload", {})
        assert "path" in payload


class TestProcessManagement:
    """Test process.* commands"""
    
    def test_process_spawn(self, node_process, gateway):
        """Test process.spawn command"""
        time.sleep(2)
        
        response = gateway.invoke_node(
            node_process.node_id,
            "process.spawn",
            {"command": ["sleep", "10"]}
        )
        
        assert response.get("ok"), f"Command failed: {response}"
        payload = response.get("payload", {})
        assert "processId" in payload
        
        return payload["processId"]
    
    def test_process_poll(self, node_process, gateway):
        """Test process.poll command"""
        time.sleep(2)
        
        # Spawn a process
        spawn_resp = gateway.invoke_node(
            node_process.node_id,
            "process.spawn",
            {"command": ["sleep", "2"]}
        )
        proc_id = spawn_resp["payload"]["processId"]
        
        # Poll it
        time.sleep(0.5)
        poll_resp = gateway.invoke_node(
            node_process.node_id,
            "process.poll",
            {"processId": proc_id}
        )
        
        assert poll_resp.get("ok"), f"Poll failed: {poll_resp}"
        payload = poll_resp.get("payload", {})
        assert payload.get("state") == "running"
    
    def test_process_list(self, node_process, gateway):
        """Test process.list command"""
        time.sleep(2)
        
        response = gateway.invoke_node(
            node_process.node_id,
            "process.list",
            {}
        )
        
        assert response.get("ok"), f"Command failed: {response}"
        payload = response.get("payload", {})
        assert isinstance(payload, list)


class TestCanvasCommands:
    """Test canvas.* commands (requires Xvfb)"""
    
    def test_canvas_present(self, canvas_node, gateway):
        """Test canvas.present command"""
        time.sleep(3)  # Wait for canvas init
        
        response = gateway.invoke_node(
            canvas_node.node_id,
            "canvas.present",
            {}
        )
        
        # Canvas might fail if Chrome not available
        if not response.get("ok"):
            pytest.skip(f"Canvas not available: {response.get('error', {})}")
        
        payload = response.get("payload", {})
        assert payload.get("status") == "visible"
    
    def test_canvas_navigate(self, canvas_node, gateway):
        """Test canvas.navigate command"""
        time.sleep(3)
        
        # First present
        gateway.invoke_node(canvas_node.node_id, "canvas.present", {})
        time.sleep(1)
        
        response = gateway.invoke_node(
            canvas_node.node_id,
            "canvas.navigate",
            {"url": "about:blank"}
        )
        
        if not response.get("ok"):
            pytest.skip(f"Canvas navigation not available")
        
        payload = response.get("payload", {})
        assert payload.get("status") == "navigated"


# =============================================================================
# Main
# =============================================================================

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
