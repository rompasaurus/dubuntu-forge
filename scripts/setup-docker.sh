#!/usr/bin/env bash
#
# Install Docker Engine + Docker Desktop (GUI) on Ubuntu.
# Run with: bash scripts/setup-docker.sh
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
echo "  ┌────────────────────────────────────────────┐"
echo "  │   Docker Engine + Docker Desktop Installer  │"
echo "  └────────────────────────────────────────────┘"
echo -e "${NC}"

# ─── Pre-flight checks ───────────────────────────────────────────────────────

if command -v docker &>/dev/null; then
    warn "Docker is already installed: $(docker --version)"
    warn "Skipping engine install."
    ENGINE_INSTALLED=true
else
    ENGINE_INSTALLED=false
fi

# ─── Install Docker Engine ────────────────────────────────────────────────────

if [ "$ENGINE_INSTALLED" = false ]; then
    info "Installing prerequisites..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq ca-certificates curl gnupg

    info "Adding Docker GPG key..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Docker may not have a repo for the current Ubuntu codename yet.
    # Try the current codename first, fall back to the nearest supported one.
    CODENAME=$(. /etc/os-release && echo "${VERSION_CODENAME:-}")
    FALLBACK_CODENAME="noble"

    info "Setting up Docker apt repository..."
    REPO_URL="https://download.docker.com/linux/ubuntu"
    if curl -fsSL "${REPO_URL}/dists/${CODENAME}/Release" &>/dev/null; then
        DOCKER_CODENAME="$CODENAME"
    else
        warn "No Docker repo for '${CODENAME}', falling back to '${FALLBACK_CODENAME}'."
        DOCKER_CODENAME="$FALLBACK_CODENAME"
    fi

    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] ${REPO_URL} ${DOCKER_CODENAME} stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    info "Installing Docker Engine..."
    sudo apt-get update -qq
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin

    log "Docker Engine installed: $(docker --version)"
fi

# ─── Add user to docker group ─────────────────────────────────────────────────

if ! groups "$USER" | grep -qw docker; then
    info "Adding $USER to the docker group..."
    sudo usermod -aG docker "$USER"
    warn "You'll need to log out and back in for group changes to take effect."
else
    log "$USER is already in the docker group."
fi

# ─── Install Docker Desktop ──────────────────────────────────────────────────

if command -v /opt/docker-desktop/bin/com.docker.backend &>/dev/null || \
   dpkg -l docker-desktop &>/dev/null 2>&1; then
    warn "Docker Desktop is already installed. Skipping."
else
    DEB="/tmp/docker-desktop-amd64.deb"
    info "Downloading Docker Desktop..."
    curl -fsSL -o "$DEB" "https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb"

    info "Installing Docker Desktop..."
    sudo apt-get install -y "$DEB"
    rm -f "$DEB"

    log "Docker Desktop installed."
fi

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
log "All done! Next steps:"
echo "  1. Log out and back in (for docker group permissions)"
echo "  2. Launch Docker Desktop from your app menu or run:"
echo "     systemctl --user start docker-desktop"
