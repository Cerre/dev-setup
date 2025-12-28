#!/usr/bin/env bash
# Dotfiles installation script
# Creates symlinks from home directory to dotfiles repo

set -e  # Exit on error

DOTFILES_DIR="$HOME/dotfiles"

echo "Installing dotfiles from $DOTFILES_DIR..."

# Function to create symlink with backup
link_file() {
    local src="$1"
    local dest="$2"

    # Backup existing file if it exists and isn't already a symlink
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        echo "  Backing up existing $dest to ${dest}.backup"
        mv "$dest" "${dest}.backup"
    fi

    # Create symlink
    echo "  Linking $dest -> $src"
    ln -sf "$src" "$dest"
}

# Ensure .config directory exists
mkdir -p "$HOME/.config"

# Create symlinks
link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
link_file "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"

echo "✓ Dotfiles installed successfully!"
echo ""
echo "Remember to:"
echo "  - Restart your shell or run: source ~/.zshrc"
echo "  - Restart tmux or run: tmux source ~/.tmux.conf"
