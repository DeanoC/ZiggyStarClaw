#!/usr/bin/env python3
"""
Unit tests for ZiggyStarClaw node - no gateway required

These tests verify the CLI binary works without needing
an OpenClaw gateway connection.
"""

import subprocess
import pytest
from pathlib import Path

ZIGGY_CLI = Path.home() / "ZiggyStarClaw" / "zig-out" / "bin" / "ziggystarclaw-cli"


class TestCliHelp:
    """Test CLI help and basic functionality"""
    
    @pytest.fixture
    def cli(self):
        if not ZIGGY_CLI.exists():
            pytest.skip(f"CLI not found: {ZIGGY_CLI}")
        return ZIGGY_CLI
    
    def test_cli_exists(self, cli):
        """CLI binary exists"""
        assert cli.exists()
        assert cli.stat().st_size > 1000000  # At least 1MB
    
    def test_cli_help(self, cli):
        """CLI shows help"""
        result = subprocess.run(
            [str(cli), "--help"],
            capture_output=True,
            text=True
        )
        assert result.returncode == 0
        assert "ZiggyStarClaw CLI" in result.stdout
    
    def test_node_mode_help(self, cli):
        """Node mode help is available"""
        result = subprocess.run(
            [str(cli), "--node-mode-help"],
            capture_output=True,
            text=True
        )
        assert result.returncode == 0
        assert "ZiggyStarClaw Node Mode" in result.stdout
        assert "--node-mode" in result.stdout


class TestNodeConfig:
    """Test node configuration"""
    
    @pytest.fixture
    def cli(self):
        if not ZIGGY_CLI.exists():
            pytest.skip(f"CLI not found: {ZIGGY_CLI}")
        return ZIGGY_CLI
    
    def test_node_mode_without_gateway(self, cli):
        """Node mode fails gracefully without gateway"""
        result = subprocess.run(
            [str(cli), "--node-mode", "--host", "127.0.0.1", "--port", "99999"],
            capture_output=True,
            text=True,
            timeout=10
        )
        # Should fail to connect but not crash
        assert result.returncode != 0 or "error" in result.stderr.lower()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
