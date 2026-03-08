#!/bin/bash
###############################################################################
# VLC Media Library Setup for /mnt/dookintel
# Populates VLC's ml.xspf media library with all media from dookintel NAS
# and configures VLC audio output for DENON-AVR via ALSA.
###############################################################################

set -u

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

MEDIA_ROOT="/mnt/dookintel"
VLC_CONFIG="$HOME/.config/vlc/vlcrc"
VLC_DATA="$HOME/.local/share/vlc"
ML_FILE="$VLC_DATA/ml.xspf"

# Media directories to index
MEDIA_DIRS=(
    "$MEDIA_ROOT/Movies"
    "$MEDIA_ROOT/Movies 2"
    "$MEDIA_ROOT/TV Shows"
    "$MEDIA_ROOT/TV Shows 2"
    "$MEDIA_ROOT/TV Shows 3"
    "$MEDIA_ROOT/TV Shows 4"
    "$MEDIA_ROOT/Bertha/Anime"
    "$MEDIA_ROOT/Bertha/German Blu Ray Rips"
    "$MEDIA_ROOT/Bertha/German Dubbed TV Shows"
    "$MEDIA_ROOT/Bertha/Youtube"
)

# Video file extensions to include
VIDEO_EXTS="mkv|mp4|avi|m4v|ts|m2ts|wmv|flv|webm|mov|mpg|mpeg|ogv|vob"

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  VLC Media Library Setup${NC}"
echo -e "${CYAN}  Source: $MEDIA_ROOT${NC}"
echo -e "${CYAN}========================================${NC}"

# Check mount is accessible
if [ ! -d "$MEDIA_ROOT" ]; then
    echo -e "${YELLOW}ERROR: $MEDIA_ROOT is not accessible. Is the NAS mounted?${NC}"
    exit 1
fi

# Ensure VLC is installed
if ! command -v vlc &>/dev/null; then
    echo -e "${YELLOW}VLC not found. Installing...${NC}"
    sudo apt install -y vlc
fi

# Enable VLC media library in config
if [ -f "$VLC_CONFIG" ]; then
    echo -e "${GREEN}[1/3]${NC} Configuring VLC settings..."

    # Enable media library
    if grep -q "^#media-library=0" "$VLC_CONFIG"; then
        sed -i 's/^#media-library=0/media-library=1/' "$VLC_CONFIG"
        echo "  Media library enabled"
    elif grep -q "^media-library=1" "$VLC_CONFIG"; then
        echo "  Media library already enabled"
    else
        echo "media-library=1" >> "$VLC_CONFIG"
        echo "  Media library setting added"
    fi

    # Configure ALSA audio output to DENON-AVR (hw:1,7)
    if grep -q "^#aout=" "$VLC_CONFIG"; then
        sed -i 's/^#aout=.*/aout=alsa/' "$VLC_CONFIG"
    elif grep -q "^aout=" "$VLC_CONFIG"; then
        sed -i 's/^aout=.*/aout=alsa/' "$VLC_CONFIG"
    else
        echo "aout=alsa" >> "$VLC_CONFIG"
    fi

    if grep -q "^#alsa-audio-device=" "$VLC_CONFIG"; then
        sed -i 's/^#alsa-audio-device=.*/alsa-audio-device=hw:1,7/' "$VLC_CONFIG"
    elif grep -q "^alsa-audio-device=" "$VLC_CONFIG"; then
        sed -i 's/^alsa-audio-device=.*/alsa-audio-device=hw:1,7/' "$VLC_CONFIG"
    else
        echo "alsa-audio-device=hw:1,7" >> "$VLC_CONFIG"
    fi
    echo "  Audio output set to ALSA -> DENON-AVR (hw:1,7)"
else
    echo -e "${YELLOW}VLC config not found at $VLC_CONFIG. Run VLC once first to generate it.${NC}"
fi

# Build the ml.xspf media library
echo -e "${GREEN}[2/3]${NC} Scanning media directories..."
mkdir -p "$VLC_DATA"

# Collect all media files into a temp file
TMPFILE=$(mktemp)
total=0

for dir in "${MEDIA_DIRS[@]}"; do
    dirname=$(basename "$dir")
    if [ ! -d "$dir" ]; then
        echo "  Skipping $dirname (not found)"
        continue
    fi

    count=0
    while IFS= read -r -d '' file; do
        echo "$file" >> "$TMPFILE"
        count=$((count + 1))
    done < <(find "$dir" -type f -regextype posix-extended -iregex ".*\.($VIDEO_EXTS)$" -print0 2>/dev/null | sort -z)

    echo "  $dirname: $count files"
    total=$((total + count))
done

echo -e "${GREEN}[3/3]${NC} Writing media library ($total files)..."

# Generate XSPF in one shot with python3 (fast)
python3 << 'PYSCRIPT' - "$TMPFILE" "$ML_FILE"
import sys
import os
import urllib.parse
from xml.sax.saxutils import escape

tmpfile = sys.argv[1]
outfile = sys.argv[2]

with open(tmpfile, 'r') as f:
    files = [line.rstrip('\n') for line in f if line.strip()]

with open(outfile, 'w', encoding='utf-8') as out:
    out.write('<?xml version="1.0" encoding="UTF-8"?>\n')
    out.write('<playlist xmlns="http://xspf.org/ns/0/" xmlns:vlc="http://www.videolan.org/vlc/playlist/ns/0/" version="1">\n')
    out.write('\t<title>Media Library</title>\n')
    out.write('\t<trackList>\n')

    for i, filepath in enumerate(files):
        location = 'file://' + urllib.parse.quote(filepath)
        title = escape(os.path.basename(filepath))
        out.write(f'\t\t<track>\n')
        out.write(f'\t\t\t<location>{location}</location>\n')
        out.write(f'\t\t\t<title>{title}</title>\n')
        out.write(f'\t\t\t<extension application="http://www.videolan.org/vlc/playlist/0">\n')
        out.write(f'\t\t\t\t<vlc:id>{i}</vlc:id>\n')
        out.write(f'\t\t\t</extension>\n')
        out.write(f'\t\t</track>\n')

    out.write('\t</trackList>\n')
    out.write('\t<extension application="http://www.videolan.org/vlc/playlist/0">\n')
    for i in range(len(files)):
        out.write(f'\t\t<vlc:item tid="{i}"/>\n')
    out.write('\t</extension>\n')
    out.write('</playlist>\n')

print(f"  Written {len(files)} tracks to {outfile}")
PYSCRIPT

rm -f "$TMPFILE"

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}Setup complete!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "Media library: $ML_FILE ($total files)"
echo ""
echo "Open VLC and click 'Media Library' in the left panel to browse."
echo "Use Ctrl+F to search within the library."
echo ""
echo -e "${YELLOW}Tip:${NC} Re-run this script anytime to refresh after adding new media."
