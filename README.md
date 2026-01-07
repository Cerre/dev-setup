# Dotfiles

Personal dotfiles for managing configuration across Linux and macOS systems.

## Contents

- **zsh**: Zsh shell configuration with fzf + ripgrep integration
- **tmux**: Terminal multiplexer configuration with vim-like keybindings
- **neovim**: Neovim editor configuration
- **vscode**: Visual Studio Code settings, keybindings, and snippets
- **fzf**: Fuzzy finder configuration
- **ripgrep**: Smart search configuration

## Prerequisites

### Common (Required)
- git
- zsh
- tmux
- neovim (0.8+ required for Kickstart config)
- fzf
- ripgrep
- ruby (for tmux-jump plugin)
- xclip (Linux only, for clipboard integration)

### Optional
- **VS Code** - For Neovim integration with debugging/Copilot (install before running `./install.sh`)
  - macOS: Download from [code.visualstudio.com](https://code.visualstudio.com) or `brew install --cask visual-studio-code`
  - Linux: Download from [code.visualstudio.com](https://code.visualstudio.com) or use snap: `sudo snap install code --classic`

### macOS specific
```bash
brew install git zsh tmux neovim fzf ripgrep ruby

# Optional: VS Code
brew install --cask visual-studio-code
```

### Linux (Debian/Ubuntu)
```bash
# Add Neovim stable PPA for version 0.9+
sudo add-apt-repository ppa:neovim-ppa/stable
sudo apt update

# Install all dependencies
sudo apt install git zsh tmux neovim fzf ripgrep ruby xclip

# Optional: VS Code
sudo snap install code --classic
```

### Linux (Arch)
```bash
sudo pacman -S git zsh tmux neovim fzf ripgrep ruby xclip

# Optional: VS Code
yay -S visual-studio-code-bin
```

## Installation

### First Time Setup

1. Clone this repository:
   ```bash
   git clone https://github.com/Cerre/dev-setup.git ~/dotfiles
   cd ~/dotfiles
   ```

2. Install Oh My Zsh (required by zshrc):
   ```bash
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```

3. Install fzf (fuzzy finder):
   ```bash
   git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
   ~/.fzf/install
   ```

4. Install TPM (Tmux Plugin Manager):
   ```bash
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ```

5. Run the install script:
   ```bash
   ./install.sh
   ```

   This will:
   - Back up existing configuration files to `.backup` files
   - Create symlinks from the dotfiles repo to their proper locations
   - Set up configurations for all included applications

6. Install tmux plugins (open tmux and press `prefix + I`):
   ```bash
   tmux
   # Inside tmux, press: Ctrl+Space then Shift+i
   ```

7. Restart your shell or source the new configuration:
   ```bash
   source ~/.zshrc
   ```

   Neovim plugins will auto-install on first launch.

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

## Testing

### Test Installation with Docker

Before deploying to a new machine, you can test the installation in a clean Docker container:

```bash
# Build and test
./test-install.sh

# Then run the container interactively
docker run -it --rm dotfiles-test

# Or test specific commands
docker run --rm dotfiles-test zsh -c 'ls -la ~/.zshrc ~/.tmux.conf'
docker run -it --rm dotfiles-test tmux
```

This creates a fresh Ubuntu 22.04 environment, installs all dependencies, and runs your install script - exactly like setting up a new machine.

### For Ansible/Automation

If you're using Ansible for work, you can create a playbook that:
1. Clones this repository
2. Installs prerequisites (zsh, tmux, neovim, fzf, ripgrep, ruby, xclip)
3. Installs Oh My Zsh and fzf
4. Runs the install script
5. Installs TPM and tmux plugins

The Dockerfile.test serves as a reference for the exact steps needed.

## Platform-Specific Notes

### macOS
- VS Code User directory is at `~/Library/Application Support/Code/User/`
- Install Xcode Command Line Tools: `xcode-select --install`

### Linux
- VS Code User directory is at `~/.config/Code/User/`
- Ensure you have the required packages installed for your distribution

## VS Code + Neovim Integration

This setup integrates your Neovim configuration directly into VS Code using the VSCode Neovim extension. You get the best of both worlds: Neovim's editing power with VS Code's debugging, Copilot, and GUI features.

**Note:** VS Code is optional. The dotfiles work perfectly fine without it for terminal-only workflows. Install VS Code only if you want the integrated experience.

### Setup

1. **Install VS Code first** (see Prerequisites section above)
   - macOS: `brew install --cask visual-studio-code`
   - Linux: `sudo snap install code --classic`
   - Or download from [code.visualstudio.com](https://code.visualstudio.com)

2. Run `./install.sh` - this will automatically detect VS Code and symlink all configs
   - If VS Code is not installed, the script will skip VS Code configuration (no errors)

3. Open VS Code - it will prompt you to install recommended extensions

4. Install the "VSCode Neovim" extension (should be recommended automatically)
   - Or manually: Ctrl+Shift+X → search "VSCode Neovim" by asvetliakov → Install

5. Restart VS Code completely for changes to take effect

### How It Works

- **Editing Engine**: VS Code uses your actual Neovim binary (from `~/.config/nvim/init.lua`)
- **Keybindings**: Your Neovim leader key mappings work in VS Code
- **Muscle Memory**: Same shortcuts as terminal Neovim

### Key Mappings

All your Neovim keybindings work in VS Code:

**File Navigation** (Telescope → VS Code equivalents):
- `<space>sf` - Quick Open (file finder)
- `<space>sg` - Search in files (grep)
- `<space><space>` - Show all open editors (buffers)
- `<space>sh` - Command palette (help)
- `-` - Toggle file explorer focus (Oil.nvim equivalent)

**LSP Operations** (matching your Neovim `gr*` prefix):
- `grd` - Go to definition
- `grr` - Find references
- `gri` - Go to implementation
- `grn` - Rename symbol
- `gra` - Code actions (quick fix)
- `grt` - Go to type definition
- `K` - Show hover documentation

**Debugging** (VS Code specific):
- `<space>db` - Toggle breakpoint
- `<space>ds` - Start debugging
- `<space>dc` - Continue
- `<space>dx` - Stop debugging

**Terminal**:
- `Ctrl+\`` - Toggle integrated terminal

### Editor Features

- **Relative line numbers** - Just like Neovim
- **Vim modes** - Normal, Insert, Visual with proper cursor shapes
- **System clipboard** - Yank/paste works across apps
- **Smart suggestions** - Works with Vim motions

### Workflow Recommendations

Use **terminal Neovim** for:
- Quick file edits
- Fast navigation
- Terminal-based workflows
- Lightweight operations

Use **VS Code + Neovim** for:
- Visual debugging sessions
- GitHub Copilot assistance
- Complex refactoring with GUI
- Multi-file project navigation
- Language-specific tooling

Since both use the same keybindings, switching between them has zero context-switching cost.

### Troubleshooting

**Neovim extension not working:**
- Check that Neovim is installed: `which nvim`
- Verify path in settings.json matches your Neovim location
- Check VS Code output panel for errors (View → Output → Neovim)

**Keybindings not working:**
- Ensure you're in normal mode (press `Esc`)
- Check that keybindings.json is properly symlinked
- Verify `neovim.mode` context in keybindings

**Performance issues:**
- Some Neovim plugins may not work well in VS Code context
- Disable heavy plugins in VS Code if needed
- Check VS Code's Neovim extension settings

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
