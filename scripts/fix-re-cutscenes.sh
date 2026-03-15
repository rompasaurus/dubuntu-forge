#!/usr/bin/env bash
# Fix Resident Evil cutscene playback on Linux (Steam/Proton)
#
# Problem: RE games use Windows Media Foundation (WMF) for cutscene video.
# Valve's Proton cannot legally ship these codecs, so cutscenes show as
# black screens, color bars, or cause freezes.
#
# Solution:
#   - RE Engine games (RE7, RE2R, RE3R, Village, RE4R): Use GE-Proton which
#     includes the necessary media foundation patches
#   - Older RE games (RE0/1 HD, RE5, RE6, Revelations): Install WMP11 via
#     protontricks into the game's Wine prefix

set -euo pipefail

STEAM_ROOT="$HOME/.steam/steam"
STEAM_APPS="$STEAM_ROOT/steamapps"
COMPAT_TOOLS="$STEAM_ROOT/compatibilitytools.d"

# RE Engine games (use GE-Proton)
declare -A RE_ENGINE_GAMES=(
    [418370]="Resident Evil 7: Biohazard"
    [883710]="Resident Evil 2 Remake"
    [952060]="Resident Evil 3 Remake"
    [1196590]="Resident Evil Village"
    [2050650]="Resident Evil 4 Remake"
)

# Older RE games (use protontricks wmp11)
declare -A RE_LEGACY_GAMES=(
    [304240]="Resident Evil HD Remaster"
    [339340]="Resident Evil 0 HD Remaster"
    [21690]="Resident Evil 5"
    [221040]="Resident Evil 6"
    [222480]="Resident Evil Revelations"
    [287290]="Resident Evil Revelations 2"
)

echo "=== Resident Evil Cutscene Fix ==="
echo ""

# -----------------------------------------------
# Step 1: Detect installed RE games
# -----------------------------------------------
echo "[*] Scanning for installed Resident Evil games..."
FOUND_ENGINE=()
FOUND_LEGACY=()

for appid in "${!RE_ENGINE_GAMES[@]}"; do
    if [ -f "$STEAM_APPS/appmanifest_${appid}.acf" ]; then
        echo "    Found: ${RE_ENGINE_GAMES[$appid]} (AppID: $appid) [RE Engine]"
        FOUND_ENGINE+=("$appid")
    fi
done

for appid in "${!RE_LEGACY_GAMES[@]}"; do
    if [ -f "$STEAM_APPS/appmanifest_${appid}.acf" ]; then
        echo "    Found: ${RE_LEGACY_GAMES[$appid]} (AppID: $appid) [Legacy]"
        FOUND_LEGACY+=("$appid")
    fi
done

