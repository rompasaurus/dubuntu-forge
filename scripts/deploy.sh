#!/usr/bin/env bash
#
# dubuntu-forge deploy script
# Recreates the dubuntu-desktop environment on a fresh Ubuntu install.
#
# Usage:
#   chmod +x scripts/deploy.sh
#   ./scripts/deploy.sh [--all | --apt | --repos | --snaps | --flatpaks | --vscode | --gnome | --configs | --services]
#
# With no arguments, runs --all.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SNAPSHOTS="$PROJECT_DIR/snapshots"
CONFIGS="$PROJECT_DIR/configs"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[x]${NC} $*"; }
info() { echo -e "${CYAN}[*]${NC} $*"; }

banner() {
    echo ""
    echo -e "${CYAN}"
    echo "  ┌──────────────────────────────────────────┐"
    echo "  │         dubuntu-forge deployer            │"
    echo "  │    Ubuntu Desktop Environment Snapshot    │"
    echo "  │                                           │"
    echo "  │  Source: dubuntu-desktop                  │"
    echo "  │  OS:     Ubuntu 25.10 (Questing)          │"
    echo "  │  GPU:    AMD Radeon RX 9070 XT            │"
    echo "  │  Date:   2026-03-03                       │"
    echo "  └──────────────────────────────────────────┘"
    echo -e "${NC}"
}

# ─── APT Repositories ────────────────────────────────────────────────────────

setup_repos() {
    log "Setting up third-party APT repositories..."

    # Google Chrome
    if [ ! -f /etc/apt/sources.list.d/google-chrome.list ]; then
        info "Adding Google Chrome repository..."
        wget -qO- https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | \
            sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
    else
        info "Google Chrome repo already configured"
    fi

    # VS Code
    if [ ! -f /etc/apt/sources.list.d/vscode.sources ]; then
        info "Adding VS Code repository..."
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
        cat <<'VSCODE' | sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft.gpg
VSCODE
    else
        info "VS Code repo already configured"
    fi

    # Tailscale
    if [ ! -f /etc/apt/sources.list.d/tailscale.list ]; then
        info "Adding Tailscale repository..."
        curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/$(lsb_release -cs).noarmor.gpg | \
            sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg > /dev/null
        echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu $(lsb_release -cs) main" | \
            sudo tee /etc/apt/sources.list.d/tailscale.list > /dev/null
    else
        info "Tailscale repo already configured"
    fi

    # GitHub Desktop (shiftkey)
    if [ ! -f /etc/apt/sources.list.d/shiftkey-packages.list ]; then
        info "Adding GitHub Desktop (shiftkey) repository..."
        wget -qO- https://apt.packages.shiftkey.dev/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/shiftkey-packages.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/shiftkey-packages.gpg] https://apt.packages.shiftkey.dev/ubuntu/ any main" | \
            sudo tee /etc/apt/sources.list.d/shiftkey-packages.list > /dev/null
    else
        info "GitHub Desktop repo already configured"
    fi

    # Steam
    if [ ! -f /etc/apt/sources.list.d/steam-stable.list ]; then
        info "Adding Steam repository..."
        # Steam usually sets itself up via the .deb, so just note it
        warn "Steam repo is typically added by installing steam-launcher. Install it manually if needed."
    else
        info "Steam repo already configured"
    fi

    sudo apt update
    log "Repositories configured."
}

# ─── APT Packages ────────────────────────────────────────────────────────────

install_apt() {
    log "Installing APT packages (manually-installed subset)..."

    # These are the key user-selected packages (filtering out base system noise)
    local KEY_PACKAGES=(
        code
        dotnet-sdk-10.0
        flatpak
        google-chrome-stable
        nodejs
        npm
        openssh-server
        python3-evdev
        steam-launcher
        tailscale
        ubuntu-desktop
        ubuntu-restricted-addons
        xrdp
    )

    info "Installing ${#KEY_PACKAGES[@]} key packages..."
    sudo apt install -y "${KEY_PACKAGES[@]}" || warn "Some packages may have failed — check output above."

    log "APT packages installed."
}

