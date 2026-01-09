# Dotfiles

Personal dotfiles for Linux systems.

## Installation

### 1. Install Packages

```bash
# Ubuntu/Debian
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update
sudo apt install git zsh tmux neovim fzf ripgrep ruby xclip nodejs npm xcape

# Arch
sudo pacman -S git zsh tmux neovim fzf ripgrep ruby xclip nodejs npm xcape
```

### 2. Clone and Install

```bash
git clone https://github.com/Cerre/dev-setup.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### 3. Post-Setup

```bash
# Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# fzf key bindings
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# TPM (Tmux Plugin Manager)
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Reload
source ~/.zshrc
```

### 4. Tmux Plugins

```bash
tmux
# Press: Ctrl+a then Shift+i
```

## Features

**Vim-Tmux Navigator**
- `Ctrl+h/j/k/l` - Navigate vim splits and tmux panes seamlessly

**Caps Lock**
- Tap = Escape
- Hold = Ctrl

**Tmux** (Prefix: `Ctrl+a`)
- `prefix + v` - Split vertical
- `prefix + h` - Split horizontal
- `Alt + h/l` - Switch windows

**FZF**
- `Ctrl+p` - File search
- `Ctrl+f` - Content search
- `Ctrl+r` - History

## Syncing

```bash
# Pull updates
cd ~/dotfiles && git pull && ./install.sh

# Push changes
cd ~/dotfiles && git add . && git commit -m "msg" && git push
```
