#!/usr/bin/env bash

set -e

DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "=== Dotfiles Installation Script ==="
echo "Dotfiles directory: $DOTFILES_DIR"
echo ""

if [ "$1" = "--dry-run" ]; then
    DRY_RUN=true
    echo "DRY RUN MODE - No changes will be made"
    echo ""
fi

backup_if_exists() {
    local file=$1
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        mkdir -p "$BACKUP_DIR"
        echo "  Backing up existing file: $file"
        if [ -z "$DRY_RUN" ]; then
            mv "$file" "$BACKUP_DIR/"
        fi
    fi
}

create_symlink() {
    local source=$1
    local target=$2

    echo "Linking: $target -> $source"

    if [ ! -e "$source" ]; then
        echo "  ERROR: Source file does not exist: $source"
        return 1
    fi

    backup_if_exists "$target"

    if [ -L "$target" ]; then
        echo "  Removing existing symlink: $target"
        if [ -z "$DRY_RUN" ]; then
            rm "$target"
        fi
    fi

    if [ -z "$DRY_RUN" ]; then
        ln -s "$source" "$target"
        echo "  ✓ Created symlink"
    fi
}

echo "=== Setting up shell configuration ==="
create_symlink "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"

echo ""
echo "=== Setting up fzf ==="
create_symlink "$DOTFILES_DIR/fzf/fzf.zsh" "$HOME/.fzf.zsh"

echo ""
echo "=== Setting up tmux ==="
create_symlink "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"

echo ""
echo "=== Setting up neovim ==="
mkdir -p "$HOME/.config"
create_symlink "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

echo ""
echo "=== Setting up VS Code ==="
if [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
else
    VSCODE_USER_DIR="$HOME/.config/Code/User"
fi

mkdir -p "$VSCODE_USER_DIR"
create_symlink "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
create_symlink "$DOTFILES_DIR/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
create_symlink "$DOTFILES_DIR/vscode/mcp.json" "$VSCODE_USER_DIR/mcp.json"
create_symlink "$DOTFILES_DIR/vscode/snippets" "$VSCODE_USER_DIR/snippets"

echo ""
echo "=== Installation Complete ==="

if [ -d "$BACKUP_DIR" ]; then
    echo "Backup of original files: $BACKUP_DIR"
fi

if [ -z "$DRY_RUN" ]; then
    echo ""
    echo "Your dotfiles have been symlinked successfully!"
    echo "You may need to restart your shell or run: source ~/.zshrc"
else
    echo ""
    echo "DRY RUN completed. Run without --dry-run to apply changes."
fi
