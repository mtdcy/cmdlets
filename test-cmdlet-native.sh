#!/bin/bash
# Native test for cmdlet.bat logic (bash implementation)
# This tests the fetch logic without Windows/Wine

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$SCRIPT_DIR/test-native"
PREBUILTS="$TEST_DIR/prebuilts"

# Test configuration
export REPO="${REPO:-https://pub.mtdcy.top/cmdlets/latest}"
export ARCH="${ARCH:-x86_64-apple-darwin}"  # Use host arch for native test

echo "=== Native Test for cmdlet.bat Logic ==="
echo "Repository: $REPO"
echo "Architecture: $ARCH"
echo ""

# Cleanup
rm -rf "$TEST_DIR"
mkdir -p "$PREBUILTS"

# Test 1: Check repository connectivity
echo "=== Test 1: Repository Connectivity ==="
if curl -fsIL --connect-timeout 5 "$REPO" -o /dev/null 2>&1; then
    echo "✅ Repository accessible"
else
    echo "❌ Repository not accessible: $REPO"
    echo "   Skipping further tests"
    exit 0
fi

# Test 2: Fetch curl package
echo ""
echo "=== Test 2: Fetch curl Package ==="
TEST_PKG="curl"
PKGFILE="$TEST_PKG.tar.gz"
PKGURL="$REPO/$ARCH/$PKGFILE"

echo "Downloading: $PKGURL"
mkdir -p "$TEST_DIR/temp"

if curl -fsL -o "$TEST_DIR/temp/$PKGFILE" "$PKGURL" 2>&1; then
    echo "✅ Download successful"
    echo "   Size: $(ls -lh "$TEST_DIR/temp/$PKGFILE" | awk '{print $5}')"
    
    echo ""
    echo "Extracting to: $PREBUILTS"
    if tar -xzf "$TEST_DIR/temp/$PKGFILE" -C "$PREBUILTS" 2>&1; then
        echo "✅ Extraction successful"
        
        echo ""
        echo "=== Results ==="
        echo "Prebuilts directory:"
        ls -la "$PREBUILTS/" | head -10
        
        echo ""
        echo "Bin directory:"
        if [ -d "$PREBUILTS/bin" ]; then
            ls -la "$PREBUILTS/bin/" | head -10
        else
            echo "(no bin directory)"
        fi
        
        echo ""
        echo "✅ Test PASSED"
    else
        echo "❌ Extraction failed"
        exit 1
    fi
else
    echo "❌ Download failed"
    echo "   Package may not exist for this architecture"
    echo ""
    echo "Available architectures:"
    curl -fsL "$REPO/" 2>&1 | grep -o 'href="[a-z0-9_-]*"' | head -10 || echo "(unable to list)"
fi

# Cleanup
echo ""
echo "Cleaning up..."
rm -rf "$TEST_DIR"
echo "Done!"
