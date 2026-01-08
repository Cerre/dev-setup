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

# Update package lists once (if on Linux with apt)
if [[ "$OSTYPE" == "linux-gnu"* ]] && command -v apt &> /dev/null; then
    if [ "$DRY_RUN" = false ]; then
        echo "Updating package lists..."
        # Ignore warnings from broken repos (like Spotify)
        sudo apt update --allow-releaseinfo-change 2>&1 | grep -v "^W:" | grep -v "Spotify" || true
        echo ""
    fi
fi

# Function to check and install a package
install_package() {
    local package_name="$1"
    local command_name="${2:-$1}"  # Use package name as command name if not specified
    local description="$3"

    if command -v "$command_name" &> /dev/null; then
        echo "✓ $package_name found"
        return 0
    fi

    echo "⚠️  $package_name not found${description:+ ($description)}"

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would install $package_name"
        return 0
    fi

    echo "Installing $package_name..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install "$package_name" || echo "⚠️  Failed to install $package_name"
        else
            echo "⚠️  Homebrew not found. Please install manually: brew install $package_name"
            return 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt &> /dev/null; then
            sudo apt install -y "$package_name" || echo "⚠️  Failed to install $package_name"
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm "$package_name" || echo "⚠️  Failed to install $package_name"
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y "$package_name" || echo "⚠️  Failed to install $package_name"
        else
            echo "⚠️  Package manager not detected. Please install manually"
            return 1
        fi
    else
        echo "⚠️  Unsupported OS. Please install manually"
        return 1
    fi

    # Verify installation
    if command -v "$command_name" &> /dev/null; then
        echo "✓ $package_name installed successfully"
        return 0
    else
        echo "⚠️  $package_name installation failed"
        return 1
    fi
}

# Core tools (required for dotfiles to work)
echo "Core tools:"
install_package "git" "git" "version control"
install_package "zsh" "zsh" "shell"
install_package "tmux" "tmux" "terminal multiplexer"

# Neovim (may need PPA on Ubuntu)
if ! command -v nvim &> /dev/null; then
    echo "⚠️  neovim not found (text editor)"

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would install neovim"
    else
        echo "Installing neovim..."

        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install neovim || echo "⚠️  Failed to install neovim"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command -v apt &> /dev/null; then
                # Try to add PPA for newer version
                sudo add-apt-repository -y ppa:neovim-ppa/stable 2>/dev/null || true
                sudo apt install -y neovim || echo "⚠️  Failed to install neovim"
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm neovim || echo "⚠️  Failed to install neovim"
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y neovim || echo "⚠️  Failed to install neovim"
            fi
        fi

        if command -v nvim &> /dev/null; then
            echo "✓ neovim installed successfully"
        else
            echo "⚠️  neovim installation failed"
        fi
    fi
else
    echo "✓ neovim found"
fi

install_package "fzf" "fzf" "fuzzy finder"
install_package "ripgrep" "rg" "fast grep alternative"
install_package "ruby" "ruby" "for tmux-jump plugin"

# xclip (Linux only, for clipboard)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    install_package "xclip" "xclip" "clipboard integration"
fi

echo ""

# Optional tools
echo "Optional tools:"

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
                brew install node || echo "⚠️  Failed to install Node.js"
            else
                echo "⚠️  Homebrew not found. Skipping Node.js (optional)"
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            if command -v apt &> /dev/null; then
                sudo apt install -y nodejs npm || echo "⚠️  Failed to install Node.js/npm"
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm nodejs npm || echo "⚠️  Failed to install Node.js/npm"
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y nodejs npm || echo "⚠️  Failed to install Node.js/npm"
            else
                echo "⚠️  Package manager not detected. Skipping Node.js (optional)"
            fi
        else
            echo "⚠️  Unsupported OS. Skipping Node.js (optional)"
        fi

        # Verify installation
        if command -v node &> /dev/null && command -v npm &> /dev/null; then
            echo "✓ Node.js $(node --version) and npm $(npm --version) installed"
        else
            echo "⚠️  Node.js/npm not installed - LSP servers may not work"
            echo "   Install manually with: sudo apt install nodejs npm"
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
