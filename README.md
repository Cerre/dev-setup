# Dotfiles

Personal dotfiles for managing configuration across Linux and macOS systems.

## Contents

- **zsh**: Zsh shell configuration with fzf + ripgrep integration
- **tmux**: Terminal multiplexer configuration with vim-like keybindings and vim-tmux-navigator
- **neovim**: Neovim editor configuration (Kickstart.nvim)
- **vscode**: Visual Studio Code settings, keybindings, and snippets
- **fzf**: Fuzzy finder configuration
- **ripgrep**: Smart search configuration

## Installation

### 1. Install Prerequisites

**Ubuntu/Debian:**
```bash
# Add neovim PPA for latest version (0.10+)
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update

# Install all required packages
sudo apt install git zsh tmux neovim fzf ripgrep ruby xclip nodejs npm xcape
```

**Arch:**
```bash
sudo pacman -S git zsh tmux neovim fzf ripgrep ruby xclip nodejs npm xcape
```

**macOS:**
```bash
brew install git zsh tmux neovim fzf ripgrep ruby node xcape
```

### 2. Clone Repository

```bash
git clone https://github.com/Cerre/dev-setup.git ~/dotfiles
cd ~/dotfiles
```

**Important:** Must be cloned to `~/dotfiles` exactly (the install script expects this path).

### 3. Run Install Script

```bash
./install.sh
```

This creates symlinks from your dotfiles repo to the proper config locations and backs up any existing configs to `.backup` files.

### 4. Post-Installation Setup

```bash
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install fzf key bindings
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# Install TPM (Tmux Plugin Manager)
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Reload shell
source ~/.zshrc
```

### 5. Install Tmux Plugins

```bash
# Open tmux
tmux

# Inside tmux, press: Ctrl+a then Shift+i
```

Neovim plugins will auto-install on first launch.

## Optional: VS Code

If you want VS Code integration:

```bash
# Ubuntu/Debian
sudo snap install code --classic

# macOS
brew install --cask visual-studio-code

# Then re-run install script to symlink VS Code configs
cd ~/dotfiles && ./install.sh
```

## Dry Run

To preview changes without making them:
```bash
./install.sh --dry-run
```

## Uninstallation

To remove symlinks and restore your system:
```bash
./uninstall.sh
```

Your original configuration files will be in the backup directory.

## Key Features

### Vim-Tmux Navigator
- Seamless navigation between neovim splits and tmux panes with `Ctrl+h/j/k/l`
- Context-aware: moves between vim splits when inside vim, switches tmux panes at edges
- `Ctrl+\` to jump to previous pane/split

### Caps Lock Remapping
- Caps Lock acts as Escape when tapped (<200ms)
- Caps Lock acts as Ctrl when held
- Requires xcape

### Neovim
- Kickstart.nvim configuration
- LSP servers for Python, Docker, Lua
- vim-tmux-navigator integration
- Oil.nvim file explorer

### Tmux
- Prefix: `Ctrl+a`
- Vi-mode for copy mode
- Nord theme status bar
- Gruvbox theme for panes
- tmux-thumbs for quick text copying
- tmux-jump for text navigation

### FZF Integration
- `Ctrl+p`: Fuzzy file search
- `Ctrl+f`: Search file contents with ripgrep
- `Ctrl+e`: Search tags

## Syncing Changes

### Pull updates on a new machine
```bash
cd ~/dotfiles
git pull
./install.sh
```

### Push changes
```bash
cd ~/dotfiles
git add .
git commit -m "Update configuration"
git push
```

## Testing

Test the installation in a clean Docker container:

```bash
./test-install.sh
```

## Troubleshooting

### Symlinks not working
- Check that the dotfiles directory is at `~/dotfiles`
- Run with `--dry-run` to see what would be changed

### Shell configuration not loading
- Make sure zsh is your default shell: `chsh -s $(which zsh)`
- Restart your terminal or run: `source ~/.zshrc`

### Neovim plugins not loading
- Ensure neovim 0.10+ is installed: `nvim --version`
- Open neovim and run `:Lazy sync`
- Check `:checkhealth` for issues

### Tmux plugins not working
- Make sure TPM is installed: `ls ~/.tmux/plugins/tpm`
- Inside tmux, press `Ctrl+a` then `Shift+i` to install

## License

Feel free to use and modify these configurations for your own use.
