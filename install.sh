#!/usr/bin/env bash
# Dotfiles installation script
# Creates symlinks from home directory to dotfiles repo

set -e  # Exit on error

DOTFILES_DIR="$HOME/dotfiles"
DRY_RUN=false

# Check for dry-run flag
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "DRY RUN MODE - No changes will be made"
    echo ""
fi

echo "Installing dotfiles from $DOTFILES_DIR..."
echo ""

# Check and install dependencies
echo "Checking dependencies..."

# Check for xcape (for Caps Lock remapping)
if ! command -v xcape &> /dev/null; then
    echo "⚠️  xcape not found (for Caps Lock → Ctrl/Escape remapping)"

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would install xcape"
    else
        echo "Installing xcape..."

        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install xcape
            else
                echo "⚠️  Homebrew not found. Skipping xcape (optional)"
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            if command -v apt &> /dev/null; then
                echo "Installing via apt (requires sudo)..."
                sudo apt install -y xcape
            elif command -v pacman &> /dev/null; then
                echo "Installing via pacman (requires sudo)..."
                sudo pacman -S --noconfirm xcape
            elif command -v dnf &> /dev/null; then
                echo "Installing via dnf (requires sudo)..."
                sudo dnf install -y xcape
            else
                echo "⚠️  Package manager not detected. Skipping xcape (optional)"
            fi
        else
            echo "⚠️  Unsupported OS. Skipping xcape (optional)"
        fi

        # Verify installation
        if command -v xcape &> /dev/null; then
            echo "✓ xcape installed"
        else
            echo "⚠️  xcape installation failed (optional feature)"
        fi
    fi
else
    echo "✓ xcape found"
fi

echo ""

# Check for Node.js and npm (required for Neovim LSP servers)
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo "⚠️  Node.js/npm not found (required for Neovim LSP servers like pyright, dockerls)"

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would install nodejs and npm"
    else
        echo "Installing Node.js and npm..."

        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install node
            else
                echo "❌ Homebrew not found. Please install Node.js manually:"
                echo "   Visit: https://nodejs.org or run: brew install node"
                exit 1
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            if command -v apt &> /dev/null; then
                echo "Installing via apt (requires sudo)..."
                sudo apt update && sudo apt install -y nodejs npm
            elif command -v pacman &> /dev/null; then
                echo "Installing via pacman (requires sudo)..."
                sudo pacman -S --noconfirm nodejs npm
            elif command -v dnf &> /dev/null; then
                echo "Installing via dnf (requires sudo)..."
                sudo dnf install -y nodejs npm
            else
                echo "❌ Package manager not detected. Please install Node.js manually:"
                echo "   Visit: https://nodejs.org"
                exit 1
            fi
        else
            echo "❌ Unsupported OS. Please install Node.js manually:"
            echo "   Visit: https://nodejs.org"
            exit 1
        fi

        # Verify installation
        if command -v node &> /dev/null && command -v npm &> /dev/null; then
            echo "✓ Node.js $(node --version) and npm $(npm --version) installed"
        else
            echo "❌ Failed to install Node.js/npm"
            exit 1
        fi
    fi
else
    echo "✓ Node.js $(node --version) and npm $(npm --version) found"
fi

echo ""

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

# FZF configuration
link_file "$DOTFILES_DIR/fzf/fzf.zsh" "$HOME/.fzf.zsh"

# Ripgrep configuration
link_file "$DOTFILES_DIR/ripgrep/ripgreprc" "$HOME/.ripgreprc"

# VS Code configuration (platform-specific)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
else
    # Linux
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
    echo "  Skipping VS Code (not installed or directory not found)"
fi

echo ""
echo "✓ Dotfiles installed successfully!"
echo ""
echo "Remember to:"
echo "  - Restart your shell or run: source ~/.zshrc"
echo "  - Restart tmux or run: tmux source ~/.tmux.conf"
echo "  - Restart VS Code to apply new settings"
