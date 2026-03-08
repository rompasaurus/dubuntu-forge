#!/usr/bin/env bash
#
# Setup Xbox Wireless Controller via USB Dongle on Ubuntu
#
# Installs the xone driver for the Xbox Wireless Adapter (045e:02fe)
# which is not supported by the built-in xpad kernel driver.
#
# Run with: bash scripts/setup-xbox-controller.sh
#
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
info() { echo -e "${CYAN}[*]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[x]${NC} $*"; }

echo -e "${CYAN}"
echo "  ┌──────────────────────────────────────────┐"
echo "  │   Xbox Wireless Controller Setup          │"
echo "  │   xone driver for USB Wireless Adapter    │"
echo "  └──────────────────────────────────────────┘"
echo -e "${NC}"

# ─── Verify Xbox Wireless Adapter is present ────────────────────────────────

if ! lsusb | grep -qi "045e.*02fe\|Xbox Wireless Adapter"; then
    err "Xbox Wireless Adapter not detected."
    err "Make sure the USB dongle is plugged in."
    exit 1
fi
log "Xbox Wireless Adapter detected."

# ─── Install dependencies ────────────────────────────────────────────────────

info "Installing build dependencies..."
sudo apt update -qq
sudo apt install -y dkms cabextract linux-headers-"$(uname -r)"
log "Dependencies installed."

# ─── Remove conflicting xpad driver if loaded ────────────────────────────────

if lsmod | grep -q "^xpad"; then
    info "Unloading conflicting xpad driver..."
    sudo rmmod xpad 2>/dev/null || true
fi

# Blacklist xpad so it doesn't interfere with xone
BLACKLIST_FILE="/etc/modprobe.d/blacklist-xpad.conf"
if [ ! -f "$BLACKLIST_FILE" ]; then
    sudo tee "$BLACKLIST_FILE" > /dev/null <<'EOF'
# Blacklist xpad to prevent conflicts with xone driver
blacklist xpad
EOF
    log "Blacklisted xpad driver."
else
    info "xpad already blacklisted."
fi

# ─── Install xone driver ─────────────────────────────────────────────────────

XONE_DIR="/tmp/xone"

if dkms status 2>/dev/null | grep -qi "xone"; then
    info "xone driver already installed via DKMS."
    info "Reinstalling to ensure latest version..."
    # Get installed version and remove it
    XONE_VER=$(dkms status 2>/dev/null | grep -i "xone" | head -1 | awk -F'[,/]' '{print $2}' | xargs)
    if [ -n "$XONE_VER" ]; then
        sudo dkms remove "xone/$XONE_VER" --all 2>/dev/null || true
    fi
fi

# Clean up any previous clone
rm -rf "$XONE_DIR"

info "Cloning xone driver..."
git clone https://github.com/medusalix/xone.git "$XONE_DIR"

info "Installing xone driver..."
cd "$XONE_DIR"
sudo ./install.sh
log "xone driver installed."

# ─── Download dongle firmware ─────────────────────────────────────────────────
#
# The Xbox Wireless Adapter requires proprietary firmware to operate.
# xone-get-firmware.sh extracts it from the official Windows driver.
#

info "Downloading wireless adapter firmware..."
if command -v xone-get-firmware.sh &>/dev/null; then
    sudo xone-get-firmware.sh
    log "Firmware installed."
elif [ -f /usr/local/bin/xone-get-firmware.sh ]; then
    sudo /usr/local/bin/xone-get-firmware.sh
    log "Firmware installed."
else
    warn "xone-get-firmware.sh not found in PATH."
    warn "Try running: sudo /usr/lib/modules/\$(uname -r)/updates/dkms/xone-get-firmware.sh"
fi

# ─── Clean up ────────────────────────────────────────────────────────────────

rm -rf "$XONE_DIR"
log "Cleaned up build files."

# ─── Verify ──────────────────────────────────────────────────────────────────

echo ""
info "Verification:"

# Dongle
if lsusb | grep -qi "045e.*02fe\|Xbox Wireless Adapter"; then
    echo -e "  ${GREEN}✓${NC} Xbox Wireless Adapter detected"
else
    echo -e "  ${YELLOW}✗${NC} Adapter not detected"
fi

# DKMS
if dkms status 2>/dev/null | grep -qi "xone"; then
    echo -e "  ${GREEN}✓${NC} xone driver installed (DKMS)"
else
    echo -e "  ${YELLOW}✗${NC} xone driver not found in DKMS"
fi

# Module loaded
if lsmod | grep -q "xone"; then
    echo -e "  ${GREEN}✓${NC} xone kernel module loaded"
else
    echo -e "  ${YELLOW}✗${NC} xone module not loaded (will load after reboot)"
fi

# Firmware
if [ -d /lib/firmware/xone ] || [ -f /lib/firmware/xone/FW_ACC_00U.bin ]; then
    echo -e "  ${GREEN}✓${NC} Wireless adapter firmware installed"
else
    echo -e "  ${YELLOW}✗${NC} Firmware not found — controller may not connect wirelessly"
fi

echo ""
warn "A REBOOT is recommended for the driver to fully load."
info "After reboot:"
info "  1. Press the pairing button on the USB dongle (small button)"
info "  2. Press the pairing button on your Xbox controller (top, near bumpers)"
info "  3. They should connect within a few seconds"
info "  4. Verify with: cat /proc/bus/input/devices | grep -A 5 Xbox"
echo ""
log "Done!"
