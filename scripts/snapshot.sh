#!/usr/bin/env bash
#
# Re-capture a fresh snapshot of the current system.
# Run this whenever you install new software or change settings,
# then commit the changes to keep the repo up to date.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAPSHOTS="$(dirname "$SCRIPT_DIR")/snapshots"
CONFIGS="$(dirname "$SCRIPT_DIR")/configs"

echo "[*] Capturing system snapshot..."

# APT
apt-mark showmanual 2>/dev/null | sort > "$SNAPSHOTS/apt-manual.txt"
echo "[+] APT packages: $(wc -l < "$SNAPSHOTS/apt-manual.txt") manually installed"

# Snap
snap list 2>/dev/null | tail -n +2 | awk '{print $1}' | sort > "$SNAPSHOTS/snap-packages.txt"
echo "[+] Snap packages: $(wc -l < "$SNAPSHOTS/snap-packages.txt")"

# Flatpak
flatpak list --app --columns=application 2>/dev/null | sort > "$SNAPSHOTS/flatpak-apps.txt"
echo "[+] Flatpak apps: $(wc -l < "$SNAPSHOTS/flatpak-apps.txt")"

# VS Code extensions
if command -v code &>/dev/null; then
    code --list-extensions 2>/dev/null | sort > "$SNAPSHOTS/vscode-extensions.txt"
    echo "[+] VS Code extensions: $(wc -l < "$SNAPSHOTS/vscode-extensions.txt")"
fi

# GNOME extensions
if command -v gnome-extensions &>/dev/null; then
    gnome-extensions list 2>/dev/null | sort > "$SNAPSHOTS/gnome-extensions.txt"
    echo "[+] GNOME extensions: $(wc -l < "$SNAPSHOTS/gnome-extensions.txt")"
fi

# dconf
dconf dump / > "$SNAPSHOTS/dconf-full.ini" 2>/dev/null
echo "[+] dconf settings dumped"

# GNOME favorites
gsettings get org.gnome.shell favorite-apps > "$SNAPSHOTS/gnome-favorites.txt" 2>/dev/null
gsettings list-recursively org.gnome.desktop.interface > "$SNAPSHOTS/gnome-interface.txt" 2>/dev/null
echo "[+] GNOME settings captured"

# Configs
cp ~/.bashrc "$CONFIGS/bashrc" 2>/dev/null
cp ~/.zshrc "$CONFIGS/zshrc" 2>/dev/null
cp ~/.profile "$CONFIGS/profile" 2>/dev/null
cp ~/.config/ghostty/config "$CONFIGS/ghostty.conf" 2>/dev/null
echo "[+] Config files copied"

echo ""
echo "[*] Snapshot complete! Run 'git diff' to see what changed."
