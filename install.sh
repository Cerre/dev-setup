#!/usr/bin/env bash
# Dotfiles installation - creates symlinks (Linux only)

set -e

DOTFILES_DIR="$HOME/dotfiles"

echo "Installing dotfiles from $DOTFILES_DIR..."

# Function to create symlink with backup
link_file() {
    local src="$1"
    local dest="$2"

    # Backup existing file if it exists and isn't already a symlink
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        echo "  Backing up $dest to ${dest}.backup"
        mv "$dest" "${dest}.backup"
    fi

    echo "  Linking $dest -> $src"
    ln -sf "$src" "$dest"
}

# Create config directory
mkdir -p "$HOME/.config"

# Link configs
link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
link_file "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/fzf/fzf.zsh" "$HOME/.fzf.zsh"
link_file "$DOTFILES_DIR/ripgrep/ripgreprc" "$HOME/.ripgreprc"

echo ""
echo "✓ Dotfiles installed!"
echo ""
echo "Next steps:"
echo "  source ~/.zshrc"
echo "  tmux source ~/.tmux.conf (if in tmux)"
