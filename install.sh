#!/usr/bin/env bash
# Simple dotfiles installation - just creates symlinks
# Install packages manually first (see README)

set -e

DOTFILES_DIR="$HOME/dotfiles"
DRY_RUN=false

if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "DRY RUN MODE - No changes will be made"
    echo ""
fi

echo "Installing dotfiles from $DOTFILES_DIR..."

# Function to create symlink with backup
link_file() {
    local src="$1"
    local dest="$2"

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would link $dest -> $src"
        if [ -e "$dest" ] && [ ! -L "$dest" ]; then
            echo "  [DRY RUN] Would backup existing $dest to ${dest}.backup"
        fi
        return
    fi

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

# Core configurations
link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
link_file "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/fzf/fzf.zsh" "$HOME/.fzf.zsh"
link_file "$DOTFILES_DIR/ripgrep/ripgreprc" "$HOME/.ripgreprc"

# VS Code configuration (platform-specific)
if [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
else
    VSCODE_USER_DIR="$HOME/.config/Code/User"
fi

if [ -d "$(dirname "$VSCODE_USER_DIR")" ] || [ "$DRY_RUN" = true ]; then
    mkdir -p "$VSCODE_USER_DIR"
    link_file "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
    link_file "$DOTFILES_DIR/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
    link_file "$DOTFILES_DIR/vscode/mcp.json" "$VSCODE_USER_DIR/mcp.json"
    link_file "$DOTFILES_DIR/vscode/extensions.json" "$VSCODE_USER_DIR/extensions.json"
    link_file "$DOTFILES_DIR/vscode/snippets" "$VSCODE_USER_DIR/snippets"
else
    echo "  Skipping VS Code (not installed)"
fi

echo ""
echo "✓ Dotfiles installed successfully!"
echo ""
echo "Remember to:"
echo "  - Restart your shell or run: source ~/.zshrc"
echo "  - Restart tmux or run: tmux source ~/.tmux.conf"
echo "  - Restart VS Code to apply new settings"
