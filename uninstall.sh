#!/usr/bin/env bash

set -e

echo "=== Dotfiles Uninstallation Script ==="
echo ""

if [ "$1" = "--dry-run" ]; then
    DRY_RUN=true
    echo "DRY RUN MODE - No changes will be made"
    echo ""
fi

remove_symlink() {
    local target=$1

    if [ -L "$target" ]; then
        echo "Removing symlink: $target"
        if [ -z "$DRY_RUN" ]; then
            rm "$target"
            echo "  ✓ Removed"
        fi
    else
        echo "Not a symlink (skipping): $target"
    fi
}

echo "=== Removing symlinks ==="
remove_symlink "$HOME/.zshrc"
remove_symlink "$HOME/.fzf.zsh"
remove_symlink "$HOME/.ripgreprc"
remove_symlink "$HOME/.tmux.conf"
remove_symlink "$HOME/.config/nvim"

if [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
else
    VSCODE_USER_DIR="$HOME/.config/Code/User"
fi

remove_symlink "$VSCODE_USER_DIR/settings.json"
remove_symlink "$VSCODE_USER_DIR/keybindings.json"
remove_symlink "$VSCODE_USER_DIR/mcp.json"
remove_symlink "$VSCODE_USER_DIR/snippets"

echo ""
echo "=== Uninstallation Complete ==="

if [ -z "$DRY_RUN" ]; then
    echo "Symlinks have been removed."
    echo "Your dotfiles repository at ~/dotfiles is still intact."
    echo "Backup files (if any) are in ~/dotfiles_backup_* directories."
else
    echo "DRY RUN completed. Run without --dry-run to apply changes."
fi
