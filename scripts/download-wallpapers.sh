#!/bin/bash
# Download ~200 curated 4K wallpapers from Wallhaven, sorted by category
# Uses Wallhaven public API (no key needed for SFW)
# Usage: ./download-wallpapers.sh [destination]

set -e

DEST="${1:-$HOME/Pictures/Wallpapers}"
WALLHAVEN="https://wallhaven.cc/api/v1/search"
PER_PAGE=24  # Wallhaven max per page
TOTAL_TARGET=200

echo "=== 4K Wallpaper Downloader ==="
echo "Destination: $DEST"
echo "Target: ~${TOTAL_TARGET} wallpapers"
echo ""

# Categories and search queries
# Each entry: "folder|query|pages_to_fetch"
CATEGORIES=(
    "nature|nature landscape mountain|2"
    "nature|ocean underwater reef|1"
    "nature|aurora borealis northern lights|1"
    "nature|forest fog moody|1"
    "space|nebula galaxy deep space|2"
    "space|earth planet orbit|1"
    "space|astronaut space station|1"
    "cyberpunk|cyberpunk neon city|2"
    "cyberpunk|tokyo neon night|1"
    "cityscapes|city skyline night|2"
    "cityscapes|urban architecture modern|1"
    "abstract|abstract colorful fluid|2"
    "abstract|geometric minimal dark|1"
    "abstract|fractal psychedelic|1"
    "scifi|science fiction futuristic|2"
    "scifi|mech robot sci-fi|1"
    "dark|dark moody atmospheric|2"
    "dark|gothic horror dark|1"
    "gaming|dark souls elden ring|1"
    "gaming|baldurs gate 3|1"
    "gaming|final fantasy|1"
    "gaming|cyberpunk 2077|1"
    "gaming|god of war|1"
    "anime|anime scenery landscape|2"
    "anime|anime cyberpunk city|1"
    "minimal|minimalist wallpaper dark|2"
)

# Create all category folders
declare -A FOLDER_COUNTS
for entry in "${CATEGORIES[@]}"; do
    IFS='|' read -r folder _ _ <<< "$entry"
    mkdir -p "$DEST/$folder"
    FOLDER_COUNTS[$folder]=0
done

download_category() {
    local folder="$1"
    local query="$2"
    local pages="$3"
    local count=0

    for page in $(seq 1 "$pages"); do
        # Fetch top-rated 4K+ wallpapers
        local response
        response=$(curl -s "${WALLHAVEN}?q=${query// /+}&categories=100&purity=100&atleast=3840x2160&sorting=toplist&topRange=1y&page=${page}" 2>/dev/null)

        if [ -z "$response" ]; then
            echo "  API request failed for: $query (page $page)"
            continue
        fi

        # Parse URLs and download
        local urls
        urls=$(echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for w in data.get('data', []):
        print(w['path'])
except: pass
" 2>/dev/null)

        while IFS= read -r url; do
            [ -z "$url" ] && continue
            local filename
            filename=$(basename "$url")
            local target="$DEST/$folder/$filename"

            if [ -f "$target" ]; then
                count=$((count + 1))
                continue
            fi

            curl -sL --max-time 30 -o "$target" "$url" 2>/dev/null
            if [ -f "$target" ] && [ -s "$target" ]; then
                count=$((count + 1))
            else
                rm -f "$target" 2>/dev/null
            fi
        done <<< "$urls"

        # Rate limit - be nice to wallhaven
        sleep 1
    done

    FOLDER_COUNTS[$folder]=$(( ${FOLDER_COUNTS[$folder]} + count ))
    echo "  $folder/$query: $count wallpapers"
}

# Download all categories
TOTAL=0
for entry in "${CATEGORIES[@]}"; do
    IFS='|' read -r folder query pages <<< "$entry"
    echo "=== $folder: $query ==="
    download_category "$folder" "$query" "$pages"
done

# Remove any empty/corrupt files (< 50KB is likely broken)
echo ""
echo "Cleaning up broken downloads..."
find "$DEST" -type f -size -50k -name "*.jpg" -o -name "*.png" | while read -r f; do
    echo "  Removed broken: $(basename "$f")"
    rm -f "$f"
done

# Summary
echo ""
echo "=== Download Complete ==="
echo "Location: $DEST"
echo ""
echo "Categories:"
GRAND_TOTAL=0
for folder in nature space cyberpunk cityscapes abstract scifi dark gaming anime minimal; do
    if [ -d "$DEST/$folder" ]; then
        count=$(find "$DEST/$folder" -type f 2>/dev/null | wc -l)
        GRAND_TOTAL=$((GRAND_TOTAL + count))
        echo "  $folder: $count wallpapers"
    fi
done
echo ""
echo "Total: $GRAND_TOTAL wallpapers"
echo ""
echo "Set wallpaper:"
echo "  gsettings set org.gnome.desktop.background picture-uri-dark 'file:///path/to/wallpaper.jpg'"
echo ""
echo "Random wallpaper:"
echo "  WALL=\$(find $DEST -type f | shuf -n1) && gsettings set org.gnome.desktop.background picture-uri-dark \"file://\$WALL\""
