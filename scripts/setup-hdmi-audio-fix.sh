#!/usr/bin/env bash
#
# Fix HDMI audio for Intel Arc B580 (Battlemage) with DP-to-HDMI adapter
#
# The xe display driver doesn't always enable the HDA audio output pin
# when using a DisplayPort-to-HDMI adapter, resulting in silent output
# despite PipeWire/ALSA showing everything as connected and running.
#
# This script:
#   1. Installs alsa-tools (provides hda-verb)
#   2. Enables the HDMI audio output pin on the HDA codec
#   3. Installs a systemd service to re-apply the fix on every boot
#   4. Installs a udev rule to re-apply when the sound card is hot-plugged
#
# Run with: bash scripts/setup-hdmi-audio-fix.sh
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
echo "  │   HDMI Audio Fix                          │"
echo "  │   Intel Arc B580 + DP-to-HDMI Adapter     │"
echo "  └──────────────────────────────────────────┘"
echo -e "${NC}"

# ─── Configuration ─────────────────────────────────────────────────────────
# Card 1 = HDA Intel PCH (HDMI audio companion to Arc B580)
# Codec address 2 = Intel Battlemage HDMI codec
# Node 0x04 = Pin Complex for HDMI 0 output
# Pin-ctl 0x40 = OUT enable bit
HDA_DEVICE="/dev/snd/hwC1D2"
PIN_NODE="0x04"
PIN_CTL_OUT="0x40"

# ─── Install alsa-tools ───────────────────────────────────────────────────

if ! command -v hda-verb &>/dev/null; then
    info "Installing alsa-tools (provides hda-verb)..."
    sudo apt update -qq
    sudo apt install -y alsa-tools
    log "alsa-tools installed."
else
    info "hda-verb already available."
fi

# ─── Verify HDA device exists ─────────────────────────────────────────────

if [ ! -e "$HDA_DEVICE" ]; then
    err "HDA device $HDA_DEVICE not found."
    err "Check your sound card layout with: ls /dev/snd/hwC*"
    err "And codec with: cat /proc/asound/card1/codec#*"
    exit 1
fi

# ─── Apply the fix now ────────────────────────────────────────────────────

info "Enabling HDMI audio output pin..."
info "  Device: $HDA_DEVICE  Pin: $PIN_NODE  Control: $PIN_CTL_OUT"

sudo hda-verb "$HDA_DEVICE" "$PIN_NODE" SET_PIN_WIDGET_CONTROL "$PIN_CTL_OUT"
log "HDMI audio output pin enabled."

# ─── Verify pin control was set ───────────────────────────────────────────

sleep 1
PIN_STATUS=$(grep -A 20 "Node 0x04" /proc/asound/card1/codec#2 | grep "Pin-ctls" || true)
if echo "$PIN_STATUS" | grep -q "0x40\|OUT"; then
    log "Verified: Pin-ctls shows output enabled."
else
    warn "Pin-ctls status: $PIN_STATUS"
    warn "Pin may not have been set correctly — check audio output."
fi

# ─── Install fix script to /usr/local/bin ──────────────────────────────────

FIXSCRIPT="/usr/local/bin/fix-hdmi-audio.sh"
info "Installing persistent fix script to $FIXSCRIPT..."

sudo tee "$FIXSCRIPT" > /dev/null <<'SCRIPT'
#!/usr/bin/env bash
#
# Fix HDMI audio output pin for Intel Battlemage (Arc B580)
# Called by systemd service and udev rule on boot / hotplug
#
HDA_DEVICE="/dev/snd/hwC1D2"
PIN_NODE="0x04"
PIN_CTL="0x40"

# Wait for the HDA device to be ready
for i in $(seq 1 30); do
    [ -e "$HDA_DEVICE" ] && break
    sleep 1
done

if [ ! -e "$HDA_DEVICE" ]; then
    echo "fix-hdmi-audio: $HDA_DEVICE not found after 30s, giving up." >&2
    exit 1
fi

# Small delay to let the codec fully initialize
sleep 2

# Enable the output pin
hda-verb "$HDA_DEVICE" "$PIN_NODE" SET_PIN_WIDGET_CONTROL "$PIN_CTL" 2>/dev/null
echo "fix-hdmi-audio: Enabled HDMI output pin on $HDA_DEVICE node $PIN_NODE"
SCRIPT

sudo chmod +x "$FIXSCRIPT"
log "Fix script installed."

# ─── Create systemd service for boot persistence ──────────────────────────

SERVICE_FILE="/etc/systemd/system/fix-hdmi-audio.service"
info "Creating systemd service for boot persistence..."

sudo tee "$SERVICE_FILE" > /dev/null <<'SERVICE'
[Unit]
Description=Fix HDMI audio output pin for Intel Arc B580
After=sound.target
Wants=sound.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/fix-hdmi-audio.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable fix-hdmi-audio.service
log "Systemd service enabled (runs on every boot)."

# ─── Create udev rule for hotplug persistence ─────────────────────────────

UDEV_RULE="/etc/udev/rules.d/91-fix-hdmi-audio.rules"
info "Creating udev rule for display hotplug..."

sudo tee "$UDEV_RULE" > /dev/null <<'UDEV'
# Re-enable HDMI audio pin when the HDA Intel PCH sound card appears
# Triggered on boot and when DP-to-HDMI adapter is re-plugged
ACTION=="add|change", SUBSYSTEM=="sound", ATTRS{vendor}=="0x8086", \
  RUN+="/usr/local/bin/fix-hdmi-audio.sh"
UDEV

sudo udevadm control --reload-rules
log "Udev rule installed."

# ─── Restart PipeWire to pick up changes ───────────────────────────────────

info "Restarting PipeWire audio stack..."
systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null || true
sleep 2
log "PipeWire restarted."

# ─── Verification ─────────────────────────────────────────────────────────

echo ""
info "Verification:"

# Pin control
PIN_CHECK=$(grep -A 20 "Node 0x04" /proc/asound/card1/codec#2 | grep "Pin-ctls" || true)
if echo "$PIN_CHECK" | grep -q "0x40\|OUT"; then
    echo -e "  ${GREEN}✓${NC} HDMI output pin enabled"
else
    echo -e "  ${YELLOW}✗${NC} Pin status: $PIN_CHECK"
fi

# Systemd service
if systemctl is-enabled fix-hdmi-audio.service &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Systemd service enabled (boot persistence)"
else
    echo -e "  ${YELLOW}✗${NC} Systemd service not enabled"
fi

# Udev rule
if [ -f "$UDEV_RULE" ]; then
    echo -e "  ${GREEN}✓${NC} Udev rule installed (hotplug persistence)"
else
    echo -e "  ${YELLOW}✗${NC} Udev rule not found"
fi

# Fix script
if [ -x "$FIXSCRIPT" ]; then
    echo -e "  ${GREEN}✓${NC} Fix script installed at $FIXSCRIPT"
else
    echo -e "  ${YELLOW}✗${NC} Fix script not found"
fi

echo ""
log "Done! Try playing audio now."
info "The fix will re-apply automatically on boot and adapter hotplug."
info ""
info "To undo this fix:"
info "  sudo systemctl disable fix-hdmi-audio.service"
info "  sudo rm $FIXSCRIPT $SERVICE_FILE $UDEV_RULE"
info "  sudo systemctl daemon-reload && sudo udevadm control --reload-rules"
echo ""
