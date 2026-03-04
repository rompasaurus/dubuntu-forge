#!/usr/bin/env bash
#
# Hide the GNOME top panel and window title bars when windows are maximized.
# Installs and configures:
#   - Hide Top Bar (auto-hides the GNOME top panel)
#   - Unite       (removes window title bars when maximized)
#
# Run with: bash scripts/setup-hide-topbar.sh
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
echo "  ┌───────────────────────────────────────────────────┐"
echo "  │   Hide Top Panel & Title Bars (Maximized Windows) │"
echo "  └───────────────────────────────────────────────────┘"
echo -e "${NC}"

# ─── Install gext (gnome-extensions-cli) ──────────────────────────────────────

if ! command -v gext &>/dev/null; then
    info "Installing gnome-extensions-cli..."
    pipx install gnome-extensions-cli --system-site-packages
    export PATH="$HOME/.local/bin:$PATH"
fi
log "gext available."

# ─── Install extensions ───────────────────────────────────────────────────────

HIDE_TOP_BAR="hidetopbar@mathieu.biber.org"
UNITE="unite@hardpixel.eu"

for ext in "$HIDE_TOP_BAR" "$UNITE"; do
    if gnome-extensions list | grep -q "$ext"; then
        log "$ext already installed"
    else
        info "Installing $ext..."
        gext install "$ext"
    fi
    gnome-extensions enable "$ext" 2>/dev/null || true
done

# ─── Configure Hide Top Bar ──────────────────────────────────────────────────

SCHEMA_HTB="org.gnome.shell.extensions.hidetopbar"

# Hide when a window is maximized or near the top
gsettings set "$SCHEMA_HTB" mouse-sensitive true
gsettings set "$SCHEMA_HTB" enable-intellihide true
gsettings set "$SCHEMA_HTB" enable-active-window true

log "Hide Top Bar configured."

# ─── Configure Unite ──────────────────────────────────────────────────────────

SCHEMA_UNITE="org.gnome.shell.extensions.unite"

# Hide window title bar when maximized
gsettings set "$SCHEMA_UNITE" hide-window-titlebars "maximized"
# Move window buttons to the top panel
gsettings set "$SCHEMA_UNITE" show-window-buttons "maximized"
# Show window title in the top panel
gsettings set "$SCHEMA_UNITE" show-window-title "maximized"

log "Unite configured."

echo ""
log "Done! Both extensions are active."
info "The top panel will auto-hide and title bars will be removed on maximized windows."
info "You can tweak settings in: Extensions app > Hide Top Bar / Unite"
echo ""
