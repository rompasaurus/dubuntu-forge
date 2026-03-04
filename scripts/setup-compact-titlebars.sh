#!/usr/bin/env bash
#
# Configure GTK title bar compactness (GTK3 + GTK4).
# Run with: bash scripts/setup-compact-titlebars.sh
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
echo "  │       Compact Title Bars Setup            │"
echo "  └──────────────────────────────────────────┘"
echo -e "${NC}"

echo "  Select title bar compactness:"
echo ""
echo "  1) Default     — restore stock title bars"
echo "  2) Subtle      — slightly smaller padding and text"
echo "  3) Compact     — noticeably thinner bars with smaller text"
echo "  4) Ultra       — minimal padding, smallest text, max screen space"
echo ""
read -rp "  Choice [1-4]: " choice

case "$choice" in
    1)
        CSS=""
        LABEL="Default (stock)"
        ;;
    2)
        CSS=$(cat <<'CSS'
/* Subtle title bars */
headerbar {
    min-height: 34px;
    padding: 3px 6px;
}

headerbar .title {
    font-size: 0.9em;
}

headerbar button {
    min-height: 26px;
    min-width: 26px;
    padding: 3px 6px;
}

.titlebar {
    min-height: 34px;
    padding: 3px 6px;
}

.titlebar .title {
    font-size: 0.9em;
}
CSS
        )
        LABEL="Subtle"
        ;;
    3)
        CSS=$(cat <<'CSS'
/* Compact title bars */
headerbar {
    min-height: 28px;
    padding: 2px 4px;
}

headerbar .title {
    font-size: 0.85em;
}

headerbar button {
    min-height: 22px;
    min-width: 22px;
    padding: 2px 4px;
}

.titlebar {
    min-height: 28px;
    padding: 2px 4px;
}

.titlebar .title {
    font-size: 0.85em;
}
CSS
        )
        LABEL="Compact"
        ;;
    4)
        CSS=$(cat <<'CSS'
/* Ultra compact title bars */
headerbar {
    min-height: 20px;
    padding: 0px 2px;
}

headerbar .title {
    font-size: 0.75em;
}

headerbar button {
    min-height: 16px;
    min-width: 16px;
    padding: 0px 2px;
    margin: 0px;
}

.titlebar {
    min-height: 20px;
    padding: 0px 2px;
}

.titlebar .title {
    font-size: 0.75em;
}
CSS
        )
        LABEL="Ultra compact"
        ;;
    *)
        warn "Invalid choice. Exiting."
        exit 1
        ;;
esac

# ─── Apply CSS ───────────────────────────────────────────────────────────────

mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

for dir in "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"; do
    echo "$CSS" > "$dir/gtk.css"
done

if [ -z "$CSS" ]; then
    log "Title bars reset to default."
else
    log "Title bars set to: $LABEL"
fi

info "Close and reopen apps to see the change."
