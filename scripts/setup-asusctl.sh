#!/usr/bin/env bash
#
# Install asusctl + ROG Control Center for ASUS ROG laptops.
# Controls keyboard RGB, fan profiles, and power settings.
# Run with: bash scripts/setup-asusctl.sh
#
set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
info() { echo -e "${CYAN}[*]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }

echo -e "${CYAN}"
echo "  ┌──────────────────────────────────────────────┐"
echo "  │   asusctl + ROG Control Center Installer      │"
echo "  └──────────────────────────────────────────────┘"
echo -e "${NC}"

# ─── Verify this is an ASUS ROG machine ──────────────────────────────────────

VENDOR=$(command cat /sys/class/dmi/id/sys_vendor 2>/dev/null || true)
PRODUCT=$(command cat /sys/class/dmi/id/product_family 2>/dev/null || true)

if [[ "$VENDOR" != *"ASUSTeK"* ]]; then
    warn "This doesn't appear to be an ASUS machine ($VENDOR). Proceeding anyway..."
fi
info "Detected: $PRODUCT"

# ─── Install build dependencies ──────────────────────────────────────────────

info "Installing build dependencies..."
sudo apt-get update -qq
sudo apt-get install -y \
    build-essential cmake libclang-dev libudev-dev libfontconfig-dev \
    libseat-dev libxkbcommon-dev libinput-dev libgbm-dev libpipewire-0.3-dev \
    libgtk-3-dev libpango1.0-dev libgdk-pixbuf-2.0-dev libcairo2-dev \
    pkg-config git

# ─── Ensure Rust is installed ────────────────────────────────────────────────

if ! command -v cargo &>/dev/null; then
    info "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi
log "Rust available: $(rustc --version)"

# ─── Clone and build asusctl ─────────────────────────────────────────────────

BUILD_DIR="/tmp/asusctl-build"
rm -rf "$BUILD_DIR"

info "Cloning asusctl..."
git clone --depth 1 https://gitlab.com/asus-linux/asusctl.git "$BUILD_DIR"

info "Building asusctl (this may take a few minutes)..."
cd "$BUILD_DIR"
make

info "Installing asusctl..."
sudo make install

# ─── Enable and start the daemon ─────────────────────────────────────────────

info "Enabling asusd service..."
sudo systemctl daemon-reload
sudo systemctl enable --now asusd

log "asusd is running."

# ─── Clean up ────────────────────────────────────────────────────────────────

cd -
rm -rf "$BUILD_DIR"

# ─── Done ────────────────────────────────────────────────────────────────────

echo ""
log "All done! asusctl is installed."
echo ""
info "Keyboard LED commands:"
echo "  asusctl led-mode -l              # list available modes"
echo "  asusctl led-mode static          # set static color mode"
echo "  asusctl led-mode breathe         # set breathing effect"
echo "  asusctl -k low|med|high|off      # set keyboard brightness"
echo ""
info "ROG Control Center (GUI):"
echo "  rog-control-center               # launch the GUI (Wayland only)"
echo ""
info "Fan profiles:"
echo "  asusctl profile -l               # list profiles"
echo "  asusctl profile -P quiet         # set quiet profile"
echo ""
