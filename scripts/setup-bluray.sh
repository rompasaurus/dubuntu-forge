#!/bin/bash
# Setup Blu-ray playback support for VLC on Ubuntu
# Includes MakeMKV as fallback for DRM-protected discs
# Creates a pinnable Blu-Ray Player launcher with custom icon

set -e

echo "=== Installing VLC and Blu-ray libraries ==="
sudo apt update
sudo apt install -y vlc libaacs0 libbdplus0 libbluray-bdj openjdk-21-jre

echo "=== Installing decryption keys ==="
mkdir -p ~/.config/aacs

KEYDB_INSTALLED=false

# Try primary source
echo "Trying primary KEYDB source..."
if wget -q --timeout=10 -O ~/.config/aacs/KEYDB.cfg "https://vlc-bluray.whoknowsmy.name/files/KEYDB.cfg" 2>/dev/null; then
    echo "KEYDB installed from primary source."
    KEYDB_INSTALLED=true
fi

# Try git repo fallback
if [ "$KEYDB_INSTALLED" = false ]; then
    echo "Primary source failed. Trying git repo..."
    if git clone --depth 1 https://github.com/psr/libaacs-keys.git /tmp/libaacs-keys 2>/dev/null; then
        cp /tmp/libaacs-keys/KEYDB.cfg ~/.config/aacs/KEYDB.cfg
        rm -rf /tmp/libaacs-keys
        echo "KEYDB installed from git repo."
        KEYDB_INSTALLED=true
    fi
fi

if [ "$KEYDB_INSTALLED" = false ]; then
    echo "WARNING: Could not download KEYDB.cfg. VLC may not play encrypted discs."
    echo "MakeMKV (installed below) will handle playback instead."
fi

echo ""
echo "=== Installing MakeMKV ==="
sudo add-apt-repository -y ppa:heyarje/makemkv-beta
sudo apt update
sudo apt install -y makemkv-bin makemkv-oss

echo ""
echo "=== Creating Blu-Ray Player launcher ==="

# Create icon
mkdir -p ~/.local/share/icons
cat > ~/.local/share/icons/bluray-player.svg << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <circle cx="64" cy="64" r="60" fill="#1a1a2e"/>
  <circle cx="64" cy="64" r="58" fill="url(#discGrad)" stroke="#0077cc" stroke-width="1.5"/>
  <circle cx="64" cy="64" r="48" fill="none" stroke="#0055aa" stroke-width="0.5" opacity="0.4"/>
  <circle cx="64" cy="64" r="40" fill="none" stroke="#0055aa" stroke-width="0.5" opacity="0.3"/>
  <circle cx="64" cy="64" r="32" fill="none" stroke="#0055aa" stroke-width="0.5" opacity="0.3"/>
  <ellipse cx="45" cy="40" rx="30" ry="20" fill="url(#shine)" opacity="0.15"/>
  <circle cx="64" cy="64" r="12" fill="#111"/>
  <circle cx="64" cy="64" r="10" fill="#222" stroke="#0077cc" stroke-width="1"/>
  <circle cx="64" cy="64" r="6" fill="#0a0a15"/>
  <text x="64" y="84" text-anchor="middle" font-family="Arial, sans-serif" font-weight="bold" font-size="11" fill="#00aaff" opacity="0.9">BLU-RAY</text>
  <polygon points="58,50 58,38 70,44" fill="#00aaff" opacity="0.8"/>
  <defs>
    <radialGradient id="discGrad" cx="40%" cy="35%">
      <stop offset="0%" stop-color="#1a3a5c"/>
      <stop offset="50%" stop-color="#0d1b2a"/>
      <stop offset="100%" stop-color="#1a1a2e"/>
    </radialGradient>
    <radialGradient id="shine" cx="50%" cy="50%">
      <stop offset="0%" stop-color="#66bbff"/>
      <stop offset="100%" stop-color="#66bbff" stop-opacity="0"/>
    </radialGradient>
  </defs>
</svg>
SVGEOF

# Create desktop launcher
cat > ~/.local/share/applications/bluray-player.desktop << DESKEOF
[Desktop Entry]
Name=Blu-Ray Player
Comment=Play Blu-Ray disc with VLC
Exec=vlc bluray:///dev/sr0
Icon=$HOME/.local/share/icons/bluray-player.svg
Terminal=false
Type=Application
Categories=AudioVideo;Video;Player;
Keywords=bluray;blu-ray;disc;movie;
StartupWMClass=vlc
StartupNotify=true
DESKEOF

update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

echo "Launcher created! Search 'Blu-Ray Player' in Activities and pin to dash."

echo ""
echo "=== Done! ==="
echo ""
echo "To play a Blu-ray disc:"
echo "  1. Click the Blu-Ray Player icon in your dash"
echo "  2. Or run: vlc bluray:///dev/sr0"
echo "  3. Or use MakeMKV for DRM-heavy discs"
echo ""
echo "If VLC fails, open MakeMKV first (handles DRM decryption),"
echo "then try VLC again via Media → Open Disc → Blu-ray."
