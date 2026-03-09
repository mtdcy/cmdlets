#!/bin/bash
# =============================================================================
#  bootstrap.windows.sh - Prepare Windows tools using cmdlets.sh
#  
#  Copyright (c) 2026, mtdcy.chen@gmail.com
#  Licensed under BSD 2-Clause License
#
#  Usage: ./bootstrap.windows.sh
#    Downloads Windows (mingw64) tools for cmdlets.bat
# =============================================================================

set -eo pipefail

# Configuration
export CMDLETS_ARCH=x86_64-w64-mingw32
export CMDLETS_PREBUILTS="${CMDLETS_PREBUILTS:-prebuilts}"

# Default packages (name:rename)
DEFAULT_PACKAGES=(
    "curl"
    "bsdtar:tar"
)

# =============================================================================
# Main
# =============================================================================

echo "============================================================================="
echo "  cmdlets.bat Bootstrap for Windows (mingw64)"
echo "============================================================================="
echo ""
echo "Architecture: $CMDLETS_ARCH"
echo "Prebuilts:    $CMDLETS_PREBUILTS"
echo ""

# Check if cmdlets.sh exists
if [ ! -f "cmdlets.sh" ]; then
    echo "ERROR: cmdlets.sh not found in current directory"
    exit 1
fi

# Create prebuilts directory
mkdir -p "$CMDLETS_PREBUILTS"

# Install packages
echo "Installing packages..."
echo ""

for pkg_entry in "${DEFAULT_PACKAGES[@]}"; do
    # Parse package name and optional rename
    PKG_NAME="${pkg_entry%%:*}"
    PKG_RENAME="${pkg_entry#*:}"
    
    # If no rename, use original name
    if [ "$PKG_RENAME" = "$pkg_entry" ]; then
        PKG_RENAME="$PKG_NAME"
    fi
    
    echo "Installing $PKG_NAME..."
    
    # Check if already installed
    if [ -f "$CMDLETS_PREBUILTS/.cmdlets" ] && grep -q "^$PKG_NAME" "$CMDLETS_PREBUILTS/.cmdlets" 2>/dev/null; then
        if [ "$PKG_RENAME" = "tar" ]; then
            if [ -f "$CMDLETS_PREBUILTS/bin/tar.exe" ] || [ -f "$CMDLETS_PREBUILTS/bin/bsdtar.exe" ]; then
                echo "  Already installed, skipping"
                continue
            fi
        else
            if [ -f "$CMDLETS_PREBUILTS/bin/${PKG_NAME}.exe" ]; then
                echo "  Already installed, skipping"
                continue
            fi
        fi
    fi
    
    # Fetch package using cmdlets.sh
    if bash cmdlets.sh fetch "$PKG_NAME" 2>&1; then
        # Rename if needed
        if [ "$PKG_RENAME" != "$PKG_NAME" ] && [ "$PKG_RENAME" = "tar" ]; then
            if [ -f "$CMDLETS_PREBUILTS/bin/bsdtar.exe" ] && [ ! -f "$CMDLETS_PREBUILTS/bin/tar.exe" ]; then
                cp "$CMDLETS_PREBUILTS/bin/bsdtar.exe" "$CMDLETS_PREBUILTS/bin/tar.exe"
                echo "  Created tar.exe from bsdtar.exe"
            fi
        fi
        echo "  Installed successfully"
    else
        echo "  WARNING: Failed to install $PKG_NAME"
    fi
    echo ""
done

# Summary
echo "============================================================================="
echo "  Bootstrap Summary"
echo "============================================================================="
echo ""

# Verify installation (based on DEFAULT_PACKAGES)
echo "Verifying installation..."

FAILED=0
for pkg_entry in "${DEFAULT_PACKAGES[@]}"; do
    PKG_NAME="${pkg_entry%%:*}"
    PKG_RENAME="${pkg_entry#*:}"
    
    if [ "$PKG_RENAME" = "$pkg_entry" ]; then
        PKG_RENAME="$PKG_NAME"
    fi
    
    # Check for the renamed binary or original
    if [ "$PKG_RENAME" = "tar" ]; then
        if [ -f "$CMDLETS_PREBUILTS/bin/tar.exe" ] || [ -f "$CMDLETS_PREBUILTS/bin/bsdtar.exe" ]; then
            echo "  OK: $PKG_RENAME.exe"
        else
            echo "  MISSING: $PKG_RENAME.exe"
            FAILED=1
        fi
    else
        if [ -f "$CMDLETS_PREBUILTS/bin/${PKG_NAME}.exe" ]; then
            echo "  OK: $PKG_NAME.exe"
        else
            echo "  MISSING: $PKG_NAME.exe"
            FAILED=1
        fi
    fi
done

echo ""

# Check installed packages
if [ -f "$CMDLETS_PREBUILTS/.cmdlets" ]; then
    echo "Installed packages:"
    cat "$CMDLETS_PREBUILTS/.cmdlets"
    echo ""
fi

echo "============================================================================="
echo "  Bootstrap completed"
echo "============================================================================="
echo ""
echo "You can now use cmdlets.bat in Windows environment:"
echo "  cmdlets.bat fetch <package>"
echo "  cmdlets.bat list"
echo "  cmdlets.bat search <pattern>"
echo ""

# Exit with error if verification failed
if [ $FAILED -ne 0 ]; then
    exit 1
fi
