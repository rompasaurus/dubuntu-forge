#!/usr/bin/env bash
#
# Install and enable the Tiling Shell GNOME extension.
# Provides Windows 11-style snap layouts and tiling for GNOME.
#
# Run with: bash scripts/setup-tiling-shell.sh
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
echo "  ┌─────────────────────────────────────┐"
echo "  │   Tiling Shell – GNOME Extension     │"
echo "  └─────────────────────────────────────┘"
echo -e "${NC}"

# ─── Install gext (gnome-extensions-cli) ──────────────────────────────────────

if ! command -v gext &>/dev/null; then
    info "Installing gnome-extensions-cli..."
    pipx install gnome-extensions-cli --system-site-packages
    export PATH="$HOME/.local/bin:$PATH"
fi
log "gext available."

# ─── Install Tiling Shell ────────────────────────────────────────────────────

EXT_ID="tilingshell@ferrarodomenico.com"

if gnome-extensions list | grep -q "$EXT_ID"; then
    log "$EXT_ID already installed"
else
    info "Installing $EXT_ID..."
    gext install "$EXT_ID"
fi

gnome-extensions enable "$EXT_ID" 2>/dev/null || true
log "Tiling Shell enabled."

echo ""
log "Done! Tiling Shell is active."
info "Hover over the maximize button to see snap layouts."
info "Tweak settings in: Extensions app > Tiling Shell"
echo ""
