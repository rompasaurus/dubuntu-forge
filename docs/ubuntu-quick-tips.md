# Ubuntu Quick Tips

Handy shortcuts, tweaks, and quality-of-life improvements for Ubuntu/GNOME.

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Super` | Open Activities / app search |
| `Super + Up` | Fullscreen / maximize window |
| `Super + Down` | Restore / un-maximize window |
| `Super + Left/Right` | Snap window to left/right half |
| `Super + H` | Minimize window |
| `Super + D` | Show desktop (minimize all) |
| `Super + L` | Lock screen |
| `Super + Tab` | Switch between apps |
| `Alt + Tab` | Switch between windows (all workspaces) |
| `Alt + F4` | Close window |
| `Alt + F2` | Run command dialog (X11 only) |
| `F11` | Toggle fullscreen in most apps |
| `Ctrl + Alt + T` | Open terminal |
| `Ctrl + Alt + Del` | Log out |
| `Super + Page Up/Down` | Switch workspaces |
| `Super + Shift + Page Up/Down` | Move window to another workspace |
| `Print Screen` | Screenshot tool |
| `Shift + Print Screen` | Screenshot selection |
| `Super + V` | Clipboard history (GNOME 45+) |

## Window Management

### Tile windows side by side
Drag a window to the left/right edge, or use `Super + Left/Right`. On GNOME 45+ you can also drag a second window to the opposite side to auto-tile.

### Quarter-tiling
Hold `Super` and drag a window to a corner for quarter-tile. Or use a tiling extension like **Tiling Assistant**:
```bash
sudo apt install gnome-shell-extension-tiling-assistant
```

## Top Bar & Dock Tweaks

### Auto-hide the top bar (macOS-style)
```bash
sudo apt install gnome-shell-extension-autohide-top-panel
```
Log out/in or restart GNOME Shell (`Alt+F2` > `r` on X11). Enable in the **Extensions** app. The top bar hides and reappears when you hover at the top.

### Move the dock to the bottom
```bash
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
```

### Auto-hide the dock
```bash
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
```

### Make the dock smaller
```bash
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 36
```

## Appearance

### Enable dark mode
```bash
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
```

### Change the GTK theme
```bash
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
```

### Set a custom wallpaper
```bash
gsettings set org.gnome.desktop.background picture-uri-dark "file:///path/to/wallpaper.jpg"
```

### Install the Tweaks tool
```bash
sudo apt install gnome-tweaks
```
Gives you control over fonts, themes, startup apps, top bar clock, and more.

## System Management

### Check disk usage
```bash
df -h           # filesystem usage
du -sh ~/       # home folder size
duf             # prettier alternative (install with: sudo apt install duf)
```

### Kill an unresponsive app
```bash
xdotool selectwindow windowclose   # click to kill
# or
xkill                               # click to kill (X11)
# or
pkill -f app-name
```

### Find what's using a port
```bash
sudo ss -tlnp | grep :8080
```

### Manage startup applications
Open **Tweaks > Startup Applications**, or manually add `.desktop` files to:
```
~/.config/autostart/
```

### Clear APT cache
```bash
sudo apt clean && sudo apt autoremove -y
```

## Useful GNOME Extensions

Install from the **Extensions** app or [extensions.gnome.org](https://extensions.gnome.org):

| Extension | What it does |
|-----------|-------------|
| **Auto Hide Top Bar** | macOS-style auto-hiding top bar |
| **Tiling Assistant** | Quarter-tiling, snap groups, layouts |
| **Blur my Shell** | Blur effect on top bar, dash, overview |
| **Clipboard Indicator** | Clipboard history manager |
| **AppIndicator Support** | System tray icons for apps like Discord, Slack |
| **Caffeine** | Prevent screen from going to sleep |
| **Vitals** | CPU, RAM, temp, fan speed in top bar |
| **Night Theme Switcher** | Auto dark/light mode based on time |

Install the extension manager CLI to manage them:
```bash
sudo apt install gnome-shell-extension-manager
```

## Multi-Monitor Tips

### Set primary display
```bash
xrandr --output DP-1 --primary
```

### List connected displays
```bash
xrandr --listmonitors
```

### Move workspaces to span all monitors
```bash
gsettings set org.gnome.mutter workspaces-only-on-primary false
```

## Performance

### Reduce animations
```bash
gsettings set org.gnome.desktop.interface enable-animations false
```

### Check GPU info
```bash
glxinfo | grep "OpenGL renderer"
# or for AMD:
radeontop
```

### Monitor system resources
```bash
btop       # pretty TUI monitor
htop       # classic process viewer
nvidia-smi # NVIDIA GPU (if applicable)
```

## Networking

### Restart networking
```bash
sudo systemctl restart NetworkManager
```

### Show IP addresses
```bash
ip -br addr
```

### Test DNS resolution
```bash
resolvectl status
dig google.com
```

### Flush DNS cache
```bash
sudo resolvectl flush-caches
```

## Quick Fixes

### Fix broken packages
```bash
sudo apt --fix-broken install
sudo dpkg --configure -a
```

### Fix "repository not signed" errors
```bash
# Remove the offending repo
sudo rm /etc/apt/sources.list.d/problematic-repo.list
# Or re-add its GPG key
curl -fsSL https://example.com/key.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/repo.gpg
```

### Reset GNOME to defaults
```bash
dconf reset -f /org/gnome/
```
**Warning:** This resets ALL GNOME settings. Use with caution.
