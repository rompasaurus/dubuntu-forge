#!/usr/bin/env bash
#
# Xbox Wireless Controller Manager
#
# Provides options to reconnect, pair, or reset the Xbox USB Wireless Adapter
# using the xone driver — no need to press the dongle pair button.
#
# Run with: bash scripts/xbox-reconnect.sh
#
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
info() { echo -e "${CYAN}[*]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[x]${NC} $*"; }

DONGLE=""
BUS=""
DEV=""
DEVPATH=""
SYSDEV=""

# ─── Find the Xbox Wireless Adapter ──────────────────────────────────────────

find_dongle() {
    DONGLE=$(lsusb | grep -i "045e:02fe\|045e:02e6\|045e:0719" | head -1 || true)

    if [ -z "$DONGLE" ]; then
        err "Xbox wireless dongle not found."
        err "Make sure the USB dongle is plugged in."
        exit 1
    fi

    BUS=$(echo "$DONGLE" | awk '{print $2}')
    DEV=$(echo "$DONGLE" | awk '{print $4}' | tr -d ':')
    DEVPATH="/dev/bus/usb/$BUS/$DEV"

    # Find the sysfs device path (e.g. /sys/bus/usb/devices/3-3.4.3)
    SYSDEV=""
    for d in /sys/bus/usb/devices/*; do
        local vid pid
        vid=$(cat "$d/idVendor" 2>/dev/null) || continue
        pid=$(cat "$d/idProduct" 2>/dev/null) || continue
        if [[ "$vid" == "045e" && ( "$pid" == "02fe" || "$pid" == "02e6" || "$pid" == "0719" ) ]]; then
            SYSDEV="$d"
            break
        fi
    done

    log "Found dongle: $DONGLE"
    if [ -n "$SYSDEV" ]; then
        info "Sysfs device: $(basename "$SYSDEV")"
    fi
}

# ─── Find the xone-dongle sysfs pairing path ─────────────────────────────────

find_pairing_path() {
    PAIRING_PATH=""
    for iface in /sys/bus/usb/drivers/xone-dongle/*/pairing; do
        if [ -f "$iface" ]; then
            PAIRING_PATH="$iface"
            return 0
        fi
    done
    return 1
}

# ─── USB hardware power cycle ─────────────────────────────────────────────────
# The xone MT76 radio can get stuck (init radio failed: -110) and needs a real
# electrical power cut to recover — equivalent to physically unplugging the dongle.
# uhubctl toggles VBUS power on the USB hub port. Falls back to deauthorize/reauthorize.

find_hub_location() {
    # The dongle's sysfs path encodes the hub topology, e.g. 3-3.4.3 means
    # bus 3, port 3, hub port 4, device port 3
    # uhubctl needs the hub's USB location and the port number
    if [ -z "$SYSDEV" ]; then
        return 1
    fi

    local devname
    devname=$(basename "$SYSDEV")  # e.g. 3-3.4.3

    # Port number is the last segment after the last dot
    HUB_PORT="${devname##*.}"
    # Hub location is everything before the last dot
    HUB_LOC="${devname%.*}"

    if [ "$HUB_PORT" = "$devname" ]; then
        # No dot — device is directly on a root hub port
        HUB_PORT="${devname##*-}"
        HUB_LOC=""
    fi

    return 0
}

do_power_cycle() {
    # Method 1: uhubctl — real hardware power cut (best)
    if command -v uhubctl &>/dev/null && [ -n "$SYSDEV" ] && find_hub_location; then
        info "Power-cycling USB port with uhubctl (hardware power cut)..."
        local uhub_args="-a cycle -p $HUB_PORT -d 3"
        if [ -n "$HUB_LOC" ]; then
            uhub_args="-l $HUB_LOC $uhub_args"
        fi
        if sudo uhubctl $uhub_args 2>/dev/null; then
            sleep 2
            find_dongle
            log "USB port power-cycled (hardware)."
            return
        fi
        warn "uhubctl failed — falling back to deauthorize method."
    fi

    # Method 2: deauthorize/reauthorize via sysfs
    if [ -n "$SYSDEV" ] && [ -f "$SYSDEV/authorized" ]; then
        info "Power-cycling USB device (deauthorize/reauthorize)..."
        sudo sh -c "echo 0 > '$SYSDEV/authorized'"
        sleep 3
        sudo sh -c "echo 1 > '$SYSDEV/authorized'"
        sleep 2
        find_dongle
        log "USB device power-cycled."
        return
    fi

    # Method 3: usbreset (soft — may not clear radio stuck state)
    warn "No hardware power-cycle available — using soft USB reset."
    warn "Install uhubctl for reliable recovery: sudo apt install uhubctl"
    do_usb_reset
}

