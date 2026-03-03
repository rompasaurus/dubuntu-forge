# CLI Power Tools — The Ultimate Ubuntu User Guide

> A comprehensive reference for 100+ CLI/TUI tools that transform your terminal into a powerhouse.
> Curated for **Ubuntu 25.10** on the dubuntu-desktop workstation.

---

## Table of Contents

1. [Prerequisites & Package Managers](#1-prerequisites--package-managers)
2. [File Managers & Navigation](#2-file-managers--navigation)
3. [Modern File Utilities (Drop-in Replacements)](#3-modern-file-utilities-drop-in-replacements)
4. [System Monitoring & Info](#4-system-monitoring--info)
5. [Git & Version Control](#5-git--version-control)
6. [Terminal Multiplexers & Shells](#6-terminal-multiplexers--shells)
7. [Text Editors](#7-text-editors)
8. [Developer Utilities](#8-developer-utilities)
9. [Containers & Cloud](#9-containers--cloud)
10. [Networking & Transfer](#10-networking--transfer)
11. [Security & Encryption](#11-security--encryption)
12. [Text & Data Processing](#12-text--data-processing)
13. [Miscellaneous Power Tools](#13-miscellaneous-power-tools)
14. [Fun & Eye Candy](#14-fun--eye-candy)
15. [Shell Integration Block](#15-shell-integration-block)
16. [One-Command Installer](#16-one-command-installer)

---

## 1. Prerequisites & Package Managers

Before installing Rust/Go-based tools, set up their toolchains:

```bash
# Rust (for cargo install)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

# Go (for go install)
sudo snap install go --classic

# pipx (isolated Python CLI tools)
sudo apt install pipx
pipx ensurepath

# Homebrew on Linux (optional but useful)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

---

## 2. File Managers & Navigation

### yazi — Blazing-fast async file manager (Rust)

The fastest modern file manager with built-in image/video/PDF previews, tabs, and a Lua plugin system.

```bash
# Install
cargo install --locked yazi-fm yazi-cli
# Optional preview deps:
sudo apt install ffmpegthumbnailer unar jq poppler-utils fd-find ripgrep fzf zoxide
```

| Key | Action |
|-----|--------|
| `h/j/k/l` | Navigate (vim-style) |
| `y` / `x` / `p` | Copy / cut / paste |
| `d` | Trash / delete |
| `r` | Rename |
| `Space` | Toggle selection |
| `v` | Visual mode |
| `t` | New tab |
| `w` | Task manager |
| `z` | Jump via zoxide |
| `/` | Search |
| `q` | Quit |

Config: `~/.config/yazi/yazi.toml`, `keymap.toml`, `theme.toml`

---

### lf — Lightweight terminal file manager (Go)

Vim-inspired miller-columns file manager. Single binary, zero deps, near-instant startup.

```bash
sudo apt install lf
# Or: curl https://webi.sh/lf | sh
```

| Key | Action |
|-----|--------|
| `h/l` | Parent / enter |
| `j/k` | Down / up |
| `y` then `p` | Copy then paste |
| `d` then `p` | Cut then paste |
| `Space` | Toggle selection |
| `/` then `n/N` | Search, next/prev |
| `:delete` | Delete |
| `q` | Quit |

Config: `~/.config/lf/lfrc`

---

### ranger — Python file manager with vim keybindings

Three-pane miller layout, image previews, bookmarks, tags, bulk rename. Rich plugin ecosystem.

```bash
sudo apt install ranger
ranger --copy-config=all   # Generate config files
```

| Key | Action |
|-----|--------|
| `h/j/k/l` | Navigate |
| `yy` / `dd` / `pp` | Copy / cut / paste |
| `dD` | Delete |
| `cw` | Rename |
| `zh` | Toggle hidden files |
| `S` | Open shell in current dir |
| `/` | Search |

Config: `~/.config/ranger/rc.conf`
Tip: `set preview_images true` + `set preview_images_method kitty` for image previews.

---

### nnn — Tiny, ultra-fast file manager (C)

Under 100 KB. Fastest file manager available. Plugin-extensible, 4 contexts (tabs), minimal RAM (~3.5 MB).

```bash
sudo apt install nnn
curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs | sh
```

| Key | Action |
|-----|--------|
| `Enter/l` | Open / enter |
| `h/Left` | Parent |
| `Space` | Select |
| `p` / `v` | Copy / move selected |
| `x` | Delete |
| `Tab` / `1-4` | Switch contexts |
| `/` | Filter |
| `;key` | Run plugin |

Config via env vars in `~/.bashrc`:
```bash
export NNN_BMS='d:~/Documents;D:~/Downloads;p:~/Projects'
export NNN_PLUG='p:preview-tui;f:fzcd;d:diffs'
```

---

### superfile — Modern, beautiful TUI file manager (Go)

Best-looking TUI file manager. Multi-panel, tabs, archive support, familiar Ctrl-key shortcuts.

```bash
bash -c "$(curl -sLo- https://superfile.dev/install.sh)"
```

Launch with `spf`. Config: `~/.config/superfile/config.toml`

---

### mc (Midnight Commander) — Classic dual-pane file manager

Two-panel orthodox layout. Built-in editor (mcedit), FTP/SFTP support, mouse input.

```bash
sudo apt install mc
```

| Key | Action |
|-----|--------|
| `Tab` | Switch panel |
| `F5/F6/F7/F8` | Copy / move / mkdir / delete |
| `F3/F4` | View / edit |
| `Ctrl+o` | Toggle shell |
| `Ctrl+\` | Bookmarks |

Tip: Type `sh://user@host/path` in dir bar for SFTP.

---

### broot — Interactive directory tree with fuzzy search (Rust)

Combines `tree` + `find` + `cd` into one tool. Fuzzy search, Git integration, disk usage analysis.

```bash
cargo install --locked broot
broot --install   # Set up 'br' shell function
```

| Key | Action |
|-----|--------|
| Type letters | Fuzzy filter tree |
| `Enter` | Open |
| `Alt+Enter` | cd into dir and quit |
| `Alt+h` | Toggle hidden |
| `:e` | Edit in $EDITOR |

Whale-spotting mode: `br -w` (find large files visually).

---

### zoxide — Smarter cd (Rust)

Learns your directory habits. Jump anywhere with a few letters using frecency ranking.

```bash
sudo apt install zoxide
echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
```

```bash
z foo           # Jump to best match for "foo"
z foo bar       # Match both "foo" and "bar"
zi              # Interactive selection with fzf
z -             # Previous directory
```

Tip: `eval "$(zoxide init bash --cmd cd)"` — replaces `cd` itself.

---

### fzf — General-purpose fuzzy finder

The single most impactful CLI tool. Fuzzy-search anything: files, history, processes, git branches.

```bash
sudo apt install fzf
echo 'eval "$(fzf --bash)"' >> ~/.bashrc
```

| Key | Action |
|-----|--------|
| `Ctrl+R` | Fuzzy search command history |
| `Ctrl+T` | Fuzzy find file, insert path |
| `Alt+C` | Fuzzy cd into directory |
| `**Tab` | Fuzzy completion (vim, ssh, kill, etc.) |

Search syntax: `'exact`, `^prefix`, `suffix$`, `!exclude`, `term1 | term2` (OR)

Config:
```bash
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :200 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons {}'"
```

---

## 3. Modern File Utilities (Drop-in Replacements)

### bat — cat with syntax highlighting (Rust)

```bash
sudo apt install bat
ln -sf /usr/bin/batcat ~/.local/bin/bat   # Ubuntu names it batcat
```

```bash
bat file.py              # Syntax-highlighted view
bat -p file.py           # Plain (no decorations)
bat --diff file.py       # Only Git-changed lines
bat -r 10:20 file.py     # Lines 10-20 only
bat -A file              # Show non-printable chars
```

Tip: `export MANPAGER="sh -c 'col -bx | bat -l man -p'"` — colorized man pages.

---

### eza — Modern ls replacement (Rust, successor to exa)

```bash
sudo apt install eza
```

```bash
eza                      # Colorized listing
eza -lah --icons         # Long, all, human-readable, icons
eza --tree --level=2     # Tree view
eza -l --git             # Show Git status per file
eza -l --sort=modified   # Sort by mod time
```

Recommended aliases:
```bash
alias ls='eza --icons'
alias ll='eza -lah --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons'
```

---

### fd — Modern find replacement (Rust)

```bash
sudo apt install fd-find
ln -sf /usr/bin/fdfind ~/.local/bin/fd
```

```bash
fd pattern              # Recursive search
fd -e py                # Find all .py files
fd -e py -x wc -l       # Find .py files, count lines each
fd -t d pattern          # Directories only
fd -H pattern            # Include hidden
fd --changed-within 1d   # Recently modified
```

---

### ripgrep (rg) — Blazing-fast grep (Rust)

```bash
sudo apt install ripgrep
```

```bash
rg pattern              # Recursive search
rg -i pattern            # Case-insensitive
rg -t py pattern         # Only Python files
rg -A3 -B3 pattern      # Context lines
rg -l pattern            # Filenames only
rg -c pattern            # Count per file
rg --files               # List searchable files
```

Config: set `RIPGREP_CONFIG_PATH=~/.config/ripgrep/config`:
```
--smart-case
--hidden
--glob=!.git
```

---

### dust — Visual disk usage (Rust, replaces du)

```bash
cargo install du-dust
```

```bash
dust                    # Current directory
dust -n 20              # Top 20 largest
dust -d 2               # Depth limit 2
dust -f                 # Show files too
```

---

### duf — Better df (Go)

```bash
sudo apt install duf
```

```bash
duf                     # All mounted filesystems
duf --only local        # Local only
duf --sort size         # Sort by size
duf --json              # JSON output
```

---

### sd — Intuitive find & replace (Rust, replaces sed)

```bash
cargo install sd
```

```bash
sd 'old' 'new' file.txt           # Replace in-place
sd 'foo(\d+)' 'bar$1' file        # Capture groups
sd -p 'old' 'new' file            # Preview (dry run)
fd -e py -X sd 'old' 'new'        # Recursive replace with fd
```

---

### delta — Beautiful git diffs (Rust)

```bash
sudo apt install git-delta
```

Add to `~/.gitconfig`:
```ini
[core]
    pager = delta
[interactive]
    diffFilter = delta --color-only
[delta]
    navigate = true
    side-by-side = true
    line-numbers = true
    syntax-theme = Catppuccin-mocha
[merge]
    conflictstyle = zdiff3
```

---

### hexyl — Hex viewer with colors (Rust)

```bash
sudo apt install hexyl
```

```bash
hexyl file.bin           # Full hex view
hexyl -n 256 file        # First 256 bytes
hexyl -s 1024 file       # Skip to offset
```

---

### choose — Smarter cut (Rust)

```bash
cargo install choose
```

```bash
echo 'a b c d' | choose 0          # "a"
echo 'a b c d' | choose 2:         # "c d"
echo 'a b c d' | choose -1         # "d"
echo 'a,b,c' | choose -f ',' 0 2   # Comma delimiter
```

---

### tre — Modern tree with Git awareness (Rust)

```bash
cargo install tre-command
```

```bash
tre                     # Tree (respects .gitignore)
tre -e                  # Numbered entries (e1, e2... open in $EDITOR)
tre -l 2                # Depth limit
tre -j                  # JSON output
```

---

### doggo — Modern DNS client (Go)

```bash
go install github.com/mr-karan/doggo/cmd/doggo@latest
```

```bash
doggo example.com                   # A record lookup
doggo MX example.com                # MX records
doggo example.com @9.9.9.9         # Specific nameserver
doggo example.com @https://cloudflare-dns.com/dns-query  # DNS over HTTPS
doggo --reverse 8.8.8.8            # Reverse DNS
doggo example.com --json           # JSON output
```

---

## 4. System Monitoring & Info

### btop — Best all-in-one system monitor (C++)

```bash
sudo apt install btop
```

Full TUI dashboard: CPU, memory, disks, network, processes. GPU support, mouse-driven, themeable.

| Key | Action |
|-----|--------|
| `h/l` | Switch category tabs |
| `Up/Down` | Navigate processes |
| `Enter` | Detailed process view |
| `k` | Kill process (sends SIGTERM) |
| `f` | Filter processes |
| `t` | Tree view toggle |
| `m` | Toggle sort menu |
| `Esc` | Back / close menu |

Config: `~/.config/btop/btop.conf`

---

### htop — Interactive process viewer

```bash
sudo apt install htop
```

| Key | Action |
|-----|--------|
| `F5` | Tree view |
| `F6` | Sort by column |
| `F9` | Kill process |
| `F4` | Filter |
| `u` | Filter by user |
| `t` | Toggle tree |
| `H` | Toggle user threads |
| `Space` | Tag process |

---

### bottom (btm) — System monitor (Rust)

```bash
cargo install bottom --locked
```

```bash
btm                     # Launch
btm -b                  # Basic mode
btm --battery           # Show battery info
```

---

### glances — Cross-platform system monitor (Python)

```bash
pipx install glances
```

```bash
glances                 # Local monitoring
glances -w              # Web UI mode (http://localhost:61208)
glances --export csv    # Export to CSV
glances -s              # Server mode (remote monitoring)
```

---

### nvtop — GPU monitor (C)

```bash
sudo apt install nvtop
```

Monitors AMD, NVIDIA, Intel, Apple, and Qualcomm GPUs. Shows utilization, memory, temperature, fan speed, power, per-process GPU usage.

---

### bandwhich — Per-process bandwidth monitor (Rust)

```bash
cargo install bandwhich
sudo bandwhich           # Needs root for packet capture
```

Shows which processes are using bandwidth and to what destinations. Three views: total, per-process, per-connection.

---

### procs — Modern ps replacement (Rust)

```bash
cargo install procs
```

```bash
procs                   # Colored process list
procs --tree            # Process tree
procs --watch 1         # Watch mode (1s refresh)
procs --sorta cpu       # Sort ascending by CPU
procs --tcp             # Show TCP connections
procs zsh               # Filter by keyword
```

---

### fastfetch — System info fetcher (C, successor to neofetch)

```bash
sudo apt install fastfetch
```

```bash
fastfetch               # Full system info with logo
fastfetch --logo none   # Text only
fastfetch -c examples/13.jsonc  # Alternate layout
```

Config: `~/.config/fastfetch/config.jsonc`

---

### inxi — Comprehensive system info (Perl)

```bash
sudo apt install inxi
```

```bash
inxi -Fxxxz             # Full system info
inxi -G                 # Graphics/GPU info
inxi -N                 # Network devices
inxi -D                 # Disk info
inxi -b                 # Brief overview
inxi -t c10             # Top 10 CPU processes
inxi -t m10             # Top 10 memory processes
```

---

### hyperfine — Command benchmarking (Rust)

```bash
cargo install hyperfine
```

```bash
hyperfine 'fd -e py'                    # Benchmark single command
hyperfine 'fd -e py' 'find . -name "*.py"'  # Compare two commands
hyperfine --warmup 3 'cargo build'      # Warm-up runs
hyperfine --min-runs 20 'my-command'    # Minimum iterations
hyperfine --export-markdown bench.md 'cmd1' 'cmd2'  # Export results
```

---

### tokei / scc — Code line counters

```bash
cargo install tokei    # Rust (150+ languages)
go install github.com/boyter/scc/v3@latest  # Go (adds COCOMO estimates)
```

```bash
tokei                  # Count all code
tokei -t Rust,Python   # Specific languages
scc                    # Count + complexity + cost estimates
scc --by-file          # Per-file breakdown
```

---

### s-tui — CPU stress test + thermal monitor (Python)

```bash
pipx install s-tui
sudo apt install stress   # Optional stress test backend
```

Real-time CPU frequency, temperature, power, and utilization graphs. Can run stress tests.

---

### powertop — Power consumption analyzer

```bash
sudo apt install powertop
sudo powertop            # Interactive analysis
sudo powertop --auto-tune  # Apply all power-saving suggestions
```

---

### Other monitoring tools

| Tool | Install | What it does |
|------|---------|--------------|
| `iotop` | `sudo apt install iotop` | Per-process disk I/O |
| `iftop` | `sudo apt install iftop` | Per-connection bandwidth |
| `nethogs` | `sudo apt install nethogs` | Per-process bandwidth |
| `bmon` | `sudo apt install bmon` | Multi-interface network graphs |
| `vnstat` | `sudo apt install vnstat` | Long-term traffic accounting |
| `nmon` | `sudo apt install nmon` | IBM's toggle-panel monitor |
| `cpufetch` | `sudo snap install cpufetch` | CPU architecture ASCII art |
| `macchina` | `cargo install macchina` | Rust neofetch alternative |

---

## 5. Git & Version Control

### lazygit — TUI for Git

The single best quality-of-life upgrade for git workflows. Interactive staging, rebasing, cherry-picking.

```bash
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit && sudo install lazygit /usr/local/bin
```

| Key | Action |
|-----|--------|
| `Space` | Stage/unstage file |
| `a` | Stage all |
| `c` | Commit |
| `P` / `p` | Push / pull |
| `s` | Squash commit |
| `i` | Interactive rebase |
| `x` | Context menu |
| `/` | Filter/search |

Config: `~/.config/lazygit/config.yml`. Set `pager: delta --dark --paging=never` for delta integration.

---

### gitui — Fast Git TUI (Rust)

2x faster than lazygit with 1/15th memory. Great for huge repos.

```bash
cargo install gitui --locked
```

---

### tig — ncurses Git browser

```bash
sudo apt install tig
```

```bash
tig                    # Browse log
tig --all              # All branches
tig blame file.rs      # Interactive blame
tig status             # Staging area
tig stash              # Browse stashes
```

---

### gh — GitHub CLI

```bash
sudo apt install gh
```

```bash
gh pr create --fill            # Create PR from commits
gh pr list                     # List PRs
gh pr checkout 42              # Check out PR locally
gh issue create --title "Bug"  # Create issue
gh run watch                   # Watch CI run
gh browse                      # Open in browser
```

---

### git-absorb — Auto fixup commits

```bash
cargo install git-absorb
```

```bash
git add file_with_fixes.rs
git absorb --and-rebase     # Auto-distribute fixes to correct commits
```

---

### git-branchless — Stacked diffs + universal undo

```bash
cargo install --locked git-branchless
git branchless init
```

```bash
git sl                  # Smartlog: visualize commit graph
git undo                # Undo ANY git operation
git restack             # Auto-rebase children after amending
git sync                # Rebase all stacks onto updated main
```

---

### onefetch — Git repo info display

```bash
sudo apt install onefetch
```

```bash
onefetch                # Repo summary with ASCII art
```

---

### git-cliff — Changelog generator

```bash
cargo install git-cliff
```

```bash
git cliff -o CHANGELOG.md          # Generate changelog
git cliff --unreleased             # Unreleased changes only
git cliff --bump                   # Auto-bump + changelog
```

---

### commitizen — Conventional commits

```bash
pipx install commitizen
```

```bash
cz commit                # Guided commit message
cz bump                  # Auto-bump version
cz changelog             # Generate changelog
```

---

## 6. Terminal Multiplexers & Shells

### tmux — Standard terminal multiplexer

```bash
sudo apt install tmux
```

| Key (prefix: `Ctrl+b`) | Action |
|-------------------------|--------|
| `"` / `%` | Split horizontal / vertical |
| Arrow keys | Move between panes |
| `c` | New window |
| `n` / `p` | Next / prev window |
| `d` | Detach |
| `z` | Zoom pane |
| `[` | Scroll/copy mode |

Essential `~/.tmux.conf`:
```bash
set -g mouse on
set -g base-index 1
set -g default-terminal "tmux-256color"
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
```

---

### zellij — Modern multiplexer (Rust)

```bash
cargo install --locked zellij
```

Discoverable keybinding bar, floating panes, WASM plugins, layout files, session resurrection.

| Key | Action |
|-----|--------|
| `Ctrl+p` | Pane mode |
| `Ctrl+t` | Tab mode |
| `Ctrl+n` | Resize mode |
| `Ctrl+s` | Scroll mode |
| `Ctrl+o` | Session mode (d=detach) |
| `Alt+n` | Quick new pane |

---

### starship — Cross-shell prompt (Rust)

```bash
curl -sS https://starship.rs/install.sh | sh
echo 'eval "$(starship init bash)"' >> ~/.bashrc
```

Config: `~/.config/starship.toml`:
```toml
[character]
success_symbol = "[>](bold green)"
error_symbol = "[>](bold red)"

[cmd_duration]
min_time = 2_000

[directory]
truncation_length = 3
```

---

### atuin — Magical shell history (Rust)

```bash
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
atuin import auto
```

Replaces `Ctrl+R` with full-screen, filterable, searchable history with metadata (directory, duration, exit code). Optional encrypted sync across machines.

Config: `~/.config/atuin/config.toml`:
```toml
search_mode = "fuzzy"
filter_mode = "global"
style = "compact"
show_preview = true
```

---

### fish — User-friendly shell

```bash
sudo apt install fish
```

Autosuggestions, syntax highlighting, web config (`fish_config`), smart completions — all built-in.

Note: Not POSIX-compatible. Use alongside bash for scripting.

---

### zsh + oh-my-zsh

```bash
sudo apt install zsh && chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Essential plugins for `~/.zshrc`:
```bash
plugins=(git z fzf zsh-autosuggestions zsh-syntax-highlighting)
```

---

### nushell — Structured data shell (Rust)

```bash
cargo install nu
```

```nu
ls | where size > 10mb                    # Filter files by size
ps | where cpu > 5 | sort-by mem          # Query processes
open data.json | get users                # Parse JSON natively
sys | get host                            # Structured system info
```

---

## 7. Text Editors

### neovim — Hyperextensible editor

```bash
sudo snap install nvim --classic
```

Quick start with LazyVim (full IDE):
```bash
git clone https://github.com/LazyVim/starter ~/.config/nvim
nvim   # Auto-installs everything
```

---

### helix — Batteries-included modal editor (Rust)

```bash
sudo snap install helix --classic
```

Built-in Tree-sitter, LSP, fuzzy finder, multiple cursors. Zero plugins needed.

| Key | Action |
|-----|--------|
| `w/b` | Select word forward/back |
| `x` | Select line |
| `s` | Sub-select (regex in selection) |
| `Space+f` | File picker |
| `Space+/` | Global search |
| `gd` | Go to definition |
| `Space+?` | Command palette |

Config: `~/.config/helix/config.toml`

---

### micro — Intuitive terminal editor

```bash
sudo apt install micro
```

Standard keybindings: `Ctrl+S` save, `Ctrl+Z` undo, `Ctrl+Q` quit, `Ctrl+F` find. Zero learning curve.

---

### kakoune — Selection-first modal editor

```bash
sudo apt install kakoune
```

"Select then act" — you always see what you're operating on before acting. First-class multiple selections.

---

## 8. Developer Utilities

### jq — JSON processor

```bash
sudo apt install jq
```

```bash
curl -s api.example.com | jq '.'                    # Pretty print
cat data.json | jq '.users[] | select(.active) | .email'  # Filter
cat data.json | jq '[.items[] | {name, price}]'     # Reshape
cat data.json | jq -r '.items[].name'               # Raw output
```

---

### yq — YAML/XML/TOML processor

```bash
sudo snap install yq
```

```bash
yq '.metadata.name' deploy.yaml           # Extract field
yq '.spec.replicas = 3' -i deploy.yaml    # Edit in-place
yq -o=json config.yaml                    # YAML to JSON
```

---

### xh — HTTP client (Rust, HTTPie-compatible)

```bash
cargo install xh
```

```bash
xh GET api.example.com/users              # GET
xh POST api.example.com name=alice age:=30  # POST JSON
xh -f POST api.example.com/login user=admin pass=secret  # Form data
xh --download example.com/file.zip        # Download
```

---

### tealdeer (tldr) — Simplified man pages

```bash
sudo apt install tealdeer && tldr --update
```

```bash
tldr tar                # Common tar examples
tldr git rebase         # Git rebase examples
```

---

### entr — Run commands on file change

```bash
sudo apt install entr
```

```bash
ls src/*.rs | entr cargo test              # Re-run tests on save
ls *.py | entr -r python app.py            # Restart server on change
git ls-files | entr -c make                # Rebuild on any change
```

---

### watchexec — Smart file watcher (Rust)

```bash
cargo install watchexec-cli
```

```bash
watchexec cargo test                       # Auto-re-run tests
watchexec -e rs,toml cargo build           # Watch specific extensions
watchexec -r python app.py                 # Restart on change
```

---

### just — Modern command runner (replaces make)

```bash
cargo install just
```

Create a `justfile`:
```just
default: fmt test

test *args='':
    cargo test {{args}}

fmt:
    cargo fmt

build: fmt
    cargo build --release
```

```bash
just           # Run default recipe
just test      # Run specific recipe
just --list    # Show all recipes
```

---

### direnv — Per-directory environments

```bash
sudo apt install direnv
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
```

```bash
echo 'export DATABASE_URL="postgres://localhost/dev"' > .envrc
direnv allow
# Variable auto-loads when you cd in, unloads when you cd out
```

---

### mise — Polyglot version manager (Rust, replaces asdf/nvm/pyenv)

```bash
curl https://mise.run | sh
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
```

```bash
mise use node@20            # Install & activate Node 20
mise use -g python@3.12     # Global Python version
mise install                # Install all from mise.toml
```

`mise.toml`:
```toml
[tools]
node = "20"
python = "3.12"
```

---

### grex — Generate regex from examples (Rust)

```bash
cargo install grex
```

```bash
grex "test-123" "test-456" "test-789"    # -> ^test-\d{3}$
grex -d "2024-01-15" "2024-12-31"        # With digit conversion
```

---

### glow — Terminal markdown renderer (Go)

```bash
sudo apt install glow
```

```bash
glow README.md          # Render markdown
glow .                  # Browse all .md files (TUI)
```

---

### silicon — Code screenshots from terminal (Rust)

```bash
cargo install silicon
```

```bash
silicon main.rs -o code.png --theme Dracula --font "JetBrains Mono"
silicon main.rs --to-clipboard              # Copy to clipboard
```

---

### navi — Interactive cheatsheet tool (Rust)

```bash
cargo install --locked navi
```

```bash
navi                    # Browse cheatsheets
navi --tldr docker      # Use tldr as source
# Add Ctrl+G widget:
eval "$(navi widget bash)"
```

---

### posting — TUI API client (Python)

```bash
pipx install posting
```

Full Postman-like API testing in the terminal. Requests stored as version-controllable YAML files.

---

## 9. Containers & Cloud

### lazydocker — TUI for Docker

```bash
go install github.com/jesseduffield/lazydocker@latest
```

View and manage containers, images, volumes, logs. Single-keystroke operations.

---

### dive — Docker image layer analyzer

```bash
wget https://github.com/wagoodman/dive/releases/latest/download/dive_0.12.0_linux_amd64.deb
sudo dpkg -i dive_0.12.0_linux_amd64.deb
```

```bash
dive myimage:latest          # Analyze image layers
dive build -t myimage .      # Build + analyze
dive --ci myimage:latest     # CI mode (fail on inefficiency)
```

---

### ctop — Top for containers

```bash
sudo wget -qO /usr/local/bin/ctop https://github.com/bcicen/ctop/releases/latest/download/ctop-0.7.7-linux-amd64
sudo chmod +x /usr/local/bin/ctop
```

Real-time CPU, memory, network I/O for all containers.

---

### k9s — TUI for Kubernetes

```bash
curl -sS https://webi.sh/k9s | sh
```

```bash
k9s                         # Launch
:pods / :deploy / :svc      # Resource views
/pattern                    # Filter
l / s / d / e               # Logs / shell / describe / edit
:pulse                      # Cluster health
```

---

### stern — Multi-pod log tailing

```bash
go install github.com/stern/stern@latest
```

```bash
stern myapp                          # Tail all pods matching "myapp"
stern "web-.*" -n production         # Regex match in namespace
stern myapp --since 1h --include "ERROR"
```

---

## 10. Networking & Transfer

### trippy — Visual traceroute (Rust)

```bash
cargo install trippy
sudo trippy example.com
```

Combines ping + traceroute into a real-time, interactive TUI with per-hop latency charts.

---

### gping — Ping with graph (Rust)

```bash
cargo install gping
```

```bash
gping google.com                    # Ping with live graph
gping google.com cloudflare.com     # Compare multiple hosts
```

---

### croc — Simple file transfer

```bash
go install github.com/schollz/croc/v10@latest
```

```bash
croc send file.zip          # Sender gets a code
croc code-phrase             # Receiver enters code
```

End-to-end encrypted, works across networks. No server setup needed.

---

### magic-wormhole — Secure file transfer

```bash
pipx install magic-wormhole
```

```bash
wormhole send file.zip       # Generates wormhole code
wormhole receive             # Enter code to receive
```

---

### rclone — Cloud storage Swiss army knife

```bash
sudo apt install rclone
```

```bash
rclone config                        # Interactive setup
rclone sync /local/path remote:path  # Sync to cloud
rclone mount remote:path /mnt/cloud  # Mount cloud as filesystem
rclone copy remote:path /local/      # Download
```

Supports 40+ cloud providers: Google Drive, S3, Dropbox, OneDrive, etc.

---

### aria2 — Parallel download accelerator

```bash
sudo apt install aria2
```

```bash
aria2c -x 16 https://example.com/large-file.zip  # 16 connections
aria2c -i urls.txt                                # Batch download
aria2c 'magnet:?xt=urn:...'                      # BitTorrent
```

---

### termshark — TUI for Wireshark (Go)

```bash
go install github.com/gcla/termshark/v2/cmd/termshark@latest
```

```bash
sudo termshark -i eth0                # Capture live
termshark -r capture.pcap             # Read pcap file
```

---

## 11. Security & Encryption

### age — Modern file encryption

```bash
sudo apt install age
```

```bash
age-keygen -o key.txt                        # Generate key pair
age -r age1publickey... file.txt > file.enc  # Encrypt
age -d -i key.txt file.enc > file.txt        # Decrypt
tar cz ~/docs | age -r age1... > docs.tar.gz.age  # Encrypt archive
```

---

### pass — Unix password manager

```bash
sudo apt install pass
```

```bash
pass init GPG-KEY-ID                # Initialize store
pass insert email/gmail             # Add password
pass email/gmail                    # Retrieve (copies to clipboard)
pass generate web/github 24         # Generate 24-char password
pass git push                       # Sync via git
```

---

### sops — Encrypted secrets in files

```bash
go install github.com/getsops/sops/v3/cmd/sops@latest
```

```bash
sops -e secrets.yaml > secrets.enc.yaml   # Encrypt YAML
sops secrets.enc.yaml                     # Decrypt & edit
sops -d secrets.enc.yaml                  # Decrypt to stdout
```

Supports AGE, PGP, AWS KMS, GCP KMS. Only encrypts values, not keys — diffs remain readable.

---

### lynis — Security auditing

```bash
sudo apt install lynis
sudo lynis audit system              # Full security audit
```

---

## 12. Text & Data Processing

### miller (mlr) — CSV/JSON/TSV Swiss army knife

```bash
sudo apt install miller
```

```bash
mlr --csv head -n 5 data.csv              # First 5 rows
mlr --csv filter '$age > 30' data.csv     # Filter rows
mlr --csv sort-by -f salary data.csv      # Sort descending
mlr --csv stats1 -a mean -f salary data.csv  # Statistics
mlr --csv --json cat data.csv              # CSV to JSON
mlr --csv cut -f name,email data.csv       # Select columns
```

---

### xsv — Fast CSV toolkit (Rust)

```bash
cargo install xsv
```

```bash
xsv headers data.csv               # Show column names
xsv count data.csv                  # Row count
xsv select name,age data.csv       # Select columns
xsv search "pattern" data.csv      # Search rows
xsv sort -s name data.csv          # Sort
xsv join --left name a.csv name b.csv  # Join CSVs
xsv stats data.csv                  # Column statistics
xsv sample 100 data.csv            # Random sample
```

---

### jless — Interactive JSON viewer (Rust)

```bash
cargo install jless
```

```bash
cat data.json | jless              # Browse JSON interactively
jless data.json                    # Open file
```

Vim keybindings, collapsible nodes, search, copy paths.

---

### fx — Terminal JSON viewer (Go)

```bash
go install github.com/antonmedv/fx@latest
```

```bash
cat data.json | fx                 # Interactive viewer
cat data.json | fx '.users[0]'    # Apply expression
curl api.com | fx                  # Pipe API response
```

---

### pandoc — Universal document converter

```bash
sudo apt install pandoc
```

```bash
pandoc README.md -o README.html           # Markdown to HTML
pandoc README.md -o README.pdf            # Markdown to PDF
pandoc doc.docx -o doc.md                 # Word to Markdown
pandoc --from=html --to=markdown page.html  # HTML to Markdown
```

---

### pup — HTML CLI processor

```bash
go install github.com/ericchiang/pup@latest
```

```bash
curl -s example.com | pup 'title text{}'       # Extract title
curl -s example.com | pup 'a attr{href}'       # Extract links
curl -s example.com | pup 'div.content text{}' # CSS selector
```

---

## 13. Miscellaneous Power Tools

### GNU parallel — Run commands in parallel

```bash
sudo apt install parallel
```

```bash
ls *.jpg | parallel convert {} {.}.png     # Parallel image convert
cat urls.txt | parallel -j10 curl -O {}    # Download 10 at a time
seq 100 | parallel -j4 'echo processing {}'  # 4 parallel workers
find . -name '*.gz' | parallel gunzip      # Parallel decompress
```

---

### pv — Pipe Viewer (progress bar for pipes)

```bash
sudo apt install pv
```

```bash
pv bigfile.iso > /dev/sdb                  # Progress bar for dd-like ops
cat bigfile | pv | gzip > out.gz           # Progress on compression
pv -s $(du -sb file | cut -f1) file | gzip > out.gz  # With total size
```

---

### moreutils — Extra Unix tools

```bash
sudo apt install moreutils
```

| Tool | What it does |
|------|-------------|
| `sponge` | Soak up stdin, write to file (allows `sort file \| sponge file`) |
| `ts` | Timestamp each line (`command \| ts '[%H:%M:%S]'`) |
| `vidir` | Edit directory contents in your $EDITOR |
| `parallel` | Run multiple commands in parallel |
| `ifdata` | Get interface info without parsing ifconfig |
| `pee` | Tee to multiple commands |
| `chronic` | Only show output on error (great for cron) |

---

### trash-cli — Safe rm replacement

```bash
sudo apt install trash-cli
```

```bash
trash-put file.txt              # Move to trash (not rm!)
trash-list                      # Show trashed files
trash-restore                   # Restore from trash
trash-empty                     # Empty trash
```

Alias: `alias rm='trash-put'` (safer!)

---

### thefuck — Auto-correct commands

```bash
pipx install thefuck
echo 'eval "$(thefuck --alias)"' >> ~/.bashrc
```

```bash
git pussh    # Typo!
fuck         # Corrects to: git push
```

---

### asciinema — Record terminal sessions

```bash
sudo apt install asciinema
```

```bash
asciinema rec demo.cast           # Start recording
# ... do things ...
exit                               # Stop recording
asciinema play demo.cast          # Replay locally
asciinema upload demo.cast        # Share online
```

---

### vhs — Terminal GIF recorder (Go, by Charm)

```bash
go install github.com/charmbracelet/vhs@latest
```

Write a `.tape` script:
```
Output demo.gif
Set FontSize 14
Type "echo Hello World"
Enter
Sleep 2s
```

```bash
vhs demo.tape    # Renders to GIF/MP4/WebM
```

---

### gum — Shell script UI toolkit (Go, by Charm)

```bash
go install github.com/charmbracelet/gum@latest
```

```bash
gum choose "Option A" "Option B" "Option C"    # Selection menu
gum input --placeholder "Enter name"             # Text input
gum confirm "Are you sure?"                      # Yes/no prompt
gum spin --title "Loading..." -- sleep 3         # Spinner
gum write --placeholder "Enter description"      # Multi-line input
NAME=$(gum input) && echo "Hello $NAME"          # Use in scripts
```

---

### pet — CLI snippet manager (Go)

```bash
go install github.com/knqyf263/pet@latest
```

```bash
pet new                 # Add a new snippet
pet list                # List all snippets
pet search              # Fuzzy search snippets
pet exec                # Search + execute
pet sync                # Sync via Gist
```

---

## 14. Fun & Eye Candy

```bash
sudo apt install cmatrix           # Matrix rain
sudo apt install figlet            # ASCII art text
sudo apt install toilet            # Colored ASCII text
sudo apt install lolcat            # Rainbow text (pipe anything through it)
sudo apt install pipes.sh          # Animated pipes screensaver
sudo apt install cbonsai           # Growing ASCII bonsai
sudo apt install sl                # Steam locomotive (for mistyping 'ls')
```

```bash
echo "dubuntu" | figlet | lolcat   # Rainbow ASCII banner
cmatrix                            # Enter the Matrix
pipes.sh                           # Screensaver
cbonsai -l                         # Grow a bonsai
```

---

## 15. Shell Integration Block

Add to `~/.bashrc` to wire everything together:

```bash
# ─── Tool Initialization ─────────────────────────────────────────────────
eval "$(zoxide init bash)"          # Smarter cd
eval "$(fzf --bash)"               # Fuzzy finder integration
eval "$(starship init bash)"       # Cross-shell prompt
eval "$(direnv hook bash)"         # Per-directory environments
eval "$(mise activate bash)"       # Version manager

# ─── fzf + fd + bat Integration ──────────────────────────────────────────
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :200 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons {}'"

# ─── bat Configuration ───────────────────────────────────────────────────
export BAT_THEME="Catppuccin Mocha"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# ─── Modern Aliases ──────────────────────────────────────────────────────
alias ls='eza --icons'
alias ll='eza -lah --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons'
alias cat='bat --paging=never'
alias du='dust'
alias df='duf'
alias find='fd'
alias grep='rg'
alias tree='tre -e'
alias top='btop'
alias dig='doggo'
alias lg='lazygit'
alias ld='lazydocker'
```

---

## 16. One-Command Installer

A script to install the essentials is available at `scripts/install-cli-tools.sh` (see below).

```bash
#!/usr/bin/env bash
# Install essential CLI tools for Ubuntu
set -euo pipefail

echo "[*] Installing APT packages..."
sudo apt update && sudo apt install -y \
    bat eza fd-find ripgrep fzf zoxide \
    htop btop ncdu duf \
    git-delta hexyl \
    mc ranger nnn tig \
    jq pandoc miller \
    tmux micro \
    entr direnv \
    age pass trash-cli moreutils pv \
    asciinema figlet lolcat cmatrix \
    nvtop iotop iftop nethogs bmon vnstat \
    fastfetch inxi tealdeer glow \
    powertop lynis

echo "[*] Creating Ubuntu compatibility symlinks..."
mkdir -p ~/.local/bin
ln -sf /usr/bin/batcat ~/.local/bin/bat 2>/dev/null || true
ln -sf /usr/bin/fdfind ~/.local/bin/fd 2>/dev/null || true

echo "[*] Installing Rust tools via cargo..."
if command -v cargo &>/dev/null; then
    cargo install \
        yazi-fm yazi-cli \
        du-dust sd choose \
        tre-command \
        bottom --locked \
        procs \
        broot --locked \
        xplr --locked \
        watchexec-cli \
        just \
        grex \
        git-absorb \
        gitui --locked \
        silicon \
        hyperfine \
        tokei \
        zellij --locked \
        xh \
        jless \
        gping \
        bandwhich
    echo "[+] Rust tools installed"
else
    echo "[!] Rust/cargo not found. Run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
fi

echo "[*] Installing Go tools..."
if command -v go &>/dev/null; then
    go install github.com/jesseduffield/lazygit@latest
    go install github.com/jesseduffield/lazydocker@latest
    go install github.com/mr-karan/doggo/cmd/doggo@latest
    go install github.com/charmbracelet/glow@latest
    go install github.com/charmbracelet/gum@latest
    go install github.com/charmbracelet/vhs@latest
    go install github.com/schollz/croc/v10@latest
    go install github.com/knqyf263/pet@latest
    go install github.com/stern/stern@latest
    go install github.com/antonmedv/fx@latest
    go install github.com/ericchiang/pup@latest
    go install github.com/boyter/scc/v3@latest
    echo "[+] Go tools installed"
else
    echo "[!] Go not found. Run: sudo snap install go --classic"
fi

echo "[*] Installing Python tools via pipx..."
if command -v pipx &>/dev/null; then
    pipx install glances
    pipx install s-tui
    pipx install commitizen
    pipx install posting
    pipx install thefuck
    pipx install magic-wormhole
    echo "[+] Python tools installed"
else
    echo "[!] pipx not found. Run: sudo apt install pipx && pipx ensurepath"
fi

echo "[*] Installing starship prompt..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

echo "[*] Installing atuin shell history..."
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

echo "[*] Updating tldr pages..."
tldr --update 2>/dev/null || true

echo ""
echo "[+] All done! Restart your shell or run: source ~/.bashrc"
echo "[*] Don't forget to add the shell integration block from CLI-UserGuide.md to your .bashrc"
```

---

> **Total tools covered: 100+**
> Generated for the dubuntu-forge project on 2026-03-03.
