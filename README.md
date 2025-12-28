# Dotfiles

Personal dotfiles for managing configuration across Linux and macOS systems.

## Contents

- **zsh**: Zsh shell configuration
- **tmux**: Terminal multiplexer configuration
- **neovim**: Neovim editor configuration
- **vscode**: Visual Studio Code settings, keybindings, and snippets
- **fzf**: Fuzzy finder configuration

## Prerequisites

### Common
- git
- zsh
- tmux
- neovim
- fzf

### macOS specific
```bash
brew install git zsh tmux neovim fzf
```

### Linux (Debian/Ubuntu)
```bash
sudo apt install git zsh tmux neovim fzf
```

### Linux (Arch)
```bash
sudo pacman -S git zsh tmux neovim fzf
```

## Installation

### First Time Setup

1. Clone this repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. Run the install script:
   ```bash
   ./install.sh
   ```

   This will:
   - Back up existing configuration files to `~/dotfiles_backup_TIMESTAMP/`
   - Create symlinks from the dotfiles repo to their proper locations
   - Set up configurations for all included applications

3. Restart your shell or source the new configuration:
   ```bash
   source ~/.zshrc
   ```

### Dry Run

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

## File Structure

```
dotfiles/
├── fzf/
│   └── fzf.zsh           -> ~/.fzf.zsh
├── nvim/
│   ├── init.lua          -> ~/.config/nvim/init.lua
│   └── lua/              -> ~/.config/nvim/lua/
├── tmux/
│   └── tmux.conf         -> ~/.tmux.conf
├── vscode/
│   ├── settings.json     -> ~/.config/Code/User/settings.json (Linux)
│   ├── keybindings.json  -> ~/.config/Code/User/keybindings.json
│   ├── mcp.json          -> ~/.config/Code/User/mcp.json
│   └── snippets/         -> ~/.config/Code/User/snippets/
├── zsh/
│   └── zshrc             -> ~/.zshrc
├── install.sh
├── uninstall.sh
└── README.md
```

## Adding New Dotfiles

1. Copy the configuration file to the appropriate directory in `~/dotfiles/`
2. Update `install.sh` to create the symlink
3. Update `uninstall.sh` to remove the symlink
4. Commit and push your changes

Example:
```bash
# Add a new bashrc file
cp ~/.bashrc ~/dotfiles/bash/bashrc
git add bash/bashrc
git commit -m "Add bashrc configuration"
git push
```

## Syncing Changes

### Pulling updates from a new machine
```bash
cd ~/dotfiles
git pull
./install.sh
```

### Pushing changes
```bash
cd ~/dotfiles
git add .
git commit -m "Update configuration"
git push
```

## Platform-Specific Notes

### macOS
- VS Code User directory is at `~/Library/Application Support/Code/User/`
- Install Xcode Command Line Tools: `xcode-select --install`

### Linux
- VS Code User directory is at `~/.config/Code/User/`
- Ensure you have the required packages installed for your distribution

## Troubleshooting

### Symlinks not working
- Check that the dotfiles directory is at `~/dotfiles`
- Ensure the install script has execute permissions: `chmod +x install.sh`
- Run with `--dry-run` to see what would be changed

### Shell configuration not loading
- Make sure zsh is your default shell: `chsh -s $(which zsh)`
- Restart your terminal or run: `source ~/.zshrc`

### VS Code settings not applying
- Check the symlink path matches your OS
- Verify VS Code is completely closed and reopened after installation

## License

Feel free to use and modify these configurations for your own use.