# ─── USB Reset (soft) ────────────────────────────────────────────────────────

do_usb_reset() {
    info "Resetting USB device at $DEVPATH..."

    if command -v usbreset &>/dev/null; then
        sudo usbreset "$BUS/$DEV"
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
}

# ─── Reload xone driver ──────────────────────────────────────────────────────

do_reload_driver() {
    if lsmod | grep -q "xone_dongle" || modinfo xone_dongle &>/dev/null; then
        info "Reloading xone driver..."
        sudo modprobe -r xone_dongle 2>/dev/null || true
        sudo modprobe -r xone_gip 2>/dev/null || true
        sleep 1
        sudo modprobe xone_gip 2>/dev/null || true
        sudo modprobe xone_dongle 2>/dev/null || true
        log "xone driver reloaded."
    elif lsmod | grep -q "xpad"; then
        info "Reloading xpad driver..."
        sudo modprobe -r xpad
        sleep 1
        sudo modprobe xpad
        log "xpad driver reloaded."
    else
        warn "No Xbox controller driver module found."
        warn "Run setup-xbox-controller.sh first to install the xone driver."
        return 1
    fi
}

# ─── Wait for driver probe and check success ─────────────────────────────────

wait_for_driver() {
    local retries=5
    info "Waiting for xone driver to initialize dongle..."
    for ((i = 1; i <= retries; i++)); do
        sleep 1
        if find_pairing_path; then
            log "Driver initialized successfully."
            return 0
        fi
        # Check if driver is still probing
        if journalctl -k --no-pager --since "10 seconds ago" 2>/dev/null | grep -q "init radio failed"; then
            warn "Radio init failed (attempt $i/$retries)."
            if ((i < retries)); then
                info "Retrying with power cycle..."
                do_power_cycle
                do_reload_driver
            fi
        fi
    done
    return 1
}

# ─── Action: Reconnect ───────────────────────────────────────────────────────

action_reconnect() {
    echo ""
    info "Reconnecting — power-cycle dongle and reload driver..."
    echo ""
    do_power_cycle
    do_reload_driver
    echo ""
    log "Done. Turn on your Xbox controller — it should auto-connect."
    echo ""
}

# ─── Action: Pair new controller ──────────────────────────────────────────────

action_pair() {
    echo ""
    info "Putting dongle into pairing mode..."
    echo ""

    # Power cycle and reload to get a clean state
    do_power_cycle
    do_reload_driver

    if wait_for_driver; then
        sudo sh -c "echo 1 > '$PAIRING_PATH'"
        log "Dongle is now in pairing mode!"
    else
        warn "Could not activate pairing — driver failed to initialize."
        warn "Try unplugging the dongle, waiting 5 seconds, and plugging it back in."
        warn "Then run this script again."
    fi

    echo ""
    info "On your controller: hold the ${BOLD}Xbox button${NC} to power on,"
    info "then press the small ${BOLD}pair button${NC} on top of the controller."
    info "The Xbox button will flash faster when in pairing mode."
    echo ""
}

# ─── Action: Full reset ──────────────────────────────────────────────────────

action_full_reset() {
    echo ""
    info "Full reset — unload driver, power-cycle USB, reload driver..."
    echo ""

    if lsmod | grep -q "xone"; then
        info "Unloading xone modules..."
        sudo modprobe -r xone_dongle 2>/dev/null || true
        sudo modprobe -r xone_gip 2>/dev/null || true
        sleep 1
    fi

    do_power_cycle
    sleep 2

    info "Reloading xone modules..."
    sudo modprobe xone_gip 2>/dev/null || true
    sudo modprobe xone_dongle 2>/dev/null || true

    log "Full reset complete."
    echo ""
    log "Turn on your Xbox controller — it should auto-connect."
    echo ""
}

# ─── Menu ─────────────────────────────────────────────────────────────────────

echo -e "${CYAN}"
echo "  ┌──────────────────────────────────────────┐"
echo "  │   Xbox Wireless Controller Manager        │"
echo "  └──────────────────────────────────────────┘"
echo -e "${NC}"

find_dongle

echo ""
echo -e "  ${BOLD}1)${NC} Reconnect  — power-cycle dongle & reload driver (already paired)"
echo -e "  ${BOLD}2)${NC} Pair       — put dongle in pairing mode (new controller)"
echo -e "  ${BOLD}3)${NC} Full reset — unload, power-cycle, reload (troubleshoot)"
echo -e "  ${BOLD}q)${NC} Quit"
echo ""
read -rp "  Choose an option [1-3/q]: " choice

case "$choice" in
    1) action_reconnect ;;
    2) action_pair ;;
    3) action_full_reset ;;
    q|Q) echo ""; info "Bye."; echo "" ;;
    *) err "Invalid option."; exit 1 ;;
esac
