#!/usr/bin/env bash
#
# Appends CLI tool integrations to ~/.zshrc
# Safe to run multiple times — checks for existing block before appending.
#
set -euo pipefail

MARKER="# ─── dubuntu-forge CLI tools ─────────────────────────────────────────────"

if grep -qF "$MARKER" ~/.zshrc 2>/dev/null; then
    echo "[!] Block already exists in ~/.zshrc — skipping."
    echo "    To re-apply, remove the dubuntu-forge block from ~/.zshrc first."
    exit 0
fi

cat >> ~/.zshrc << 'ZSHBLOCK'

# ─── dubuntu-forge CLI tools ─────────────────────────────────────────────

# ─── Tool Initialization (silently skips missing tools) ──────────────────
command -v zoxide   &>/dev/null && eval "$(zoxide init zsh)"
command -v fzf      &>/dev/null && eval "$(fzf --zsh)"
command -v starship &>/dev/null && eval "$(starship init zsh)"
command -v direnv   &>/dev/null && eval "$(direnv hook zsh)"
command -v mise     &>/dev/null && eval "$(mise activate zsh)"
command -v thefuck  &>/dev/null && eval "$(thefuck --alias)"
command -v atuin    &>/dev/null && eval "$(atuin init zsh)"

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

# ─── end dubuntu-forge CLI tools ─────────────────────────────────────────
ZSHBLOCK

echo "[+] CLI tool block appended to ~/.zshrc"
echo "[*] Run: exec zsh   (to reload)"
