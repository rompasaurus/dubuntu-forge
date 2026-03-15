#!/usr/bin/env bash
# Fix screen autorotation on GPD Duo (G1628-04) running GNOME/Wayland
# The MXC6655 accelerometer is detected but iio-sensor-proxy is masked by default.
# GNOME requires SW_TABLET_MODE which the GPD Duo doesn't report, so we use a
# lightweight Python daemon that monitors the sensor proxy and rotates the display
# via Mutter's D-Bus API.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== GPD Duo Autorotate Fix ==="

# Step 1: Ensure dependencies are installed
echo "[*] Checking dependencies..."
DEPS=(iio-sensor-proxy python3-dbus python3-gi gir1.2-glib-2.0)
MISSING=()
for pkg in "${DEPS[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        MISSING+=("$pkg")
    fi
done
if [ ${#MISSING[@]} -gt 0 ]; then
    echo "[*] Installing: ${MISSING[*]}"
    sudo apt-get install -y "${MISSING[@]}"
else
    echo "[✓] All dependencies installed"
fi

# Step 2: Unmask and enable iio-sensor-proxy
echo "[*] Unmasking iio-sensor-proxy.service..."
sudo systemctl unmask iio-sensor-proxy.service

echo "[*] Enabling iio-sensor-proxy.service..."
sudo systemctl enable iio-sensor-proxy.service

# Step 3: Create hwdb entry for GPD Duo accelerometer mount matrix
HWDB_FILE="/etc/udev/hwdb.d/61-sensor-gpd-duo.hwdb"
if [ ! -f "$HWDB_FILE" ]; then
    echo "[*] Creating hwdb entry for GPD Duo accelerometer..."
    sudo tee "$HWDB_FILE" > /dev/null <<'EOF'
sensor:modalias:acpi:MXC6655*:dmi:*:svnGPD:pnG1628-04:*
 ACCEL_MOUNT_MATRIX=0, 1, 0; 1, 0, 0; 0, 0, -1
EOF
    echo "[*] Updating hwdb and reloading udev rules..."
    sudo systemd-hwdb update
    sudo udevadm trigger
else
    echo "[✓] hwdb entry already exists at $HWDB_FILE"
fi

# Step 3b: Disable IIO buffered mode for the accelerometer
# The mxc4005 driver enables buffered/triggered mode by default, which prevents
# direct sysfs reads of in_accel_{x,y,z}_raw. The gpd-sensor-proxy needs direct
# reads, so we disable the buffer via a udev rule.
UDEV_RULE="/etc/udev/rules.d/99-gpd-duo-iio-buffer.rules"
if [ ! -f "$UDEV_RULE" ]; then
    echo "[*] Creating udev rule to disable IIO buffer mode..."
    sudo tee "$UDEV_RULE" > /dev/null <<'EOF'
# Disable IIO buffered mode on mxc4005 accelerometer so sysfs direct reads work
ACTION=="add", SUBSYSTEM=="iio", KERNEL=="iio:device*", ATTR{name}=="mxc4005", ATTR{buffer/enable}="0"
EOF
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    echo "[✓] udev rule created"
else
    echo "[✓] IIO buffer udev rule already exists"
fi

# Disable buffer now if currently enabled
if [ -f /sys/bus/iio/devices/iio:device0/buffer/enable ]; then
    if [ "$(cat /sys/bus/iio/devices/iio:device0/buffer/enable)" = "1" ]; then
        echo "[*] Disabling IIO buffer mode..."
        echo 0 | sudo tee /sys/bus/iio/devices/iio:device0/buffer/enable > /dev/null
    fi
fi

# Step 4: Install autorotate daemon
DAEMON_DEST="/usr/local/bin/gpd-duo-autorotate.py"
echo "[*] Installing autorotate daemon to $DAEMON_DEST..."
sudo cp "$SCRIPT_DIR/gpd-duo-autorotate.py" "$DAEMON_DEST"
sudo chmod +x "$DAEMON_DEST"

# Step 5: Install and enable systemd user service
SERVICE_DIR="$HOME/.config/systemd/user"
mkdir -p "$SERVICE_DIR"
cp "$SCRIPT_DIR/gpd-duo-autorotate.service" "$SERVICE_DIR/gpd-duo-autorotate.service"

echo "[*] Enabling autorotate service..."
systemctl --user daemon-reload
systemctl --user enable gpd-duo-autorotate.service
systemctl --user start gpd-duo-autorotate.service

# Step 6: Verify
echo ""
echo "=== Verification ==="

echo "[*] Accelerometer device:"
if [ -d /sys/bus/iio/devices/iio:device0 ]; then
    echo "    Name: $(cat /sys/bus/iio/devices/iio:device0/name)"
    echo "    Mount matrix: $(cat /sys/bus/iio/devices/iio:device0/in_accel_mount_matrix)"
else
    echo "    WARNING: No IIO accelerometer device found"
fi

echo ""
echo "[*] Autorotate daemon status:"
if systemctl --user is-active gpd-duo-autorotate.service &>/dev/null; then
    echo "    gpd-duo-autorotate is running"
else
    echo "    WARNING: gpd-duo-autorotate is NOT running"
    echo "    Check logs: journalctl --user -u gpd-duo-autorotate.service"
fi

echo ""
echo "=== Done ==="
echo "Autorotation should now be active. Try rotating the device."
echo ""
echo "If orientations are wrong, edit the ORIENTATION_MAP in $DAEMON_DEST"
echo "then run: systemctl --user restart gpd-duo-autorotate.service"
