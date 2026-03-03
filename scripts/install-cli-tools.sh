#!/usr/bin/env bash
#
# Install essential CLI tools for Ubuntu
# Part of dubuntu-forge — see CLI-UserGuide.md for usage docs
#
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
info() { echo -e "${CYAN}[*]${NC} $*"; }

echo -e "${CYAN}"
echo "  ┌──────────────────────────────────────────┐"
echo "  │     dubuntu-forge CLI Tools Installer     │"
echo "  │         100+ terminal power tools         │"
echo "  └──────────────────────────────────────────┘"
echo -e "${NC}"

# ─── APT Packages ────────────────────────────────────────────────────────────

info "Installing APT packages..."
sudo apt update && sudo apt install -y \
    bat eza fd-find ripgrep fzf zoxide \
    htop btop ncdu duf \
    git-delta hexyl \
    mc ranger nnn tig \
    jq pandoc miller \
    tmux micro kakoune \
    entr direnv \
    age pass trash-cli moreutils pv \
    asciinema figlet lolcat cmatrix \
    nvtop iotop iftop nethogs bmon vnstat \
    fastfetch inxi tealdeer glow \
    powertop lynis aria2 \
    pipx
log "APT packages installed."

# ─── Symlinks (Ubuntu renames some tools) ────────────────────────────────────

info "Creating compatibility symlinks..."
mkdir -p ~/.local/bin
ln -sf /usr/bin/batcat ~/.local/bin/bat 2>/dev/null || true
ln -sf /usr/bin/fdfind ~/.local/bin/fd 2>/dev/null || true
log "Symlinks created."

# ─── Rust tools ──────────────────────────────────────────────────────────────

if command -v cargo &>/dev/null; then
    info "Installing Rust tools via cargo (this may take a while)..."
    cargo install --locked \
        yazi-fm yazi-cli \
        du-dust sd choose \
        tre-command \
        bottom \
        procs \
        broot \
        xplr \
        watchexec-cli \
        just \
        grex \
        git-absorb \
        gitui \
        silicon \
        hyperfine \
        tokei \
        zellij \
        xh \
        jless \
        gping \
        bandwhich \
        trippy
    log "Rust tools installed."

    # Initialize broot shell function
    broot --install 2>/dev/null || true
else
    warn "Rust/cargo not found. Install with: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
fi

# ─── Go tools ────────────────────────────────────────────────────────────────

if command -v go &>/dev/null; then
    info "Installing Go tools..."
    go install github.com/jesseduffield/lazygit@latest
    go install github.com/jesseduffield/lazydocker@latest
    go install github.com/mr-karan/doggo/cmd/doggo@latest
    go install github.com/charmbracelet/gum@latest
    go install github.com/charmbracelet/vhs@latest
    go install github.com/schollz/croc/v10@latest
    go install github.com/knqyf263/pet@latest
    go install github.com/stern/stern@latest
    go install github.com/antonmedv/fx@latest
    go install github.com/ericchiang/pup@latest
    go install github.com/boyter/scc/v3@latest
    go install github.com/dundee/gdu/v5/cmd/gdu@latest
    go install github.com/yorukot/superfile@latest
    go install github.com/gcla/termshark/v2/cmd/termshark@latest
    log "Go tools installed."
else
    warn "Go not found. Install with: sudo snap install go --classic"
fi

# ─── Python tools ────────────────────────────────────────────────────────────

if command -v pipx &>/dev/null; then
    pipx ensurepath
    info "Installing Python tools via pipx..."
    pipx install glances 2>/dev/null || true
    pipx install s-tui 2>/dev/null || true
    pipx install commitizen 2>/dev/null || true
    pipx install posting 2>/dev/null || true
    pipx install thefuck 2>/dev/null || true
    pipx install magic-wormhole 2>/dev/null || true
    log "Python tools installed."
else
    warn "pipx not found. Run: sudo apt install pipx && pipx ensurepath"
fi

# ─── Standalone installs ─────────────────────────────────────────────────────

info "Installing starship prompt..."
curl -sS https://starship.rs/install.sh | sh -s -- -y 2>/dev/null || warn "Starship install failed"

info "Installing atuin shell history..."
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh 2>/dev/null || warn "Atuin install failed"

info "Updating tldr pages..."
tldr --update 2>/dev/null || true

# ─── Done ────────────────────────────────────────────────────────────────────

echo ""
log "All tools installed!"
echo ""
info "Next steps:"
info "  1. Add the shell integration block to your ~/.bashrc"
info "     (see CLI-UserGuide.md section 15)"
info "  2. Restart your shell: exec bash"
info "  3. Run 'atuin import auto' to import shell history"
info "  4. Run 'broot --install' if not done automatically"
echo ""
