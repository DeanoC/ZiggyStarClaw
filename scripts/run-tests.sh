#!/bin/bash
# Run ZiggyStarClaw node tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== ZiggyStarClaw Node Test Runner ==="
echo ""

# Check CLI exists
if [ ! -f "$PROJECT_DIR/zig-out/bin/ziggystarclaw-cli" ]; then
    echo -e "${RED}Error: CLI not found. Build first:${NC}"
    echo "  cd $PROJECT_DIR && zig build"
    exit 1
fi

echo -e "${GREEN}✓ CLI found${NC}"

# Check Xvfb
if [ -n "$DISPLAY" ] || pgrep -f "Xvfb" > /dev/null; then
    echo -e "${GREEN}✓ X11 available (DISPLAY=$DISPLAY)${NC}"
else
    echo -e "${YELLOW}⚠ X11 not available. Canvas tests will be skipped.${NC}"
    echo "  Start Xvfb: ~/clawd/scripts/xvfb-service.sh start"
fi

# Check gateway
echo -n "Checking gateway... "
if python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:18789/health', timeout=2)" 2>/dev/null; then
    echo -e "${GREEN}✓ Gateway available${NC}"
else
    echo -e "${YELLOW}⚠ Gateway not detected. Some tests may be skipped.${NC}"
fi

echo ""

# Run tests
cd "$PROJECT_DIR"

# Parse arguments
TEST_ARGS="-v"
if [ $# -eq 0 ]; then
    # Run all tests
    echo "Running all tests..."
    python3 -m pytest tests/test_node.py $TEST_ARGS
else
    # Run specific tests
    echo "Running tests matching: $@"
    python3 -m pytest tests/test_node.py $TEST_ARGS -k "$@"
fi
