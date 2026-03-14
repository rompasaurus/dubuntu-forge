#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Xbox Wireless Controller — Bluetooth Fix for Steam on Linux
# =============================================================================
# Problem: Xbox Wireless Controller (045E:0B22) connected via Bluetooth is
#          classified as a keyboard by the hid_generic driver instead of a
#          joystick. Steam ignores devices without ID_INPUT_JOYSTICK.
#
# Fix:     Install xpadneo — a DKMS kernel module that replaces hid_generic
#          for Xbox Bluetooth controllers. It properly classifies the device
#          as a gamepad and provides rumble, battery reporting, and correct
#          button mapping.
#
# Hardware: Xbox Wireless Controller (Bluetooth mode)
#           Vendor/Product: 045E:0B22
# See:      https://github.com/atar-axis/xpadneo
# =============================================================================

XPADNEO_DIR="/tmp/xpadneo"
STALE_UDEV="/etc/udev/rules.d/71-xbox-bt-controller.rules"

echo "=== Xbox Wireless Controller Bluetooth Fix (xpadneo) ==="
echo ""

# --- Clean up stale udev-only fix if present ---
if [[ -f "$STALE_UDEV" ]]; then
    echo "Removing old udev-only workaround (${STALE_UDEV})..."
    sudo rm -f "$STALE_UDEV"
    sudo udevadm control --reload-rules
fi

# --- Install prerequisites ---
echo "Installing prerequisites (dkms, linux-headers, git)..."
sudo apt-get update -qq
sudo apt-get install -y dkms "linux-headers-$(uname -r)" git

# --- Check if xpadneo is already installed ---
if dkms status xpadneo 2>/dev/null | grep -q "installed"; then
    INSTALLED_VER=$(dkms status xpadneo 2>/dev/null | grep installed | head -1 | awk -F'[,/]' '{print $2}' | tr -d ' ')
    echo ""
    echo "xpadneo ${INSTALLED_VER} is already installed."
    echo "To update, run: cd ${XPADNEO_DIR} && git pull && sudo ./update.sh"
    echo ""
else
    # --- Clone and install xpadneo ---
    echo ""
    echo "Cloning xpadneo..."
    rm -rf "$XPADNEO_DIR"
    git clone https://github.com/atar-axis/xpadneo.git "$XPADNEO_DIR"

    echo "Installing xpadneo via DKMS..."
    cd "$XPADNEO_DIR"
    sudo ./install.sh
    echo ""
fi

# --- Verify ---
echo "=== Verification ==="

if lsmod | grep -q xpadneo; then
    echo "[OK] xpadneo module loaded"
else
    echo "[!!] xpadneo module not loaded — a reboot is required"
fi

# Check if controller is currently connected and classified correctly
JS_DEV=$(find /dev/input -name 'js*' 2>/dev/null | head -1)
if [[ -n "$JS_DEV" ]]; then
    if udevadm info "$JS_DEV" 2>/dev/null | grep -q "ID_INPUT_JOYSTICK=1"; then
        echo "[OK] ${JS_DEV} tagged as joystick"
    else
        echo "[!!] ${JS_DEV} not tagged as joystick yet — reboot and reconnect the controller"
    fi
fi

echo ""
echo "=== Next Steps ==="
echo "1. Reboot your machine"
echo "2. Turn on the Xbox controller and connect via Bluetooth"
echo "3. Open Steam → Settings → Controller"
echo "4. Enable 'Xbox Extended Feature Support' if prompted"
echo "5. The controller should appear as an Xbox gamepad"
echo ""
echo "To uninstall: cd ${XPADNEO_DIR} && sudo ./uninstall.sh"
