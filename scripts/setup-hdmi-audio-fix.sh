#!/usr/bin/env bash
#
# Fix HDMI audio for Intel Arc B580 (Battlemage) with DP-to-HDMI adapter
# (Cable Matters DP 1.4 to HDMI 2.1 / Parade PS186)
#
# Problem: The xe display driver (kernel 6.17) doesn't embed audio into
# the DisplayPort stream when using an active DP-to-HDMI adapter.
# The HDA codec is configured correctly but no audio reaches the TV.
#
# Solution: Use the GPU's native HDMI port for audio to the receiver,
# and the DP adapter for 4K@120Hz video to the TV. A custom PipeWire
# sink is created that explicitly targets the HDMI ALSA device (hw:1,7)
# for the Denon AVR, bypassing the broken DP audio path entirely.
#
# Setup:
#   Video: Arc B580 DP → Cable Matters adapter → Samsung QBQ90 (4K@120Hz)
#   Audio: Arc B580 HDMI → Denon AVR (7.1 surround)
#
# Usage:
#   bash scripts/setup-hdmi-audio-fix.sh          # Install
#   bash scripts/setup-hdmi-audio-fix.sh --undo   # Remove everything
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

PIPEWIRE_CONF="$HOME/.config/pipewire/pipewire.conf.d/denon-hdmi-sink.conf"
OLD_FIXSCRIPT="/usr/local/bin/fix-hdmi-audio.sh"
OLD_SERVICE="/etc/systemd/system/fix-hdmi-audio.service"
OLD_UDEV="/etc/udev/rules.d/91-fix-hdmi-audio.rules"

# ─── Undo mode ────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--undo" ]]; then
    echo -e "${CYAN}"
    echo "  ┌──────────────────────────────────────────┐"
    echo "  │   HDMI Audio Fix — Uninstall              │"
    echo "  └──────────────────────────────────────────┘"
    echo -e "${NC}"

    # Remove PipeWire custom sink
    if [ -f "$PIPEWIRE_CONF" ]; then
        rm -f "$PIPEWIRE_CONF"
        log "Removed $PIPEWIRE_CONF"
    else
        info "PipeWire config not found (already clean)."
    fi

    # Remove old systemd/udev artifacts (requires sudo)
    if systemctl is-enabled fix-hdmi-audio.service &>/dev/null; then
        sudo systemctl disable fix-hdmi-audio.service
        log "Systemd service disabled."
    fi
    for f in "$OLD_FIXSCRIPT" "$OLD_SERVICE" "$OLD_UDEV"; do
        if [ -f "$f" ]; then
            sudo rm -f "$f"
            log "Removed $f"
        fi
    done
    if [ -f "$OLD_SERVICE" ] || [ -f "$OLD_UDEV" ]; then
        sudo systemctl daemon-reload 2>/dev/null || true
        sudo udevadm control --reload-rules 2>/dev/null || true
    fi

    # Restart PipeWire to apply
    systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null || true

    echo ""
    log "Undo complete. All HDMI audio fix artifacts removed."
    exit 0
fi

# ─── Install mode ─────────────────────────────────────────────────────────
echo -e "${CYAN}"
echo "  ┌──────────────────────────────────────────┐"
echo "  │   HDMI Audio Fix                          │"
echo "  │   Intel Arc B580 + DP-to-HDMI Adapter     │"
echo "  │                                           │"
echo "  │   Video: DP adapter → TV (4K@120Hz)       │"
echo "  │   Audio: HDMI → Denon AVR (7.1)           │"
echo "  └──────────────────────────────────────────┘"
echo -e "${NC}"

# ─── Verify HDMI connection to receiver ──────────────────────────────────

info "Checking for Denon AVR on HDMI..."
if aplay -l 2>/dev/null | grep -q "DENON-AVR"; then
    log "Denon AVR detected on HDMI."
else
    warn "Denon AVR not detected. Make sure HDMI cable is connected"
    warn "from the Arc B580 HDMI port to your Denon receiver."
    warn ""
    warn "If the receiver doesn't appear, try:"
    warn "  for i in 1 2 3 4; do echo detect | sudo tee /sys/class/drm/card0-HDMI-A-\$i/status; done"
    warn ""
    # Find what IS on HDMI
    HDMI_DEVICES=$(aplay -l 2>/dev/null | grep "HDMI" || true)
    if [ -n "$HDMI_DEVICES" ]; then
        info "Available HDMI devices:"
        echo "$HDMI_DEVICES"
    fi
fi

# ─── Detect ALSA device number for Denon ─────────────────────────────────

DENON_DEV=""
for dev in 3 7 8 9; do
    name=$(head -1 /proc/asound/card1/pcm${dev}p/sub0/info 2>/dev/null | awk -F': ' '{print $2}')
    id=$(grep "^id:" /proc/asound/card1/pcm${dev}p/sub0/info 2>/dev/null | awk '{print $2}')
    subname=$(grep "^name:" /proc/asound/card1/pcm${dev}p/sub0/info 2>/dev/null | awk '{print $2}')
    # Check ELD for this device
    for eld in /proc/asound/card1/eld#2.*; do
        eld_valid=$(grep "eld_valid" "$eld" 2>/dev/null | awk '{print $2}')
        monitor=$(grep "monitor_name" "$eld" 2>/dev/null | awk '{print $2}')
        if [ "$eld_valid" = "1" ] && echo "$monitor" | grep -qi "denon"; then
            # Match ELD to PCM device via pin
            DENON_DEV="$dev"
            break 2
        fi
    done
