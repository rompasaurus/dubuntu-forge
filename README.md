# dubuntu-forge

Snapshot and deploy script for the **dubuntu-desktop** Ubuntu workstation.

## System Profile

| Property       | Value                            |
|----------------|----------------------------------|
| **Hostname**   | dubuntu-desktop                  |
| **OS**         | Ubuntu 25.10 (Questing)          |
| **Kernel**     | 6.17.0-14-generic                |
| **GPU**        | AMD Radeon RX 9070 XT (Navi 48)  |
| **Displays**   | 3x 4K (ASUS XG32UC 240Hz + Dell U3223QE + LG HDR 4K) |
| **Desktop**    | GNOME (dark mode, Greybird theme)|
| **Shell**      | Bash                             |

## What's Captured

- **APT packages** — manually installed (filtered from 2400+ total)
- **Snap packages** — Discord, Firefox, Ghostty, Obsidian, Spotify, etc.
- **Flatpak apps** — WhatsApp for Linux
- **VS Code extensions** — 14 extensions (Claude Code, GitLens, C#, Python, etc.)
- **GNOME settings** — theme, icon pack, dock favorites, dark mode
- **System services** — xrdp, tailscale, ssh
- **Config files** — .bashrc, .profile, ghostty, environment.d
- **Full dconf dump** — every GNOME/desktop setting

## Quick Deploy

```bash
git clone <this-repo>
cd dubuntu-forge
./scripts/deploy.sh
```

### Selective deploy

```bash
./scripts/deploy.sh --repos      # Add third-party APT repos
./scripts/deploy.sh --apt        # Install APT packages
./scripts/deploy.sh --snaps      # Install Snap packages
./scripts/deploy.sh --flatpaks   # Install Flatpak apps
./scripts/deploy.sh --vscode     # Install VS Code extensions
./scripts/deploy.sh --gnome      # Apply GNOME theme/dock/settings
./scripts/deploy.sh --configs    # Deploy dotfiles and configs
./scripts/deploy.sh --services   # Enable xrdp, tailscale, ssh
./scripts/deploy.sh --claude     # Install Claude Code CLI
```

## Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `deploy.sh` | Restore the full dubuntu-desktop environment (packages, configs, GNOME settings, services) | `./scripts/deploy.sh` or `./scripts/deploy.sh --apt --configs` |
| `snapshot.sh` | Capture current system state (APT, snaps, flatpaks, dconf, configs) | `./scripts/snapshot.sh` |
| `install-cli-tools.sh` | Install the full suite of 100+ CLI/TUI power tools from the User Guide | `bash scripts/install-cli-tools.sh` |
| `install-essentials.sh` | Install only the essential CLI tools needed for the zshrc integration block | `bash scripts/install-essentials.sh` |
| `setup-zshrc.sh` | Append CLI tool integrations (zoxide, fzf, eza, bat, etc.) to `~/.zshrc` | `bash scripts/setup-zshrc.sh` |
| `setup-cac.sh` | Setup CAC smart card auth for Chrome — installs middleware, PKCS#11 module, and DoD root certs | `bash scripts/setup-cac.sh` |

### Recommended order for a fresh machine

```bash
./scripts/deploy.sh            # 1. Restore full environment
bash scripts/install-essentials.sh  # 2. Install essential CLI tools
bash scripts/setup-zshrc.sh         # 3. Wire up shell integrations
bash scripts/setup-cac.sh           # 4. (Optional) Enable CAC/smart card login
```

## Update Snapshot

After installing new software or changing settings:

```bash
./scripts/snapshot.sh
git add -A && git commit -m "Update snapshot"
```

## Key Software

| Category     | Packages                                                        |
|--------------|-----------------------------------------------------------------|
| **Browsers** | Google Chrome, Firefox                                          |
| **Dev**      | VS Code, Node.js 20, .NET SDK 10, Python 3.13, Git             |
| **AI**       | Claude Code (CLI)                                               |
| **Gaming**   | Steam                                                           |
| **Comms**    | Discord, Thunderbird, WhatsApp, Spotify                         |
| **Remote**   | xrdp, Remmina, Tailscale, OpenSSH                               |
| **Notes**    | Obsidian                                                        |
| **Terminal** | Ghostty                                                         |

## Docs

| Guide | Description |
|-------|-------------|
| [CLI Power Tools User Guide](CLI-UserGuide.md) | Comprehensive reference for 100+ CLI/TUI tools |
| [CLI Deep-Dive Reference](docs/cli-powertools-reference.md) | Networking, security, and text processing tools |
| [Ubuntu Quick Tips](docs/ubuntu-quick-tips.md) | Keyboard shortcuts, GNOME tweaks, multi-monitor tips, and quick fixes |

## Notes

- Monitor config (`configs/monitors.xml`) is saved but not auto-deployed since it's hardware-specific.
- The full dconf dump (`snapshots/dconf-full.ini`) can restore *all* GNOME settings with `dconf load / < snapshots/dconf-full.ini` — use with caution.
- After deploy, you'll still need to `tailscale up` and set up SSH keys manually.