if [ ${#FOUND_ENGINE[@]} -eq 0 ] && [ ${#FOUND_LEGACY[@]} -eq 0 ]; then
    echo "    No Resident Evil games found in Steam library."
    echo "    If games are installed on a different drive, set STEAM_ROOT before running."
    exit 0
fi
echo ""

# -----------------------------------------------
# Step 2: Install GE-Proton (for RE Engine games)
# -----------------------------------------------
install_ge_proton() {
    echo "[*] Installing GE-Proton..."

    # Find latest GE-Proton release
    echo "    Fetching latest release from GitHub..."
    LATEST_URL=$(curl -sL "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest" \
        | grep -o '"browser_download_url": *"[^"]*\.tar\.gz"' \
        | head -1 \
        | cut -d'"' -f4)

    if [ -z "$LATEST_URL" ]; then
        echo "    ERROR: Could not fetch latest GE-Proton release."
        echo "    Install manually from: https://github.com/GloriousEggroll/proton-ge-custom/releases"
        return 1
    fi

    GE_FILENAME=$(basename "$LATEST_URL" .tar.gz)
    echo "    Latest version: $GE_FILENAME"

    # Check if already installed
    if [ -d "$COMPAT_TOOLS/$GE_FILENAME" ]; then
        echo "[✓] $GE_FILENAME is already installed"
        return 0
    fi

    mkdir -p "$COMPAT_TOOLS"
    TMPFILE=$(mktemp --suffix=.tar.gz)

    echo "    Downloading..."
    curl -L --progress-bar "$LATEST_URL" -o "$TMPFILE"

    echo "    Extracting to $COMPAT_TOOLS..."
    tar -xf "$TMPFILE" -C "$COMPAT_TOOLS"
    rm -f "$TMPFILE"

    echo "[✓] $GE_FILENAME installed"
    echo ""
    echo "    >>> IMPORTANT: Restart Steam for GE-Proton to appear. <<<"
    echo "    Then for each RE Engine game:"
    echo "      Right-click > Properties > Compatibility"
    echo "      > Force use: $GE_FILENAME"
}

if [ ${#FOUND_ENGINE[@]} -gt 0 ]; then
    echo "--- RE Engine Games (need GE-Proton) ---"

    # Check if any GE-Proton is already installed
    GE_INSTALLED=""
    if [ -d "$COMPAT_TOOLS" ]; then
        GE_INSTALLED=$(ls -d "$COMPAT_TOOLS"/GE-Proton* 2>/dev/null | tail -1 || true)
    fi

    if [ -n "$GE_INSTALLED" ]; then
        GE_NAME=$(basename "$GE_INSTALLED")
        echo "[✓] GE-Proton already installed: $GE_NAME"
        echo ""
        echo "    Make sure each RE Engine game is set to use it:"
        for appid in "${FOUND_ENGINE[@]}"; do
            echo "      - ${RE_ENGINE_GAMES[$appid]}: Right-click > Properties > Compatibility > $GE_NAME"
        done
    else
        install_ge_proton
    fi
    echo ""
fi

# -----------------------------------------------
# Step 3: Install protontricks + WMP11 (for legacy RE games)
# -----------------------------------------------
if [ ${#FOUND_LEGACY[@]} -gt 0 ]; then
    echo "--- Legacy RE Games (need WMP11 codecs) ---"

    # Install protontricks if needed
    if ! command -v protontricks &>/dev/null; then
        echo "[*] Installing protontricks..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get install -y protontricks
        elif command -v pacman &>/dev/null; then
            sudo pacman -S --noconfirm protontricks
        elif command -v flatpak &>/dev/null; then
            flatpak install -y com.github.Matoking.protontricks
        else
            echo "    ERROR: Could not install protontricks. Install manually."
            exit 1
        fi
    fi

    PROTONTRICKS_CMD="protontricks"
    if ! command -v protontricks &>/dev/null; then
        if flatpak list 2>/dev/null | grep -q protontricks; then
            PROTONTRICKS_CMD="flatpak run com.github.Matoking.protontricks"
        fi
    fi

    echo "[✓] protontricks available"

    for appid in "${FOUND_LEGACY[@]}"; do
        game="${RE_LEGACY_GAMES[$appid]}"
        echo ""
        echo "[*] Fixing: $game (AppID: $appid)..."

        # Check if game has been launched at least once (prefix must exist)
        if [ ! -d "$STEAM_APPS/compatdata/$appid/pfx" ]; then
            echo "    SKIP: Game has not been launched yet. Launch it once first, then re-run this script."
            continue
        fi

        echo "    Installing Windows Media Player 11 codecs..."
        if $PROTONTRICKS_CMD "$appid" wmp11 2>&1 | tail -5; then
            echo "    [✓] WMP11 installed for $game"
        else
            echo "    WARNING: wmp11 install may have failed."
            echo "    Try: Set game to Proton 5.13, launch once, quit, then re-run this script."
        fi
    done
    echo ""
fi

# -----------------------------------------------
# Step 4: Enable Steam Shader Pre-Caching
# -----------------------------------------------
echo "--- Additional Steps ---"
echo "[*] Make sure Steam Shader Pre-Caching is enabled:"
echo "    Steam > Settings > Shader Pre-Caching > Enable both options"
echo "    (Valve re-encodes some cutscene videos and distributes via this system)"
echo ""

echo "=== Done ==="
echo ""
echo "Summary:"
if [ ${#FOUND_ENGINE[@]} -gt 0 ]; then
    echo "  RE Engine games: Use GE-Proton as compatibility tool in Steam"
fi
if [ ${#FOUND_LEGACY[@]} -gt 0 ]; then
    echo "  Legacy RE games: WMP11 codecs installed via protontricks"
fi
echo ""
echo "If cutscenes still don't work after applying fixes:"
echo "  1. Make sure you restart Steam"
echo "  2. Verify game files (Right-click > Properties > Installed Files > Verify)"
echo "  3. Try switching between Proton versions"
