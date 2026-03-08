#!/bin/bash
# Full Kodi setup: install, skin, media sources, metadata, HDR/DV fix
# Usage: ./setup-kodi.sh [mount_path]
# Example: ./setup-kodi.sh /mnt/dookintel

set -e

MOUNT_POINT="${1:-/mnt/dookintel}"
KODI_USERDATA="$HOME/.kodi/userdata"
KODI_ADDONS="$HOME/.kodi/addons"
KODI_PACKAGES="$KODI_ADDONS/packages"
REPO="https://mirrors.kodi.tv/addons/omega"

echo "=== Kodi Full Setup ==="
echo "Media path: $MOUNT_POINT"
echo ""

# -----------------------------------------------
# 1. Install Kodi
# -----------------------------------------------
echo "[1/7] Installing Kodi..."
sudo apt install -y kodi cifs-utils

# -----------------------------------------------
# 2. Check media mount
# -----------------------------------------------
echo "[2/7] Checking media mount..."
if [ ! -d "$MOUNT_POINT" ]; then
    echo "Warning: $MOUNT_POINT not found. Continuing with setup anyway."
    echo "Mount your share before launching Kodi."
fi

# -----------------------------------------------
# 3. Auto-detect media folders
# -----------------------------------------------
echo "[3/7] Detecting media folders..."
MOVIE_SOURCES=""
TV_SOURCES=""

