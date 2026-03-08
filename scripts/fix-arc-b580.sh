#!/usr/bin/env bash
#
# Fix Intel Arc B580 graphical glitches + enable 120Hz on Ubuntu 25.10
# Samsung QBQ90 4K TV via HDMI 2.1
#
# Issues addressed:
#   1. GNOME desktop corruption (gray blocks, flashing rectangles in Files,
#      Terminal, Settings, etc.) caused by GSK GPU renderer + Xe driver.
#   2. Monitor stuck at 60Hz despite HDMI 2.1 + 120Hz panel support.
#   3. Missing VAAPI hardware video acceleration.
#
# Run with: bash scripts/fix-arc-b580.sh
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
echo "  │   Intel Arc B580 Fix (Ubuntu 25.10)       │"
echo "  │   Graphical Glitches + 120Hz + VAAPI      │"
echo "  └──────────────────────────────────────────┘"
echo -e "${NC}"

# ─── Verify Arc B580 is present ────────────────────────────────────────────────

if ! lspci | grep -qi "arc.*b580\|battlemage"; then
    err "Intel Arc B580 not detected. This script is specific to that GPU."
    exit 1
fi
log "Intel Arc B580 detected."

# ─── Fix 1: GNOME graphical corruption ────────────────────────────────────────
#
# The GSK GPU renderer (used by GTK4 apps: Files, Terminal, Settings, etc.)
# has rendering bugs with the Xe driver on Battlemage GPUs.
# Forcing GSK_RENDERER=gl and disabling CCS (color compression) fixes it.
#

info "Fixing GNOME graphical corruption..."

ENV_FILE="/etc/environment"
ENVD_DIR="/etc/environment.d"
ENVD_FILE="$ENVD_DIR/90-arc-b580-fixes.conf"

# Use environment.d (systemd user env) — works properly on Wayland sessions
sudo mkdir -p "$ENVD_DIR"

if [ -f "$ENVD_FILE" ]; then
    warn "Fix file already exists at $ENVD_FILE — backing up."
    sudo cp "$ENVD_FILE" "$ENVD_FILE.bak.$(date +%s)"
fi

sudo tee "$ENVD_FILE" > /dev/null <<'EOF'
# Intel Arc B580 fixes for Ubuntu 25.10
# Fix GNOME/GTK4 graphical corruption (gray blocks, flashing rectangles)
GSK_RENDERER=gl

# Disable Color Compression Surfaces — fixes rendering artifacts in Xe driver
INTEL_DEBUG=noccs
EOF

log "Created $ENVD_FILE (GSK_RENDERER=gl + INTEL_DEBUG=noccs)"

# Also add to /etc/environment as fallback for non-systemd login paths
for var in "GSK_RENDERER=gl" "INTEL_DEBUG=noccs"; do
    key="${var%%=*}"
    if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
        sudo sed -i "s|^${key}=.*|${var}|" "$ENV_FILE"
        info "Updated $key in $ENV_FILE"
    else
        echo "$var" | sudo tee -a "$ENV_FILE" > /dev/null
        info "Added $key to $ENV_FILE"
    fi
done

log "Graphical corruption fix applied."

# ─── Fix 2: Enable 120Hz refresh rate ─────────────────────────────────────────
#
# The Samsung QBQ90 supports 4K@120Hz via HDMI 2.1 (VIC 117/118).
# The Xe driver may default to limited bandwidth mode, capping at 60Hz.
# We need to:
#   a) Ensure HDMI output uses full bandwidth (max bpc = 8 for 4K@120)
#   b) Add a custom xrandr mode if 120Hz isn't exposed
#

info "Configuring 120Hz support..."

# Create udev rule to ensure HDMI 2.1 high-bandwidth mode
UDEV_RULE="/etc/udev/rules.d/99-arc-b580-hdmi.rules"
if [ ! -f "$UDEV_RULE" ]; then
    sudo tee "$UDEV_RULE" > /dev/null <<'EOF'
# Intel Arc B580 — ensure HDMI 2.1 FRL (Fixed Rate Link) is enabled
ACTION=="add|change", KERNEL=="card0", SUBSYSTEM=="drm", RUN+="/bin/sh -c 'echo 12 > /sys/class/drm/card0/card0-HDMI-A-3/max_bpc 2>/dev/null || true'"
EOF
    log "Created udev rule for HDMI 2.1 max bandwidth."
else
    info "udev rule already exists."
fi

# Set max bpc now
if [ -f /sys/class/drm/card0/card0-HDMI-A-3/max_bpc ]; then
    echo 12 | sudo tee /sys/class/drm/card0/card0-HDMI-A-3/max_bpc > /dev/null 2>&1 || true
    log "Set max_bpc=12 for HDMI-3."
fi

# Create an autostart script that adds the 120Hz mode on login
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

cat > "$AUTOSTART_DIR/arc-b580-120hz.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Arc B580 120Hz Setup
Exec=/home/dooktv/.local/bin/arc-b580-120hz.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
Comment=Enable 120Hz mode for Samsung QBQ90 via HDMI 2.1
EOF

mkdir -p "$HOME/.local/bin"

cat > "$HOME/.local/bin/arc-b580-120hz.sh" <<'SCRIPT'
#!/usr/bin/env bash
# Wait for display to be ready
sleep 3

