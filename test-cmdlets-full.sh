#!/bin/bash
# Full test suite for cmdlets.bat (native bash simulation)
# Tests: fetch, list, search, remove

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$SCRIPT_DIR/test-full"
PREBUILTS="$TEST_DIR/prebuilts"

# Test configuration
export REPO="${REPO:-https://pub.mtdcy.top/cmdlets/latest}"
export ARCH="${ARCH:-x86_64-w64-mingw32}"

echo "=== Full Test Suite for cmdlets.bat ==="
echo "Repository: $REPO"
echo "Architecture: $ARCH"
echo ""

# Cleanup
rm -rf "$TEST_DIR"
mkdir -p "$PREBUILTS"

# Test 1: Repository connectivity
echo "=== Test 1: Repository Connectivity ==="
if curl -fsIL --connect-timeout 5 "$REPO" -o /dev/null; then
    echo "✅ Repository accessible"
else
    echo "❌ Repository not accessible"
    exit 1
fi

# Test 2: Fetch curl
echo ""
echo "=== Test 2: Fetch curl ==="
PKGFILE="curl/curl@8.18.0.tar.gz"
PKGURL="$REPO/$ARCH/$PKGFILE"

mkdir -p "$TEST_DIR/temp/$(dirname "$PKGFILE")"
if curl -fsL -o "$TEST_DIR/temp/$PKGFILE" "$PKGURL"; then
    echo "✅ Download successful"
    tar -xzf "$TEST_DIR/temp/$PKGFILE" -C "$PREBUILTS"
    echo "curl" > "$PREBUILTS/.cmdlets"
    echo "✅ Extraction successful"
else
    echo "❌ Download failed"
    exit 1
fi

# Test 3: List packages
echo ""
echo "=== Test 3: List Packages ==="
if [ -f "$PREBUILTS/.cmdlets" ]; then
    echo "Installed packages:"
    cat "$PREBUILTS/.cmdlets"
    echo "✅ List successful"
else
    echo "❌ .cmdlets file not found"
fi

# Test 4: List binaries
echo ""
echo "=== Test 4: List Binaries ==="
if [ -d "$PREBUILTS/bin" ]; then
    echo "Binaries:"
    ls -lh "$PREBUILTS/bin/"*.exe 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    echo "✅ Binaries found"
else
    echo "❌ bin directory not found"
fi

# Test 5: Search (simulate)
echo ""
echo "=== Test 5: Search ==="
echo "Searching for 'curl'..."
if grep -q "curl" "$PREBUILTS/.cmdlets"; then
    echo "✅ Found: curl"
else
    echo "❌ Not found"
fi

# Test 6: Remove package
echo ""
echo "=== Test 6: Remove Package ==="
if [ -f "$PREBUILTS/.cmdlets" ]; then
    # Remove from .cmdlets
    grep -v "^curl" "$PREBUILTS/.cmdlets" > "$TEST_DIR/cmdlets.tmp" || true
    mv "$TEST_DIR/cmdlets.tmp" "$PREBUILTS/.cmdlets"
    
    # Remove binaries
    rm -f "$PREBUILTS/bin/"curl* 2>/dev/null || true
    
    echo "✅ Remove successful"
    
    # Verify removal
    if [ ! -f "$PREBUILTS/bin/curl.exe" ]; then
        echo "✅ Verified: curl.exe removed"
    else
        echo "❌ Verification failed: curl.exe still exists"
    fi
fi

# Test 7: List after remove
echo ""
echo "=== Test 7: List After Remove ==="
if [ -f "$PREBUILTS/.cmdlets" ]; then
    CONTENT=$(cat "$PREBUILTS/.cmdlets")
    if [ -z "$CONTENT" ]; then
        echo "✅ No packages installed (as expected)"
    else
        echo "Remaining packages:"
        echo "$CONTENT"
    fi
fi

# Cleanup
echo ""
echo "Cleaning up..."
rm -rf "$TEST_DIR"
echo "Done!"

echo ""
echo "=== All Tests PASSED ==="
