#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# ASUS ROG Zephyrus G16 (GU605MY) — Built-in Keyboard Fix for Ubuntu
# =============================================================================
# Problem: The hid_asus kernel driver (kernel 6.17) corrupts the HID report
#          descriptor for the N-Key keyboard (0b05:19b6), causing only one
#          key to work after login.
#
# Fix:     Blacklist hid_asus so the keyboard falls back to hid-generic,
#          rebuild initramfs so the fix survives reboot, then rebind the
#          USB device for an immediate fix.
#
# Hardware: ASUS ROG Zephyrus G16 GU605MY
# =============================================================================

USB_DEV="3-6"
BLACKLIST_CONF="/etc/modprobe.d/blacklist-hid-asus.conf"

# --- Blacklist hid_asus ---
BLACKLIST_CONTENT="blacklist hid_asus
install hid_asus /bin/true"

if [[ ! -f "$BLACKLIST_CONF" ]] || ! grep -q "install hid_asus" "$BLACKLIST_CONF"; then
    echo "Blacklisting hid_asus (blacklist + install override)..."
    echo "$BLACKLIST_CONTENT" | sudo tee "$BLACKLIST_CONF" > /dev/null
    NEED_INITRAMFS=1
else
    echo "Blacklist already in place."
    NEED_INITRAMFS=0
fi

# --- Rebuild initramfs so blacklist persists across reboots ---
if [[ "$NEED_INITRAMFS" -eq 1 ]]; then
    echo "Rebuilding initramfs (so the fix survives reboot)..."
    sudo update-initramfs -u
else
    echo "Initramfs already up to date."
fi

# --- Immediate fix: unload module and rebind device ---
if lsmod | grep -q hid_asus; then
    echo "Removing hid_asus module..."
    sudo modprobe -r hid_asus

    echo "Rebinding USB keyboard device..."
    echo -n "$USB_DEV" | sudo tee /sys/bus/usb/drivers/usb/unbind > /dev/null
    sleep 1
    echo -n "$USB_DEV" | sudo tee /sys/bus/usb/drivers/usb/bind > /dev/null
    sleep 1
else
    echo "hid_asus not loaded — keyboard should already be working."
fi

echo ""
echo "Done — keyboard fix applied and will persist across reboots."