done

# Fallback: check aplay -l output
if [ -z "$DENON_DEV" ]; then
    DENON_DEV=$(aplay -l 2>/dev/null | grep "DENON-AVR" | head -1 | sed 's/.*device \([0-9]*\).*/\1/')
fi

if [ -z "$DENON_DEV" ]; then
    err "Could not determine ALSA device number for Denon AVR."
    err "Check with: aplay -l | grep DENON"
    exit 1
fi

log "Denon AVR is on ALSA hw:1,$DENON_DEV"

# ─── Create PipeWire custom sink ─────────────────────────────────────────
#
# The default PipeWire/WirePlumber profile system doesn't correctly map
# the Battlemage HDMI codec's dynamic pin-to-PCM assignments. Creating
# an explicit ALSA sink that targets hw:1,<device> bypasses this issue.
#

info "Creating PipeWire sink for Denon AVR..."
mkdir -p "$(dirname "$PIPEWIRE_CONF")"

cat > "$PIPEWIRE_CONF" <<EOF
context.objects = [
    {   factory = adapter
        args = {
            factory.name     = api.alsa.pcm.sink
            node.name        = "alsa_output.denon-avr"
            node.description = "DENON-AVR HDMI 7.1"
            media.class      = "Audio/Sink"
            api.alsa.path    = "hw:1,$DENON_DEV"
            audio.format     = "S32LE"
            audio.rate       = 48000
            audio.channels   = 8
            audio.position   = [ FL FR RL RR FC LFE SL SR ]
        }
    }
]
EOF

log "Created $PIPEWIRE_CONF"

# ─── Restart PipeWire and set default ────────────────────────────────────

info "Restarting PipeWire..."
systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null || true
sleep 3

# Find the new sink and set as default
DENON_SINK=$(wpctl status 2>/dev/null | grep "DENON-AVR" | head -1 | awk '{print $1}' | tr -d '.*')
if [ -n "$DENON_SINK" ]; then
    wpctl set-default "$DENON_SINK"
    wpctl set-volume "$DENON_SINK" 1.0
    log "Set DENON-AVR (sink $DENON_SINK) as default audio output."
else
    warn "Could not find DENON-AVR sink. Set it manually in GNOME Sound settings."
fi

# ─── Quick audio test ────────────────────────────────────────────────────

info "Playing test tone (2 seconds)..."
echo ""
timeout 3 speaker-test -D "plughw:1,$DENON_DEV" -c 2 -l 1 -t sine 2>&1 || true
echo ""

# ─── Clean up old artifacts ──────────────────────────────────────────────
#
# Remove the previous hda-verb / module-reload approach that didn't work.
#

CLEANED=false
for f in "$OLD_FIXSCRIPT" "$OLD_SERVICE" "$OLD_UDEV"; do
    if [ -f "$f" ]; then
        info "Cleaning up old fix artifact: $f"
        sudo rm -f "$f" 2>/dev/null || warn "Could not remove $f (run with sudo)"
        CLEANED=true
    fi
done
if systemctl is-enabled fix-hdmi-audio.service &>/dev/null 2>&1; then
    sudo systemctl disable fix-hdmi-audio.service 2>/dev/null || true
    CLEANED=true
fi
if $CLEANED; then
    sudo systemctl daemon-reload 2>/dev/null || true
    sudo udevadm control --reload-rules 2>/dev/null || true
    log "Old fix artifacts cleaned up."
fi

# ─── Verification ───────────────────────────────────────────────────────

echo ""
info "Verification:"

# Denon in aplay
if aplay -l 2>/dev/null | grep -q "DENON-AVR"; then
    echo -e "  ${GREEN}✓${NC} Denon AVR detected (ALSA hw:1,$DENON_DEV)"
else
    echo -e "  ${YELLOW}✗${NC} Denon AVR not in aplay output"
fi

# PipeWire sink
if wpctl status 2>/dev/null | grep -q "DENON-AVR"; then
    echo -e "  ${GREEN}✓${NC} DENON-AVR PipeWire sink active"
else
    echo -e "  ${YELLOW}✗${NC} DENON-AVR sink not found in PipeWire"
fi

# Default sink
DEFAULT=$(wpctl status 2>/dev/null | grep "Audio/Sink" | head -1 || true)
if echo "$DEFAULT" | grep -q "denon-avr"; then
    echo -e "  ${GREEN}✓${NC} Set as default audio output"
else
    echo -e "  ${YELLOW}!${NC} Not set as default (select in GNOME Sound settings)"
fi

# PipeWire config
if [ -f "$PIPEWIRE_CONF" ]; then
    echo -e "  ${GREEN}✓${NC} PipeWire config: $PIPEWIRE_CONF"
fi

echo ""
log "Done!"
info ""
info "Setup:"
info "  Video: DP adapter → Samsung QBQ90 (4K@120Hz)"
info "  Audio: HDMI → Denon AVR (7.1 surround)"
info ""
info "Tip: Disable the Denon's video in Settings → Displays"
info "     so it doesn't extend your desktop."
info ""
info "To uninstall: bash scripts/setup-hdmi-audio-fix.sh --undo"
echo ""