# ─── Snap Packages ───────────────────────────────────────────────────────────

install_snaps() {
    log "Installing Snap packages..."

    # Classic snaps (need --classic flag)
    local CLASSIC_SNAPS=(ghostty obsidian)
    # Standard snaps
    local STANDARD_SNAPS=(discord firefox remmina spotify thunderbird whatsapp-linux-desktop)

    for snap in "${CLASSIC_SNAPS[@]}"; do
        if snap list "$snap" &>/dev/null; then
            info "$snap already installed"
        else
            info "Installing $snap (classic)..."
            sudo snap install "$snap" --classic || warn "Failed to install $snap"
        fi
    done

    for snap in "${STANDARD_SNAPS[@]}"; do
        if snap list "$snap" &>/dev/null; then
            info "$snap already installed"
        else
            info "Installing $snap..."
            sudo snap install "$snap" || warn "Failed to install $snap"
        fi
    done

    log "Snap packages installed."
}

# ─── Flatpak Apps ────────────────────────────────────────────────────────────

install_flatpaks() {
    log "Installing Flatpak apps..."

    # Ensure Flathub is added
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    local FLATPAK_APPS=(
        com.github.eneshecan.WhatsAppForLinux
    )

    for app in "${FLATPAK_APPS[@]}"; do
        if flatpak list --app | grep -q "$app"; then
            info "$app already installed"
        else
            info "Installing $app..."
            flatpak install -y flathub "$app" || warn "Failed to install $app"
        fi
    done

    log "Flatpak apps installed."
}

# ─── VS Code Extensions ─────────────────────────────────────────────────────

install_vscode_extensions() {
    log "Installing VS Code extensions..."

    if ! command -v code &>/dev/null; then
        err "VS Code not found. Install it first."
        return 1
    fi

    local EXTENSIONS=(
        alefragnani.project-manager
        anthropic.claude-code
        dbaeumer.vscode-eslint
        eamodio.gitlens
        esbenp.prettier-vscode
        kilocode.kilo-code
        ms-dotnettools.csdevkit
        ms-dotnettools.csharp
        ms-dotnettools.vscode-dotnet-runtime
        ms-playwright.playwright
        ms-python.debugpy
        ms-python.python
        ms-python.vscode-pylance
        ms-python.vscode-python-envs
    )

    for ext in "${EXTENSIONS[@]}"; do
        info "Installing extension: $ext"
        code --install-extension "$ext" --force 2>/dev/null || warn "Failed to install $ext"
    done

    log "VS Code extensions installed."
}

# ─── GNOME Settings ──────────────────────────────────────────────────────────

apply_gnome_settings() {
    log "Applying GNOME desktop settings..."

    # Theme & appearance
    gsettings set org.gnome.desktop.interface gtk-theme 'Greybird'
    gsettings set org.gnome.desktop.interface icon-theme 'elementary-xfce-dark'
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface font-name 'Sans 10'

    # Dock favorites
    gsettings set org.gnome.shell favorite-apps "['google-chrome.desktop', 'code.desktop', 'firefox_firefox.desktop', 'thunderbird_thunderbird.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Rhythmbox3.desktop', 'libreoffice-writer.desktop', 'snap-store_snap-store.desktop', 'org.gnome.Yelp.desktop', 'org.gnome.Ptyxis.desktop', 'ghostty_ghostty.desktop', 'discord_discord.desktop', 'org.remmina.Remmina.desktop', 'steam.desktop', 'spotify_spotify.desktop', 'com.github.eneshecan.WhatsAppForLinux.desktop']"

    # Keyboard layout
    gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us')]"

    log "GNOME settings applied."

    # Optionally load full dconf dump
    if [ -f "$SNAPSHOTS/dconf-full.ini" ]; then
        warn "Full dconf snapshot available at snapshots/dconf-full.ini"
        warn "To apply ALL settings: dconf load / < snapshots/dconf-full.ini"
        warn "This overwrites everything — use with caution."
    fi
}

# ─── Config Files ────────────────────────────────────────────────────────────

