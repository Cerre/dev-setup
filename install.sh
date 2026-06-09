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
        ripgrep fd-find xclip bat zoxide \
        nodejs npm \
        make build-essential \
        python3 python3-venv \
        ruby \
        fonts-jetbrains-mono

    # lazygit (terminal git UI) is not in the Ubuntu archive — fetch the pinned
    # release binary. Skipped if already present.
    if ! command -v lazygit >/dev/null 2>&1; then
        echo "==> Installing lazygit $LAZYGIT_VERSION..."
        local arch tmp
        arch="$(uname -m)"
        case "$arch" in
            x86_64) arch="x86_64" ;;
            aarch64 | arm64) arch="arm64" ;;
        esac
        tmp="$(mktemp -d)"
        curl -fsSL -o "$tmp/lazygit.tar.gz" \
            "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${arch}.tar.gz"
        tar -xf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
        $SUDO install "$tmp/lazygit" /usr/local/bin/lazygit
        rm -rf "$tmp"
    fi
}

# Pinned lazygit version (see OFFLINE.md, channel 3).
LAZYGIT_VERSION="0.44.1"

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

# fd is installed as fdfind on Ubuntu/Debian — create an fd alias on PATH.
# Telescope and telescope-file-browser use fd for fast, gitignore-aware file finding.
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    echo "  Linked fd -> fdfind"
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

# Bind Ctrl+Alt+T to Ghostty on GNOME (replaces the built-in gnome-terminal
# launcher). Only runs on a GNOME desktop (gsettings + media-keys schema) with
# Ghostty installed. Idempotent: re-running just re-asserts the same values.
if command -v ghostty >/dev/null 2>&1 && command -v gsettings >/dev/null 2>&1 \
    && gsettings list-schemas 2>/dev/null | grep -qx 'org.gnome.settings-daemon.plugins.media-keys'; then
    echo "==> Binding Ctrl+Alt+T -> Ghostty (GNOME)..."
    mk='org.gnome.settings-daemon.plugins.media-keys'
    kb_path='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ghostty/'

    # Free Ctrl+Alt+T from the built-in gnome-terminal launcher.
    gsettings set "$mk" terminal "[]" 2>/dev/null || true

    # Register our custom slot without clobbering any other custom keybindings.
    current="$(gsettings get "$mk" custom-keybindings)"
    case "$current" in
        *"$kb_path"*) : ;;                                     # already registered
        '@as []' | '[]') gsettings set "$mk" custom-keybindings "['$kb_path']" ;;
        *) gsettings set "$mk" custom-keybindings "${current%]*}, '$kb_path']" ;;
    esac

    gsettings set "$mk.custom-keybinding:$kb_path" name 'Ghostty'
    gsettings set "$mk.custom-keybinding:$kb_path" command "$(command -v ghostty)"
    gsettings set "$mk.custom-keybinding:$kb_path" binding '<Control><Alt>t'
    echo "  Ctrl+Alt+T bound to Ghostty"
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