if [ -d "$MOUNT_POINT" ]; then
    for dir in "$MOUNT_POINT"/*/; do
        dirname=$(basename "$dir")
        case "$dirname" in
            *Movie*|*movie*|*Film*|*film*)
                MOVIE_SOURCES="$MOVIE_SOURCES|$dir"
                echo "  Found movies: $dirname"
                ;;
            *TV*|*tv*|*Show*|*show*|*Series*|*series*)
                TV_SOURCES="$TV_SOURCES|$dir"
                echo "  Found TV: $dirname"
                ;;
            *RECYCLE*|*System\ Volume*|*Steam*)
                ;;
            *)
                echo "  Skipped: $dirname"
                ;;
        esac
    done
fi

# -----------------------------------------------
# 4. Install Arctic Zephyr Reloaded skin + deps
# -----------------------------------------------
echo "[4/7] Installing Arctic Zephyr Reloaded skin..."
mkdir -p "$KODI_PACKAGES" "$KODI_ADDONS"

# Download addons.xml index once
ADDON_INDEX="/tmp/kodi_addons_index.xml"
echo "  Downloading addon index..."
curl -sL "${REPO}/addons.xml.gz" | gunzip > "$ADDON_INDEX" 2>/dev/null

install_addon() {
    local addon="$1"
    if [ -d "${KODI_ADDONS}/${addon}" ]; then
        echo "  Skip: $addon (exists)"
        return
    fi
    local zip_path
    zip_path=$(grep -oP "(?<=<path>)${addon}/${addon}-[^<]+\.zip" "$ADDON_INDEX" | head -1)
    if [ -n "$zip_path" ]; then
        echo "  Installing: $addon"
        curl -sL "${REPO}/${zip_path}" -o "${KODI_PACKAGES}/${addon}.zip"
        unzip -qo "${KODI_PACKAGES}/${addon}.zip" -d "${KODI_ADDONS}/"
    else
        echo "  Not found: $addon (may be bundled)"
    fi
}

# Skin and all dependencies
ADDONS=(
    # Skin
    "skin.arctic.zephyr.mod"
    # Direct dependencies
    "script.skinshortcuts"
    "script.globalsearch"
    "script.image.resource.select"
    "resource.images.weathericons.white"
    "script.embuary.info"
    "script.embuary.helper"
    "plugin.video.themoviedb.helper"
    # Sub-dependencies
    "script.module.requests"
    "script.module.arrow"
    "script.module.simplecache"
    "script.module.routing"
    "script.module.addon.signals"
    "script.module.jurialmunkey"
    "script.module.infotagger"
    "script.module.beautifulsoup4"
    "script.module.unidecode"
    "script.module.simpleeval"
)

for addon in "${ADDONS[@]}"; do
    install_addon "$addon"
done

rm -f "$ADDON_INDEX"
echo "  Skin installation complete."

# -----------------------------------------------
# 5. Register addons in Kodi database
# -----------------------------------------------
echo "[5/7] Registering addons in database..."

# Run Kodi once briefly to create databases if they don't exist
if [ ! -f "$KODI_USERDATA/Database/Addons33.db" ]; then
    echo "  Creating Kodi databases (first run)..."
    timeout 10 kodi --standalone &>/dev/null || true
    sleep 2
    pkill -9 kodi 2>/dev/null || true
    pkill -9 kodi.bin 2>/dev/null || true
    sleep 1
fi

if [ -f "$KODI_USERDATA/Database/Addons33.db" ]; then
    python3 << 'PYEOF'
import sqlite3, os
from datetime import datetime

DB = os.path.expanduser("~/.kodi/userdata/Database/Addons33.db")
conn = sqlite3.connect(DB)
c = conn.cursor()
now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
origin = "repository.xbmc.org"

addons = [
    "skin.arctic.zephyr.mod", "script.skinshortcuts", "script.globalsearch",
    "script.image.resource.select", "resource.images.weathericons.white",
    "script.embuary.info", "script.embuary.helper", "plugin.video.themoviedb.helper",
    "script.module.requests", "script.module.arrow", "script.module.simplecache",
    "script.module.routing", "script.module.addon.signals", "script.module.jurialmunkey",
    "script.module.infotagger", "script.module.beautifulsoup4",
    "script.module.unidecode", "script.module.simpleeval",
]

for addon_id in addons:
    c.execute("SELECT addonID FROM installed WHERE addonID = ?", (addon_id,))
    if not c.fetchone():
        c.execute("INSERT INTO installed (addonID, enabled, installDate, origin) VALUES (?, 1, ?, ?)",
                  (addon_id, now, origin))

conn.commit()
conn.close()
print("  Addons registered.")
PYEOF
fi

# -----------------------------------------------
# 6. Configure sources, scrapers, and database
# -----------------------------------------------
echo "[6/7] Configuring media sources and scrapers..."
mkdir -p "$KODI_USERDATA"

# Build sources.xml
cat > "${KODI_USERDATA}/sources.xml" << XMLEOF
<sources>
    <programs>
        <default pathversion="1"></default>
    </programs>
    <video>
        <default pathversion="1"></default>
XMLEOF

# Add movie sources
IFS='|'
for src in $MOVIE_SOURCES; do
    [ -z "$src" ] && continue
    name=$(basename "$src")
    cat >> "${KODI_USERDATA}/sources.xml" << XMLEOF
        <source>
            <name>${name}</name>
            <path pathversion="1">${src}</path>
            <allowsharing>true</allowsharing>
        </source>
XMLEOF
done

# Add TV sources
for src in $TV_SOURCES; do
    [ -z "$src" ] && continue
    name=$(basename "$src")
    cat >> "${KODI_USERDATA}/sources.xml" << XMLEOF
        <source>
            <name>${name}</name>
            <path pathversion="1">${src}</path>
            <allowsharing>true</allowsharing>
        </source>
XMLEOF
done
unset IFS

cat >> "${KODI_USERDATA}/sources.xml" << 'XMLEOF'
    </video>
    <music>
        <default pathversion="1"></default>
    </music>
    <pictures>
        <default pathversion="1"></default>
    </pictures>
    <files>
        <default pathversion="1"></default>
    </files>
</sources>
XMLEOF

# Configure scrapers in video database
if [ -f "$KODI_USERDATA/Database/MyVideos131.db" ]; then
    python3 << PYEOF
import sqlite3, os

DB = os.path.expanduser("~/.kodi/userdata/Database/MyVideos131.db")
conn = sqlite3.connect(DB)
c = conn.cursor()

movie_scraper = "metadata.themoviedb.org.python"
tv_scraper = "metadata.tvshows.themoviedb.org.python"
movie_settings = '<settings><setting id="certprefix" default="true">us</setting><setting id="fanart">true</setting><setting id="keeporiginaltitle" default="true">false</setting><setting id="language" default="true">en-US</setting><setting id="RatingS" default="true">TMDb</setting><setting id="tmdbcertcountry" default="true">us</setting><setting id="trailer">true</setting></settings>'
tv_settings = '<settings><setting id="certprefix" default="true">us</setting><setting id="fanart">true</setting><setting id="keeporiginaltitle" default="true">false</setting><setting id="language" default="true">en-US</setting><setting id="RatingS" default="true">TMDb</setting><setting id="tmdbcertcountry" default="true">us</setting><setting id="episodeimages">true</setting></settings>'

mount = "$MOUNT_POINT"

# Movie paths
for d in os.listdir(mount):
    full = os.path.join(mount, d) + "/"
    if not os.path.isdir(full) or "RECYCLE" in d or "System Volume" in d or "Steam" in d:
        continue
    lower = d.lower()
    if any(k in lower for k in ["movie", "film"]):
        content, scraper, settings = "movies", movie_scraper, movie_settings
    elif any(k in lower for k in ["tv", "show", "series"]):
        content, scraper, settings = "tvshows", tv_scraper, tv_settings
    else:
        continue

    c.execute("SELECT idPath FROM path WHERE strPath = ?", (full,))
    if c.fetchone():
        c.execute("UPDATE path SET strContent=?, strScraper=?, strSettings=?, scanRecursive=2147483647, strHash='' WHERE strPath=?",
                  (content, scraper, settings, full))
    else:
        c.execute("INSERT INTO path (strPath, strContent, strScraper, strHash, scanRecursive, useFolderNames, strSettings, noUpdate, exclude, allAudio) VALUES (?, ?, ?, '', 2147483647, 0, ?, 0, 0, 0)",
                  (full, content, scraper, settings))
    print(f"  {content}: {d}")

conn.commit()
conn.close()
PYEOF
fi

# -----------------------------------------------
# 7. Configure Kodi settings
# -----------------------------------------------
echo "[7/8] Applying Kodi settings..."

# Advanced settings - library auto-scan and cleanup
cat > "${KODI_USERDATA}/advancedsettings.xml" << 'XMLEOF'
<advancedsettings>
    <videolibrary>
        <scanalibraryonstartup>true</scanalibraryonstartup>
        <cleanalibraryonupdate>true</cleanalibraryonupdate>
    </videolibrary>
    <videoscanner>
        <excludefromscan>
            <regexp>[-\._ ](sample|trailer)[-\._ ]</regexp>
        </excludefromscan>
    </videoscanner>
    <playcount>
        <playcountminimumpercent>90</playcountminimumpercent>
    </playcount>
</advancedsettings>
XMLEOF

# Skin settings - info overlays, plot display, mouse warning
mkdir -p "${KODI_USERDATA}/addon_data/skin.arctic.zephyr.mod"
if [ ! -f "${KODI_USERDATA}/addon_data/skin.arctic.zephyr.mod/settings.xml" ]; then
    cat > "${KODI_USERDATA}/addon_data/skin.arctic.zephyr.mod/settings.xml" << 'XMLEOF'
<settings>
    <setting id="hide.mouse.warning" type="bool">true</setting>
    <setting id="osd.showplot" type="bool">true</setting>
    <setting id="osd.info.fullscreen" type="bool">true</setting>
    <setting id="osd.showinfoonpause" type="bool">true</setting>
    <setting id="furniture.overlayinfo" type="bool">true</setting>
    <setting id="furniture.overlayinfobalken" type="bool">true</setting>
    <setting id="51bigwide.showinfo" type="bool">true</setting>
    <setting id="55wall.showinfo" type="bool">true</setting>
    <setting id="56media.showinfo" type="bool">true</setting>
    <setting id="51.showplot" type="bool">true</setting>
    <setting id="widgets.autoscrollingplot" type="bool">true</setting>
    <setting id="furniture.flags" type="bool">true</setting>
    <setting id="furniture.flags.rating" type="bool">true</setting>
    <setting id="labels.autoscroll" type="bool">true</setting>
    <setting id="homemenu.netflix" type="bool">true</setting>
    <setting id="home.modernwidgets" type="bool">true</setting>
    <setting id="home.vertical.widgets" type="bool">true</setting>
    <setting id="home.widgets.show.reflections" type="bool">true</setting>
    <setting id="show.reflections" type="bool">true</setting>
    <setting id="furniture.flagicons" type="bool">true</setting>
    <setting id="furniture.coloredicons" type="bool">true</setting>
    <setting id="511ListInfo" type="bool">true</setting>
    <setting id="extended.nowplaying" type="bool">true</setting>
    <setting id="tmdbhelper.service" type="bool">true</setting>
    <setting id="startup.init" type="bool">true</setting>
    <setting id="SkinShortcuts-FullMenu" type="bool">true</setting>
    <setting id="skinshortcuts-sharedmenu" type="string">true</setting>
    <setting id="WidgetLimit" type="string">25</setting>
    <setting id="HubLimit" type="string">25</setting>
</settings>
XMLEOF
fi

# Skin shortcuts menu - clear hash to force rebuild
rm -f "${KODI_USERDATA}/addon_data/script.skinshortcuts/skin.arctic.zephyr.mod.hash" 2>/dev/null

# Main menu with Movies, TV Shows, Genres, Search
mkdir -p "${KODI_USERDATA}/addon_data/script.skinshortcuts"
cat > "${KODI_USERDATA}/addon_data/script.skinshortcuts/mainmenu.DATA.xml" << 'XMLEOF'
<shortcuts>
    <shortcut>
        <defaultID>movies</defaultID>
        <label>Movies</label>
        <label2>32034</label2>
        <icon>DefaultMovies.png</icon>
        <thumb></thumb>
        <action>ActivateWindow(Videos,videodb://movies/titles/,return)</action>
    </shortcut>
    <shortcut>
        <defaultID>tvshows</defaultID>
        <label>TV Shows</label>
        <label2>32035</label2>
        <icon>DefaultTVShows.png</icon>
        <thumb></thumb>
        <action>ActivateWindow(Videos,videodb://tvshows/titles/,return)</action>
    </shortcut>
    <shortcut>
        <defaultID>genres</defaultID>
        <label>Genres</label>
        <label2></label2>
        <icon>DefaultGenre.png</icon>
        <thumb></thumb>
        <action>ActivateWindow(Videos,videodb://movies/genres/,return)</action>
    </shortcut>
    <shortcut>
        <defaultID>search</defaultID>
        <label>Search</label>
        <label2></label2>
        <icon>DefaultAddonsSearch.png</icon>
        <thumb></thumb>
        <action>RunScript(script.globalsearch)</action>
    </shortcut>
    <shortcut>
        <defaultID>recently-added</defaultID>
        <label>Recently Added</label>
        <label2></label2>
        <icon>DefaultRecentlyAddedMovies.png</icon>
        <thumb></thumb>
        <action>ActivateWindow(Videos,videodb://recentlyaddedmovies/,return)</action>
    </shortcut>
    <shortcut>
        <defaultID>settings</defaultID>
        <label>Settings</label>
        <label2></label2>
        <icon>DefaultAddonProgram.png</icon>
        <thumb></thumb>
        <action>ActivateWindow(Settings)</action>
    </shortcut>
</shortcuts>
XMLEOF

# Submenus
cat > "${KODI_USERDATA}/addon_data/script.skinshortcuts/movies.DATA.xml" << 'XMLEOF'
<shortcuts>
    <shortcut>
        <defaultID>movies-titles</defaultID>
        <label>All Movies</label>
        <icon>DefaultMovies.png</icon>
        <thumb></thumb>
        <action>ActivateWindow(Videos,videodb://movies/titles/,return)</action>
    </shortcut>
    <shortcut>
        <defaultID>movies-genres</defaultID>
        <label>Genres</label>
        <icon>DefaultGenre.png</icon>
        <thumb></thumb>
        <action>ActivateWindow(Videos,videodb://movies/genres/,return)</action>
    </shortcut>
    <shortcut>
        <defaultID>movies-years</defaultID>
        <label>Years</label>
        <icon>DefaultYear.png</icon>
        <thumb></thumb>
        <action>ActivateWindow(Videos,videodb://movies/years/,return)</action>
    </shortcut>
    <shortcut>
        <defaultID>movies-recent</defaultID>
        <label>Recently Added</label>
        <icon>DefaultRecentlyAddedMovies.png</icon>
        <thumb></thumb>
        <action>ActivateWindow(Videos,videodb://recentlyaddedmovies/,return)</action>
    </shortcut>
</shortcuts>
XMLEOF

cat > "${KODI_USERDATA}/addon_data/script.skinshortcuts/tvshows.DATA.xml" << 'XMLEOF'
<shortcuts>
    <shortcut>
        <defaultID>tvshows-titles</defaultID>
        <label>All TV Shows</label>
        <icon>DefaultTVShows.png</icon>
        <thumb></thumb>
        <action>ActivateWindow(Videos,videodb://tvshows/titles/,return)</action>
    </shortcut>
    <shortcut>
        <defaultID>tvshows-genres</defaultID>
        <label>Genres</label>
        <icon>DefaultGenre.png</icon>
        <thumb></thumb>
        <action>ActivateWindow(Videos,videodb://tvshows/genres/,return)</action>
    </shortcut>
    <shortcut>
        <defaultID>tvshows-recent</defaultID>
        <label>Recently Added Episodes</label>
        <icon>DefaultRecentlyAddedEpisodes.png</icon>
        <thumb></thumb>
        <action>ActivateWindow(Videos,videodb://recentlyaddedepisodes/,return)</action>
    </shortcut>
    <shortcut>
        <defaultID>tvshows-inprogress</defaultID>
        <label>In Progress</label>
        <icon>DefaultInProgressShows.png</icon>
        <thumb></thumb>
        <action>ActivateWindow(Videos,videodb://inprogresstvshows/,return)</action>
    </shortcut>
</shortcuts>
XMLEOF

# Apply guisettings patches via Python
python3 << 'PYEOF'
import os, re

GUI = os.path.expanduser("~/.kodi/userdata/guisettings.xml")
if not os.path.exists(GUI):
    print("  guisettings.xml not found, will be created on first Kodi launch.")
    exit(0)

with open(GUI, "r") as f:
    content = f.read()

# Settings to apply: (id, value)
patches = [
    # Skin
    ("lookandfeel.skin", "skin.arctic.zephyr.mod"),
    # Library
    ("videolibrary.updateonstartup", "true"),
    ("videolibrary.backgroundupdate", "true"),
    ("videolibrary.artworklevel", "2"),
    # Metadata
    ("videolibrary.actorthumbs", "true"),
    ("myvideos.extractthumb", "true"),
    ("myvideos.extractchapterthumbs", "true"),
    # HDR / Dolby Vision
    ("winsystem.ishdrdisplay", "false"),
    ("videoplayer.convertdovi", "true"),
    # Subtitles
    ("subtitles.fontsize", "24"),
    ("subtitles.marginvertical", "0"),
    ("subtitles.align", "0"),
    ("subtitles.overridestyles", "1"),
    # Web server for Kore remote
    ("services.webserver", "true"),
    # Expert settings level
]

for setting_id, value in patches:
    # Match both default="true" and without
    pattern = rf'(<setting id="{re.escape(setting_id)}"[^>]*>)[^<]*(</setting>)'
    replacement = rf'\g<1>{value}\g<2>'
    new_content = re.sub(pattern, replacement, content)
    if new_content != content:
        # Remove default="true" to make setting stick
        new_content = new_content.replace(
            f'<setting id="{setting_id}" default="true">{value}</setting>',
            f'<setting id="{setting_id}">{value}</setting>'
        )
        content = new_content
        print(f"  Set: {setting_id} = {value}")
    else:
        print(f"  Skip: {setting_id} (not found)")

# Fix tonemapping
content = content.replace(
    "<tonemapmethod>1</tonemapmethod>",
    "<tonemapmethod>3</tonemapmethod>"
)

with open(GUI, "w") as f:
    f.write(content)

print("  GUI settings patched.")
PYEOF

# Set settings level to Expert
python3 << 'PYEOF'
import os

GUI = os.path.expanduser("~/.kodi/userdata/guisettings.xml")
if os.path.exists(GUI):
    with open(GUI, "r") as f:
        content = f.read()
    content = content.replace("<settinglevel>1</settinglevel>", "<settinglevel>3</settinglevel>")
    with open(GUI, "w") as f:
        f.write(content)
PYEOF

# -----------------------------------------------
# 8. Xbox controller keymap
# -----------------------------------------------
echo "[8/8] Setting up Xbox controller keymap..."
mkdir -p "${KODI_USERDATA}/keymaps"
cat > "${KODI_USERDATA}/keymaps/xbox.xml" << 'XMLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!-- Xbox Controller Kodi Navigation Keymap -->
<keymap>
  <global>
    <joystick profile="game.controller.default">
      <!-- Face buttons -->
      <a>Select</a>
      <a holdtime="500">ContextMenu</a>
      <b>Back</b>
      <x>Info</x>
      <y>FullScreen</y>

      <!-- Menu buttons -->
      <start>ContextMenu</start>
      <back>ActivateWindow(Home)</back>
      <guide>RunScript(script.globalsearch)</guide>

      <!-- D-Pad -->
      <up>Up</up>
      <down>Down</down>
      <left>Left</left>
      <right>Right</right>

      <!-- Left stick - navigation -->
      <leftstick direction="up">Up</leftstick>
      <leftstick direction="down">Down</leftstick>
      <leftstick direction="left">Left</leftstick>
      <leftstick direction="right">Right</leftstick>

      <!-- Right stick - volume -->
      <rightstick direction="up">VolumeUp</rightstick>
      <rightstick direction="down">VolumeDown</rightstick>
      <rightstick direction="left">VolumeDown</rightstick>
      <rightstick direction="right">VolumeUp</rightstick>

      <!-- Bumpers - page scroll -->
      <leftbumper>PageUp</leftbumper>
      <rightbumper>PageDown</rightbumper>

      <!-- Triggers - scroll -->
      <lefttrigger>ScrollUp</lefttrigger>
      <righttrigger>ScrollDown</righttrigger>

      <!-- Stick clicks -->
      <leftthumb>ToggleWatched</leftthumb>
      <rightthumb>ActivateWindow(ShutdownMenu)</rightthumb>
    </joystick>
  </global>

  <Home>
    <joystick profile="game.controller.default">
      <b holdtime="500">ActivateWindow(ShutdownMenu)</b>
    </joystick>
  </Home>

  <FullscreenVideo>
    <joystick profile="game.controller.default">
      <a>Pause</a>
      <b>Stop</b>
      <b holdtime="500">FullScreen</b>
      <x>Info</x>
      <y>OSD</y>
      <start>ActivateWindow(PlayerControls)</start>
      <back>FullScreen</back>
      <guide>OSD</guide>
      <up>ChapterOrBigStepForward</up>
      <down>ChapterOrBigStepBack</down>
      <right>StepForward</right>
      <left>StepBack</left>
      <leftstick direction="left">AnalogSeekBack</leftstick>
      <leftstick direction="right">AnalogSeekForward</leftstick>
      <leftstick direction="up">noop</leftstick>
      <leftstick direction="down">noop</leftstick>
      <leftbumper>AnalogRewind</leftbumper>
      <rightbumper>AnalogFastForward</rightbumper>
      <lefttrigger>AnalogRewind</lefttrigger>
      <righttrigger>AnalogFastForward</righttrigger>
      <leftthumb>ShowSubtitles</leftthumb>
      <rightthumb>AudioNextLanguage</rightthumb>
    </joystick>
  </FullscreenVideo>

  <VideoOSD>
    <joystick profile="game.controller.default">
      <b>Close</b>
      <y>Close</y>
    </joystick>
  </VideoOSD>

  <FullscreenInfo>
    <joystick profile="game.controller.default">
      <b>Close</b>
      <x>Close</x>
    </joystick>
  </FullscreenInfo>

  <MovieInformation>
    <joystick profile="game.controller.default">
      <b>Close</b>
    </joystick>
  </MovieInformation>

  <VirtualKeyboard>
    <joystick profile="game.controller.default">
      <a>Select</a>
      <a holdtime="500">Shift</a>
      <b>BackSpace</b>
      <y>Symbols</y>
      <leftbumper>Shift</leftbumper>
      <leftthumb>Enter</leftthumb>
      <lefttrigger>CursorLeft</lefttrigger>
      <righttrigger>CursorRight</righttrigger>
    </joystick>
  </VirtualKeyboard>
</keymap>
XMLEOF

# Enable joystick input
python3 << 'PYEOF'
import os, re

GUI = os.path.expanduser("~/.kodi/userdata/guisettings.xml")
if os.path.exists(GUI):
    with open(GUI, "r") as f:
        content = f.read()
    for setting in ["input.enablejoystick"]:
        pattern = rf'(<setting id="{re.escape(setting)}"[^>]*>)[^<]*(</setting>)'
        content = re.sub(pattern, rf'\g<1>true\g<2>', content)
    with open(GUI, "w") as f:
        f.write(content)
    print("  Xbox controller keymap installed.")
PYEOF

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Installed:"
echo "  - Kodi with Arctic Zephyr Reloaded skin"
echo "  - TMDb scrapers for movies and TV shows"
echo "  - Global search addon"
echo ""
echo "Configured:"
echo "  - Auto library scan on startup"
echo "  - Full metadata + artwork + episode summaries"
echo "  - Dolby Vision conversion enabled"
echo "  - HDR-to-SDR tonemapping (ACES)"
echo "  - Smaller subtitles at bottom of screen"
echo "  - Web server for Kore remote app (port 8080)"
echo "  - Home menu: Movies, TV Shows, Genres, Search, Recently Added"
echo "  - Xbox controller keymap for full navigation + playback"
echo ""
echo "Launch Kodi and let it scan your library."
echo "Install 'Kore' on your phone to use as a remote."
