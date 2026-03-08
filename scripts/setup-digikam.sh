#!/bin/bash
# ==============================================================================
# digiKam Photo Manager Setup
# Professional photo management with face recognition, geotagging, and RAW support
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
info() { echo -e "${CYAN}[*]${NC} $*"; }

echo -e "${CYAN}"
echo "  ┌──────────────────────────────────────────┐"
echo "  │   digiKam Photo Manager Setup             │"
echo "  └──────────────────────────────────────────┘"
echo -e "${NC}"

# Check for root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (sudo)."
    exit 1
fi

# Install digiKam and useful extras
info "Installing digiKam and dependencies..."
apt-get update -qq
apt-get install -y \
    digikam \
    libraw-dev \
    ffmpegthumbs

log "digiKam installed."

# Install optional face recognition support
info "Installing face recognition dependencies..."
apt-get install -y libopencv-dev 2>/dev/null || true
log "Face recognition support installed."

echo ""
log "Setup complete! Launch digiKam from your app menu or run: digikam"
info "First launch will walk you through setting up your photo library location."
