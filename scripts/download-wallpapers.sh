#!/bin/bash
# Download a curated collection of 4K wallpapers
# Categories: cityscapes, nature, sci-fi, gaming (BG3 + FF), weird

set -e

DEST="${1:-$HOME/Pictures/Wallpapers}"
mkdir -p "$DEST"/{cityscapes,nature,scifi,gaming,weird}

download() {
    local dir="$1" name="$2" url="$3"
    if [ -f "$DEST/$dir/$name" ]; then
        echo "  Skipping $name (already exists)"
        return
    fi
    echo "  Downloading $name..."
    wget -q --max-redirect=5 --timeout=30 -O "$DEST/$dir/$name" "$url" 2>/dev/null || \
    curl -sL --max-time 60 -o "$DEST/$dir/$name" "$url" 2>/dev/null || \
    echo "  FAILED: $name"
}

echo "=== Cityscapes ==="
download cityscapes "cyberpunk-city-neon.jpg" "https://unsplash.com/photos/dA0-qxdbyyY/download?w=3840"
download cityscapes "cyberpunk-dark-city.jpg" "https://unsplash.com/photos/eIe-KSCAbMU/download?w=3840"
download cityscapes "cyberpunk-skyscrapers.jpg" "https://unsplash.com/photos/x66ubRvGXM8/download?w=3840"
download cityscapes "tokyo-neon-street.jpg" "https://unsplash.com/photos/YNLIep6Pn4g/download?w=3840"
download cityscapes "tokyo-neon-alley.jpg" "https://unsplash.com/photos/IwPKcaH-DaQ/download?w=3840"
download cityscapes "tokyo-neon-signs.jpg" "https://unsplash.com/photos/cbwlHckGxAk/download?w=3840"
download cityscapes "nyc-skyline-night.jpg" "https://unsplash.com/photos/GmlMtdSfmVU/download?w=3840"
download cityscapes "nyc-bridge-night.jpg" "https://unsplash.com/photos/_e3RZ8jDOUo/download?w=3840"
download cityscapes "nyc-tribute-in-light.jpg" "https://unsplash.com/photos/7YBXY3SnhSc/download?w=3840"

echo "=== Nature ==="
download nature "aurora-borealis.jpg" "https://unsplash.com/photos/jwIk4Z3Msi4/download?w=3840"
download nature "aurora-bright-sky.jpg" "https://unsplash.com/photos/m5oOEXIRWdU/download?w=3840"
download nature "aurora-tree-silhouettes.jpg" "https://unsplash.com/photos/62V7ntlKgL8/download?w=3840"
download nature "moraine-lake-reflection.jpg" "https://unsplash.com/photos/DlkF4-dbCOU/download?w=3840"
download nature "mountain-lake-peaceful.jpg" "https://unsplash.com/photos/ZYY2lNM-J1Y/download?w=3840"
download nature "matterhorn-reflection.jpg" "https://unsplash.com/photos/qnPEmE8M1c4/download?w=3840"
download nature "deep-ocean-diver.jpg" "https://unsplash.com/photos/FuusC7lfg6Q/download?w=3840"
download nature "coral-reef.jpg" "https://unsplash.com/photos/FiAuI0Wen2I/download?w=3840"
download nature "deep-ocean-blue.jpg" "https://unsplash.com/photos/DnNqjwalv9g/download?w=3840"

echo "=== Sci-Fi ==="
download scifi "space-station-astronaut.jpg" "https://unsplash.com/photos/X19mJVgTZfo/download?w=3840"
download scifi "space-station-orbit.jpg" "https://unsplash.com/photos/rDaxHYjJC1o/download?w=3840"
download scifi "space-station-detail.jpg" "https://unsplash.com/photos/f-wULBP2iNE/download?w=3840"
download scifi "nebula-red-deep-space.jpg" "https://unsplash.com/photos/pr_kNwZtYM0/download?w=3840"
download scifi "nebula-cosmic-gases.jpg" "https://unsplash.com/photos/G-5JCERzbE8/download?w=3840"
download scifi "nebula-spacecraft.jpg" "https://unsplash.com/photos/AJZ_75RTpL0/download?w=3840"
download scifi "shuttle-earth-atmosphere.jpg" "https://unsplash.com/photos/7Cz6bWjdlDs/download?w=3840"

echo "=== Gaming - Baldur's Gate 3 ==="
download gaming "bg3-official-art.jpg" "https://w.wallhaven.cc/full/3l/wallhaven-3l651y.jpg"
download gaming "bg3-landscape.jpg" "https://w.wallhaven.cc/full/1p/wallhaven-1pgxjg.jpg"

echo "=== Gaming - Final Fantasy ==="
download gaming "ff7r-characters.png" "https://w.wallhaven.cc/full/gp/wallhaven-gpdkrl.png"
download gaming "ff7-rebirth-nibel.png" "https://w.wallhaven.cc/full/7p/wallhaven-7pd15e.png"
download gaming "ff16-odin.png" "https://w.wallhaven.cc/full/gw/wallhaven-gwz773.png"
download gaming "ff16-key-art.png" "https://w.wallhaven.cc/full/we/wallhaven-we2pmp.png"
download gaming "ff16-clive.png" "https://w.wallhaven.cc/full/je/wallhaven-je933m.png"
download gaming "ffx-tidus.jpg" "https://w.wallhaven.cc/full/qz/wallhaven-qzv2el.jpg"

echo "=== Weird ==="
download weird "psychedelic-swirl.jpg" "https://unsplash.com/photos/JKWPpiBTatw/download?w=3840"
download weird "abstract-vibrant.jpg" "https://unsplash.com/photos/u-VOCC2yg9s/download?w=3840"
download weird "psychedelic-fractal.jpg" "https://unsplash.com/photos/ikys5rulD-0/download?w=3840"
download weird "glitch-digital.jpg" "https://unsplash.com/photos/ZXN1cb4-Lww/download?w=3840"
download weird "glitch-red-black.jpg" "https://unsplash.com/photos/2G9YVbjwE-Q/download?w=3840"
download weird "glitch-vibrant.jpg" "https://unsplash.com/photos/Xl_5sYauFFE/download?w=3840"
download weird "cosmic-horror-surreal.jpg" "https://unsplash.com/photos/zn7Lp_XO0D0/download?w=3840"
download weird "glitch-symbols.jpg" "https://unsplash.com/photos/7L_hW0SArAY/download?w=3840"
download weird "glitch-dark-abstract.jpg" "https://unsplash.com/photos/76SsNhsVPkU/download?w=3840"

echo ""
echo "=== Done! ==="
echo "Downloaded to: $DEST"
echo ""
echo "Categories:"
for dir in cityscapes nature scifi gaming weird; do
    count=$(find "$DEST/$dir" -type f 2>/dev/null | wc -l)
    echo "  $dir: $count wallpapers"
done
echo ""
echo "To set a wallpaper:"
echo "  gsettings set org.gnome.desktop.background picture-uri-dark 'file:///path/to/wallpaper.jpg'"
