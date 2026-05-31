#!/usr/bin/env bash
# Dotfiles bootstrap + install (Ubuntu).
#
# Idempotent: safe to re-run. It will
#   1. install system packages (apt + Neovim PPA)
#   2. bootstrap Oh My Zsh, fzf, and TPM (if missing)
#   3. symlink all configs into place
#   4. install Neovim plugins (pinned via lazy-lock.json) and tmux plugins
#
# Usage:
#   ./install.sh              # full bootstrap
#   SKIP_APT=1 ./install.sh   # skip system package install (already provisioned)
#   SKIP_PLUGINS=1 ./install.sh  # skip nvim/tmux plugin install
#
# For air-gapped / offline installation, see OFFLINE.md.

set -euo pipefail

# Resolve the repo dir from this script's location (works wherever it's cloned).
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run apt/etc. with sudo unless we're already root (e.g. in Docker).
SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

echo "Installing dotfiles from $DOTFILES_DIR..."

# ---------------------------------------------------------------------------
# 1. System packages
# ---------------------------------------------------------------------------
install_packages() {
    echo "==> Installing system packages..."
    $SUDO apt-get update
    # software-properties-common provides add-apt-repository (for the nvim PPA)
    $SUDO apt-get install -y software-properties-common curl

    # Neovim 0.11+ is required; the distro package is usually too old.
    if ! command -v nvim >/dev/null 2>&1; then
        $SUDO add-apt-repository -y ppa:neovim-ppa/unstable
        $SUDO apt-get update
    fi

    $SUDO apt-get install -y \
        git zsh tmux neovim \
        ripgrep xclip bat zoxide \
        nodejs npm \
        make build-essential \
        python3 python3-venv \
        ruby \
        fonts-jetbrains-mono
}

if [ -z "${SKIP_APT:-}" ]; then
    install_packages
else
    echo "==> SKIP_APT set, skipping system package install."
fi

# ---------------------------------------------------------------------------
# 2. Bootstrap shell ecosystem (Oh My Zsh, fzf, TPM)
#    NOTE: fzf must be installed BEFORE we symlink ~/.fzf.zsh below, otherwise
#    fzf's installer would write through our symlink and dirty the repo.
# ---------------------------------------------------------------------------
echo "==> Bootstrapping Oh My Zsh / fzf / TPM..."

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        "" --unattended --keep-zshrc
fi

if [ ! -d "$HOME/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    # We only need the fzf binary: fzf/fzf.zsh generates key-bindings at runtime
    # via `fzf --zsh`. Run this ONLY on first bootstrap — on re-runs ~/.fzf.zsh is
    # already a symlink into this repo, and the full installer would write through
    # it and dirty the repo.
    "$HOME/.fzf/install" --bin
fi

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# ---------------------------------------------------------------------------
# 3. Symlink configs
# ---------------------------------------------------------------------------
link_file() {
    local src="$1"
    local dest="$2"

    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        echo "  Backing up $dest to ${dest}.backup"
        mv "$dest" "${dest}.backup"
    fi

    echo "  Linking $dest -> $src"
    ln -sf "$src" "$dest"
}

echo "==> Symlinking configs..."
mkdir -p "$HOME/.config"

link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
link_file "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/fzf/fzf.zsh" "$HOME/.fzf.zsh"
link_file "$DOTFILES_DIR/ripgrep/ripgreprc" "$HOME/.ripgreprc"

# bat is installed as batcat on Ubuntu/Debian — create a bat alias on PATH.
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    echo "  Linked bat -> batcat"
fi

# Yazi file manager config
mkdir -p "$HOME/.config/yazi"
link_file "$DOTFILES_DIR/yazi/yazi.toml" "$HOME/.config/yazi/yazi.toml"

# Ghostty (optional - only if config dir exists or ghostty is installed)
if command -v ghostty >/dev/null 2>&1 || [ -d "$HOME/.config/ghostty" ]; then
    mkdir -p "$HOME/.config/ghostty"
    link_file "$DOTFILES_DIR/ghostty/config.ghostty" "$HOME/.config/ghostty/config"
    echo "  Ghostty config linked"
fi

# VS Code (optional - only if installed)
if [ -d "$HOME/.config/Code/User" ]; then
    link_file "$DOTFILES_DIR/vscode/settings.json" "$HOME/.config/Code/User/settings.json"
    link_file "$DOTFILES_DIR/vscode/keybindings.json" "$HOME/.config/Code/User/keybindings.json"
    echo "  VS Code configs linked"
fi

# ---------------------------------------------------------------------------
# 4. Install plugins
# ---------------------------------------------------------------------------
if [ -z "${SKIP_PLUGINS:-}" ]; then
    echo "==> Installing Neovim plugins (pinned via lazy-lock.json)..."
    # restore = install missing plugins and check them out to the locked commits.
    nvim --headless "+Lazy! restore" +qa || true

    echo "==> Installing tmux plugins..."
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
else
    echo "==> SKIP_PLUGINS set, skipping plugin install."
fi

echo ""
echo "Dotfiles installed."
echo ""
echo "Next steps:"
echo "  - Set zsh as your default shell:  chsh -s \"\$(which zsh)\"  (then log out/in)"
echo "  - Open a new terminal, or run:    source ~/.zshrc"
echo "  - On first 'nvim' launch, Mason finishes installing LSPs/formatters."