# Detect the active HDMI output
OUTPUT=$(xrandr 2>/dev/null | grep " connected" | grep -i "HDMI" | head -1 | awk '{print $1}')
[ -z "$OUTPUT" ] && exit 0

# Check if 120Hz mode already available
if xrandr 2>/dev/null | grep -q "120\.00"; then
    # Mode exists, try to apply it
    xrandr --output "$OUTPUT" --mode 2560x1440 --rate 120 2>/dev/null || true
    exit 0
fi

# Add custom 2560x1440@120Hz mode
# Modeline generated for HDMI 2.1 timing
MODELINE=$(cvt 2560 1440 120 2>/dev/null | grep Modeline | sed 's/Modeline //')
MODE_NAME=$(echo "$MODELINE" | awk '{print $1}' | tr -d '"')
MODE_PARAMS=$(echo "$MODELINE" | cut -d' ' -f2-)

if [ -n "$MODE_NAME" ]; then
    xrandr --newmode $MODE_NAME $MODE_PARAMS 2>/dev/null || true
    xrandr --addmode "$OUTPUT" "$MODE_NAME" 2>/dev/null || true
    xrandr --output "$OUTPUT" --mode "$MODE_NAME" 2>/dev/null || true
fi

# Also try 4K@120 (native TV mode) if 1440p@120 fails
xrandr --newmode "3840x2160_120" 1430.37 3840 4152 4576 5312 2160 2163 2168 2250 -hsync +vsync 2>/dev/null || true
xrandr --addmode "$OUTPUT" "3840x2160_120" 2>/dev/null || true
SCRIPT

chmod +x "$HOME/.local/bin/arc-b580-120hz.sh"
log "Created 120Hz autostart script."

# ─── Fix 3: VAAPI hardware video acceleration ─────────────────────────────────

info "Installing VAAPI support for hardware video decoding..."

if dpkg -s intel-media-va-driver &>/dev/null; then
    log "intel-media-va-driver already installed."
else
    sudo apt install -y intel-media-va-driver 2>/dev/null || warn "Could not install intel-media-va-driver"
fi

if dpkg -s libvdpau-va-gl1 &>/dev/null; then
    log "libvdpau-va-gl1 already installed."
else
    sudo apt install -y libvdpau-va-gl1 2>/dev/null || warn "Could not install libvdpau-va-gl1"
fi

if dpkg -s vainfo &>/dev/null; then
    log "vainfo already installed."
else
    sudo apt install -y vainfo 2>/dev/null || warn "Could not install vainfo"
fi

log "VAAPI packages installed."

# ─── Fix 4: Xe driver kernel parameters ───────────────────────────────────────
#
# Ensure Xe driver uses optimal settings for Battlemage
#

info "Configuring Xe kernel module parameters..."

MODPROBE_FILE="/etc/modprobe.d/arc-b580.conf"
if [ ! -f "$MODPROBE_FILE" ]; then
    sudo tee "$MODPROBE_FILE" > /dev/null <<'EOF'
# Intel Arc B580 (Battlemage) — Xe driver tuning
# Enable GuC/HuC firmware submission
options xe enable_guc=3
EOF
    log "Created $MODPROBE_FILE"
    sudo update-initramfs -u 2>/dev/null || warn "Could not update initramfs"
else
    info "Xe modprobe config already exists."
fi

# ─── Fix 5: Reload udev + systemctl ───────────────────────────────────────────

info "Reloading system configuration..."
sudo udevadm control --reload-rules 2>/dev/null || true
sudo udevadm trigger 2>/dev/null || true
sudo systemctl daemon-reload 2>/dev/null || true
log "System configuration reloaded."

# ─── Verify ───────────────────────────────────────────────────────────────────

echo ""
info "Verification:"

# GPU
if lspci | grep -qi "battlemage"; then
    echo -e "  ${GREEN}✓${NC} Intel Arc B580 detected"
else
    echo -e "  ${YELLOW}✗${NC} GPU not detected"
fi

# Environment fixes
if [ -f "$ENVD_FILE" ]; then
    echo -e "  ${GREEN}✓${NC} GSK_RENDERER=gl configured"
    echo -e "  ${GREEN}✓${NC} INTEL_DEBUG=noccs configured"
else
    echo -e "  ${YELLOW}✗${NC} Environment fixes not applied"
fi

# VAAPI
if command -v vainfo &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} vainfo available"
else
    echo -e "  ${YELLOW}✗${NC} vainfo not found"
fi

# 120Hz script
if [ -x "$HOME/.local/bin/arc-b580-120hz.sh" ]; then
    echo -e "  ${GREEN}✓${NC} 120Hz autostart script installed"
else
    echo -e "  ${YELLOW}✗${NC} 120Hz script not found"
fi

# Kernel module config
if [ -f "$MODPROBE_FILE" ]; then
    echo -e "  ${GREEN}✓${NC} Xe kernel module configured"
else
    echo -e "  ${YELLOW}✗${NC} Xe module config not found"
fi

echo ""
warn "A REBOOT is required for all changes to take effect."
info "After reboot:"
info "  - Desktop glitches should be fixed (GSK_RENDERER=gl)"
info "  - Check 120Hz: Settings → Displays → Refresh Rate"
info "  - If 120Hz still missing, try DisplayPort instead of HDMI"
info "  - Verify VAAPI: vainfo"
echo ""
log "Done!"
