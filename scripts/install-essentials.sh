#!/usr/bin/env bash
#
# Install the essential CLI tools needed for the zshrc integration block.
# Run with: bash scripts/install-essentials.sh
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
echo "  ┌──────────────────────────────────────────┐"
echo "  │   Install Essential CLI Tools for zshrc   │"
echo "  └──────────────────────────────────────────┘"
echo -e "${NC}"

# ─── APT packages ────────────────────────────────────────────────────────────

info "Installing APT packages (will prompt for sudo password)..."
sudo apt update
sudo apt install -y \
    curl \
    zoxide bat eza fd-find ripgrep fzf direnv btop duf trash-cli \
    zsh pipx

log "APT packages installed."

# ─── Oh My Zsh + plugins ──────────────────────────────────────────────────────

if [ -d "$HOME/.oh-my-zsh" ]; then
    log "Oh My Zsh already installed"
else
    info "Installing Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    log "Oh My Zsh installed."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    log "zsh-autosuggestions plugin already installed"
else
    info "Installing zsh-autosuggestions plugin..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    log "zsh-autosuggestions installed."
fi

# ─── Ubuntu compatibility symlinks ───────────────────────────────────────────

info "Creating symlinks (bat -> batcat, fd -> fdfind)..."
mkdir -p ~/.local/bin
ln -sf /usr/bin/batcat ~/.local/bin/bat 2>/dev/null || true
ln -sf /usr/bin/fdfind ~/.local/bin/fd 2>/dev/null || true
log "Symlinks created."

# ─── Starship prompt ─────────────────────────────────────────────────────────

if command -v starship &>/dev/null; then
    log "starship already installed"
else
    info "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# ─── mise (version manager) ─────────────────────────────────────────────────

if command -v mise &>/dev/null; then
    log "mise already installed"
else
    info "Installing mise..."
    curl https://mise.run | sh
    # Add to PATH for this session
    export PATH="$HOME/.local/bin:$PATH"
fi

# ─── thefuck (command corrector) ─────────────────────────────────────────────

if command -v thefuck &>/dev/null; then
    log "thefuck already installed"
else
    info "Installing thefuck via pipx..."
    pipx ensurepath
    pipx install thefuck
fi

# ─── Rust (needed for cargo tools) ────────────────────────────────────────────

if ! command -v cargo &>/dev/null; then
    info "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# ─── Cargo tools (dust, tre) ─────────────────────────────────────────────────

if command -v cargo &>/dev/null; then
    info "Installing cargo tools (dust, tre)..."
    cargo install du-dust tre-command 2>/dev/null || warn "Some cargo installs may have failed"
    log "Cargo tools installed."
else
    warn "Rust/cargo not found — skipping dust and tre."
fi

# ─── Go (needed for Go tools) ────────────────────────────────────────────────

if ! command -v go &>/dev/null; then
    info "Installing Go via snap..."
    sudo snap install go --classic
fi

export PATH="$HOME/go/bin:$PATH"

# ─── Go tools (doggo, lazydocker) ────────────────────────────────────────────

if command -v go &>/dev/null; then
    info "Installing Go tools (doggo, lazydocker)..."
    go install github.com/mr-karan/doggo/cmd/doggo@latest 2>/dev/null || warn "doggo install failed"
    go install github.com/jesseduffield/lazydocker@latest 2>/dev/null || warn "lazydocker install failed"
    log "Go tools installed."
else
    warn "Go not found — skipping doggo and lazydocker."
fi

# ─── lazygit ──────────────────────────────────────────────────────────────────

if command -v lazygit &>/dev/null; then
    log "lazygit already installed"
else
    info "Installing lazygit..."
    if command -v go &>/dev/null; then
        go install github.com/jesseduffield/lazygit@latest 2>/dev/null || warn "lazygit install failed"
    else
        warn "Go not found — skipping lazygit."
    fi
fi

# ─── Verify ──────────────────────────────────────────────────────────────────

echo ""
info "Verification:"
for cmd in zoxide fzf starship direnv mise thefuck bat eza fd dust duf rg tre btop doggo lazygit lazydocker; do
    if command -v "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $cmd"
    else
        echo -e "  ${YELLOW}✗${NC} $cmd (not found)"
    fi
done

echo ""
log "Done! Now run:"
info "  exec zsh"
echo ""
