#!/bin/bash
# Run all Hurl tests for lua-arangodb

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HURL_DIR="$SCRIPT_DIR/hurl"

echo "=========================================="
echo "  lua-arangodb Hurl Test Suite"
echo "=========================================="
echo ""

# Check if hurl is installed
if ! command -v hurl &> /dev/null; then
    echo "Error: hurl is not installed"
    echo "Install with: brew install hurl"
    exit 1
fi

# Check if services are running
echo "Checking services..."
if ! curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "Error: OpenResty is not running on localhost:8080"
    echo "Start with: podman-compose up -d"
    exit 1
fi
echo "Services are running."
echo ""

# Count tests
TOTAL_FILES=$(ls -1 "$HURL_DIR"/*.hurl 2>/dev/null | wc -l | tr -d ' ')
echo "Found $TOTAL_FILES test files"
echo ""

# Run tests
PASSED=0
FAILED=0

for test_file in "$HURL_DIR"/*.hurl; do
    test_name=$(basename "$test_file" .hurl)
    echo -n "Running $test_name... "

    if hurl --test "$test_file" > /dev/null 2>&1; then
        echo "PASSED"
        ((PASSED++))
    else
        echo "FAILED"
        ((FAILED++))
        # Show details for failed test
        echo "  Details:"
        hurl --test "$test_file" 2>&1 | sed 's/^/    /'
    fi
done

echo ""
echo "=========================================="
echo "  Results: $PASSED passed, $FAILED failed"
echo "=========================================="

if [ $FAILED -gt 0 ]; then
    exit 1
fi

exit 0
