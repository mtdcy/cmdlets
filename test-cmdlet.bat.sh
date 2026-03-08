#!/bin/bash
# Test cmdlets.bat in Windows environment (mingw64 + wine)
# Usage: ./test-cmdlet.bat.sh [cmdlet]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CMDLET_BAT="$SCRIPT_DIR/cmdlets.bat"
TEST_DIR="$SCRIPT_DIR/test-win"

# Default test package
TEST_PKG="${1:-curl}"

echo "=== Testing cmdlets.bat ==="
echo "Package: $TEST_PKG"
echo "Image: lcr.io/mtdcy/builder:mingw64-latest"
echo ""

# Cleanup
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/prebuilts"

# Copy cmdlets.bat to test directory
cp "$CMDLET_BAT" "$TEST_DIR/"

# Run in Docker
docker run --rm --platform linux/amd64 \
    -v "$TEST_DIR:/workspace" \
    -w /workspace \
    lcr.io/mtdcy/builder:mingw64-latest \
    bash -c "
        set -e
        export WINEDEBUG=-all
        export HOME=/workspace
        
        echo '=== Environment ==='
        echo 'OS: Windows (via Wine)'
        echo 'ARCH: x86_64-windows-gnu'
        echo 'PWD: /workspace'
        echo ''
        
        # Fetch package using wine
        echo '=== Fetching $TEST_PKG ==='
        wine cmd.exe /c cmdlets.bat fetch $TEST_PKG
        
        echo ''
        echo '=== Results ==='
        echo 'Installed packages:'
        cat prebuilts/.cmdlets 2>/dev/null || echo '(none)'
        
        echo ''
        echo 'Prebuilts directory:'
        ls -la prebuilts/ 2>/dev/null || echo '(empty)'
        
        echo ''
        echo 'Bin directory:'
        ls -la prebuilts/bin/ 2>/dev/null || echo '(empty)'
        
        echo ''
        echo '=== Test Completed ==='
    "

# Cleanup
echo ""
echo "Cleaning up test directory..."
rm -rf "$TEST_DIR"
echo "Done!"
