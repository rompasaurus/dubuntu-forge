#!/bin/bash
# ==============================================================================
# DookTV Boot Splash Setup
# Installs a custom Plymouth theme with the DookTV splash screen
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_SRC="$SCRIPT_DIR/plymouth-theme"
THEME_DEST="/usr/share/plymouth/themes/dooktv"

echo "============================================"
echo "  DookTV Boot Splash Installer"
echo "  PREPARE YOUR ANUS"
echo "============================================"
echo ""

# Check for root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (sudo)."
    exit 1
fi

# Install dependencies
echo "[1/5] Installing dependencies..."
apt-get install -y librsvg2-bin plymouth-theme-spinner > /dev/null 2>&1
echo "  Done."

# Convert SVG to PNG
echo "[2/5] Converting splash image..."
rsvg-convert -w 1920 -h 1080 "$THEME_SRC/dooktv-splash.svg" -o "$THEME_SRC/splash.png"
echo "  Done."

# Install theme files
echo "[3/5] Installing Plymouth theme..."
mkdir -p "$THEME_DEST"
cp "$THEME_SRC/splash.png" "$THEME_DEST/splash.png"
cp "$THEME_SRC/dooktv.plymouth" "$THEME_DEST/dooktv.plymouth"
cp "$THEME_SRC/dooktv.script" "$THEME_DEST/dooktv.script"

# Create alternatives entry and set as default
echo "[4/5] Setting DookTV as default boot theme..."
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth \
    "$THEME_DEST/dooktv.plymouth" 200
update-alternatives --set default.plymouth "$THEME_DEST/dooktv.plymouth"

# Update initramfs
echo "[5/5] Updating initramfs (this may take a moment)..."
update-initramfs -u
echo "  Done."

echo ""
echo "============================================"
echo "  DookTV boot splash installed!"
echo "  Reboot to see it in action."
echo "============================================"
