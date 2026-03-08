#!/usr/bin/env bash
#
# Xbox Wireless Controller Reconnect
#
# Resets the Xbox USB Wireless Adapter and reloads the xone driver
# to trigger auto-reconnect without pressing the dongle pair button.
#
# After initial pairing, the controller should auto-connect when
# powered on. If it doesn't, run this script then turn on the controller.
#
# Run with: bash scripts/xbox-reconnect.sh
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
echo "  │   Xbox Controller Reconnect               │"
echo "  │   Reset dongle & reload xone driver        │"
echo "  └──────────────────────────────────────────┘"
echo -e "${NC}"

# ─── Find the Xbox Wireless Adapter ──────────────────────────────────────────

DONGLE=$(lsusb | grep -i "045e:02fe\|045e:02e6\|045e:0719" | head -1 || true)

if [ -z "$DONGLE" ]; then
    err "Xbox wireless dongle not found."
    err "Make sure the USB dongle is plugged in."
    exit 1
fi

BUS=$(echo "$DONGLE" | awk '{print $2}')
DEV=$(echo "$DONGLE" | awk '{print $4}' | tr -d ':')
DEVPATH="/dev/bus/usb/$BUS/$DEV"

log "Found dongle: $DONGLE"

# ─── Reset the USB device ────────────────────────────────────────────────────

info "Resetting USB device at $DEVPATH..."

if command -v usbreset &>/dev/null; then
    sudo usbreset "$DEVPATH"
else
    sudo python3 -c "
import fcntl, os
USBDEVFS_RESET = 0x5514
fd = os.open('$DEVPATH', os.O_WRONLY)
fcntl.ioctl(fd, USBDEVFS_RESET, 0)
os.close(fd)
print('USB device reset successful')
"
fi

log "USB device reset."

# ─── Reload the xone driver ──────────────────────────────────────────────────

if lsmod | grep -q "xone"; then
    info "Reloading xone driver..."
    sudo modprobe -r xone_wl 2>/dev/null || true
    sudo modprobe -r xone_dongle 2>/dev/null || true
    sleep 1
    sudo modprobe xone_wl 2>/dev/null || true
    sudo modprobe xone_dongle 2>/dev/null || true
    log "xone driver reloaded."
elif lsmod | grep -q "xpad"; then
    info "Reloading xpad driver..."
    sudo modprobe -r xpad
    sleep 1
    sudo modprobe xpad
    log "xpad driver reloaded."
else
    warn "No Xbox controller driver module found loaded."
    warn "Run setup-xbox-controller.sh first to install the xone driver."
fi

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
log "Done. Turn on your Xbox controller — it should auto-connect."
info "If this is a brand new controller, you need to press the dongle"
info "pair button once for the initial pairing."
echo ""
