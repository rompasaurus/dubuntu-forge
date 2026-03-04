# Terminal Music Players

CLI/TUI music players for Spotify and YouTube Music.

---

## spotify-player

Full-featured Spotify TUI written in Rust with built-in streaming via librespot. No need for a separate Spotify client.

**Requires:** Spotify Premium account

### Install

```bash
# 1. Install dependencies
sudo apt install libssl-dev libasound2-dev libdbus-1-dev

# 2. Install via cargo
cargo install spotify_player --locked

# 3. Authenticate (opens browser for Spotify OAuth)
spotify_player authenticate
```

Alternative install methods:

```bash
# Homebrew
brew install spotify_player

# Prebuilt binaries — download from:
# https://github.com/aome510/spotify-player/releases
```

### Usage

```bash
# Launch the TUI
spotify_player

# Launch in daemon mode (background, no UI — control via Spotify Connect)
spotify_player -d
```

### CLI commands (outside TUI)

```bash
spotify_player search "query"       # Search Spotify
spotify_player playback next        # Skip track
spotify_player playback pause       # Pause playback
spotify_player like                 # Like current track
spotify_player playlist list        # List playlists
```

### Keybindings

| Key | Action |
|-----|--------|
| `Space` | Play / Pause |
| `n` | Next track |
| `p` | Previous track |
| `+` / `-` | Volume up / down |
| `>` / `<` | Seek forward / backward |
| `j` / `k` | Move down / up |
| `Ctrl-f` / `Ctrl-b` | Page down / up |
| `g g` / `G` | Jump to top / bottom |
| `/` | Search |
| `z` | Queue |
| `D` | Spotify Connect devices |
| `?` | Help (full keybinding list) |
| `q` | Quit |

### Config

| Path | Purpose |
|------|---------|
| `~/.config/spotify-player/` | Configuration files |
| `~/.cache/spotify-player/` | Auth tokens and cache |

### Shell Aliases

```bash
spotify     # Launch spotify_player TUI
spd         # Daemon mode (background, no UI)
spn         # Next track
spp         # Pause
sps         # Search (e.g. sps "daft punk")
spl         # Like current track
```

GitHub: https://github.com/aome510/spotify-player

---

## ytermusic

Lightweight YouTube Music TUI written in Rust. ~20 MB RAM usage with offline playback of cached tracks.

### Install

```bash
# 1. Install dependencies
sudo apt install alsa-tools libasound2-dev libdbus-1-dev pkg-config

# 2. Install via cargo
cargo install ytermusic --git https://github.com/ccgauche/ytermusic
```

Alternative install methods:

```bash
# Prebuilt binary — download from:
# https://github.com/ccgauche/ytermusic/releases
chmod +x ytermusic
sudo mv ytermusic /usr/local/bin/
```

### Authentication

ytermusic uses your YouTube Music browser cookies:

1. Go to https://music.youtube.com in your browser (logged in)
2. Open DevTools (`F12`) > **Network** tab
3. Click any request and copy the **Cookie** header value
4. Run `ytermusic --files` to find your config directory
5. Create `headers.txt` in that directory:

```
Cookie: <your-cookie-value>
User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36
```

> **Firefox users:** Enable the "Raw" toggle when copying cookies to prevent corruption.

### Usage

```bash
# Launch the TUI
ytermusic

# Useful flags
ytermusic --fix-db        # Repair corrupted cache database
ytermusic --clear-cache   # Delete all cached/downloaded music
ytermusic --files         # Show config directory locations
```

### Keybindings

| Key | Action |
|-----|--------|
| `Space` | Play / Pause |
| `Enter` | Select |
| `f` | Search |
| `s` | Shuffle |
| `r` | Remove from playlist |
| `Right` / `>` | Skip 5 seconds |
| `Left` / `<` | Rewind 5 seconds |
| `Ctrl+Right` | Next track |
| `Ctrl+Left` | Previous track |
| `+` / `-` | Volume up / down |
| `Up` / `Down` | Scroll |
| `Esc` | Exit menu / search |
| `Ctrl+C` | Quit |

### Features

- Offline playback of previously cached tracks
- Automatic background downloading
- Custom theming via hex colors in config
- Mouse support (click items, time bar, volume bar)

### Shell Aliases

```bash
youtube     # Launch ytermusic TUI
ytfix       # Repair corrupted cache database
ytclear     # Delete all cached/downloaded music
```

GitHub: https://github.com/ccgauche/ytermusic