deploy_configs() {
    log "Deploying config files..."

    # bashrc
    if [ -f "$CONFIGS/bashrc" ]; then
        cp "$CONFIGS/bashrc" ~/.bashrc
        info "Deployed .bashrc"
    fi

    # profile
    if [ -f "$CONFIGS/profile" ]; then
        cp "$CONFIGS/profile" ~/.profile
        info "Deployed .profile"
    fi

    # Ghostty
    if [ -f "$CONFIGS/ghostty.conf" ]; then
        mkdir -p ~/.config/ghostty
        cp "$CONFIGS/ghostty.conf" ~/.config/ghostty/config
        info "Deployed ghostty config"
    fi

    # environment.d
    if [ -f "$CONFIGS/environment.d-default.conf" ]; then
        mkdir -p ~/.config/environment.d
        cp "$CONFIGS/environment.d-default.conf" ~/.config/environment.d/default.conf
        info "Deployed environment.d config"
    fi

    # Monitor layout (informational — hardware-specific)
    if [ -f "$CONFIGS/monitors.xml" ]; then
        warn "Monitor config saved but NOT auto-deployed (hardware-specific)."
        warn "To apply: cp configs/monitors.xml ~/.config/monitors.xml"
    fi

    log "Configs deployed."
}

# ─── Services ────────────────────────────────────────────────────────────────

enable_services() {
    log "Enabling system services..."

    # xrdp for remote desktop
    sudo systemctl enable --now xrdp 2>/dev/null && info "xrdp enabled" || warn "xrdp not available"

    # Tailscale
    sudo systemctl enable --now tailscaled 2>/dev/null && info "tailscaled enabled" || warn "tailscaled not available"

    # SSH
    sudo systemctl enable --now ssh 2>/dev/null && info "ssh enabled" || warn "ssh not available"

    log "Services configured."
}

# ─── Claude Code ─────────────────────────────────────────────────────────────

install_claude_code() {
    log "Installing Claude Code..."

    if command -v claude &>/dev/null; then
        info "Claude Code already installed"
    else
        if command -v npm &>/dev/null; then
            sudo npm install -g @anthropic-ai/claude-code
            info "Claude Code installed globally via npm"
        else
            err "npm not found. Install Node.js/npm first."
            return 1
        fi
    fi

    # Deploy Claude settings
    mkdir -p ~/.claude
    cat > ~/.claude/settings.json << 'CLAUDE_SETTINGS'
{
  "skipDangerousModePermissionPrompt": true
}
CLAUDE_SETTINGS
    info "Claude Code settings deployed"

    log "Claude Code ready."
}

# ─── Main ────────────────────────────────────────────────────────────────────

run_all() {
    setup_repos
    install_apt
    install_snaps
    install_flatpaks
    install_vscode_extensions
    apply_gnome_settings
    deploy_configs
    enable_services
    install_claude_code

    echo ""
    log "All done! You may want to:"
    info "  1. Run 'tailscale up' to join your tailnet"
    info "  2. Generate SSH keys: ssh-keygen -t ed25519"
    info "  3. Log out and back in for all settings to take effect"
    info "  4. Review snapshots/dconf-full.ini for any missed GNOME tweaks"
    echo ""
}

# Parse arguments
if [ $# -eq 0 ]; then
    banner
    run_all
    exit 0
fi

banner

for arg in "$@"; do
    case "$arg" in
        --all)       run_all ;;
        --repos)     setup_repos ;;
        --apt)       install_apt ;;
        --snaps)     install_snaps ;;
        --flatpaks)  install_flatpaks ;;
        --vscode)    install_vscode_extensions ;;
        --gnome)     apply_gnome_settings ;;
        --configs)   deploy_configs ;;
        --services)  enable_services ;;
        --claude)    install_claude_code ;;
        --help|-h)
            echo "Usage: $0 [--all | --repos | --apt | --snaps | --flatpaks | --vscode | --gnome | --configs | --services | --claude]"
            echo "  No arguments = --all"
            ;;
        *)
            err "Unknown option: $arg"
            exit 1
            ;;
    esac
done
