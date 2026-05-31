# Dotfiles

Personal dotfiles for Ubuntu: Neovim (kickstart-based), tmux, zsh, fzf, ripgrep,
Yazi, Ghostty, and VS Code.

## Quick install

```bash
git clone https://github.com/Cerre/dev-setup.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` is idempotent and does everything:

1. installs system packages (apt + the Neovim PPA),
2. bootstraps Oh My Zsh, fzf, and TPM,
3. symlinks all configs into place,
4. installs Neovim plugins (pinned via `lazy-lock.json`) and tmux plugins.

Then set zsh as your default shell and reload:

```bash
chsh -s "$(which zsh)"   # log out and back in for this to take effect
source ~/.zshrc
```

On the first `nvim` launch, Mason finishes installing the LSPs/formatters
(`basedpyright`, `dockerls`, `lua_ls`, `stylua`, `debugpy`).

> **Air-gapped / offline install?** See [OFFLINE.md](OFFLINE.md) for the complete
> bill-of-materials (every package, repo, and binary with pinned versions) and
> staging instructions.

### Useful flags

```bash
SKIP_APT=1 ./install.sh       # machine is already provisioned; skip apt
SKIP_PLUGINS=1 ./install.sh   # symlink only; skip nvim/tmux plugin install
```

### Machine-specific config

Anything personal to one machine (extra `PATH` entries, project shortcuts, etc.)
goes in `~/.zshrc.local`, which the tracked `zshrc` sources at the end if it
exists. It is never committed.

## Dependencies

Installed automatically by `install.sh`. Listed here for reference / approval.

**System packages (apt):**
`git zsh tmux ripgrep xclip bat zoxide nodejs npm curl software-properties-common make build-essential python3 python3-venv ruby fonts-jetbrains-mono`

- `make` / `build-essential` — build telescope-fzf-native, LuaSnip, Treesitter parsers
- `python3` / `python3-venv` — basedpyright venv detection, debugpy
- `ruby` — the `tmux-jump` plugin
- `nodejs` / `npm` — node-based LSP servers
- `fonts-jetbrains-mono` — the config assumes a Nerd Font (install the real
  *JetBrainsMono Nerd Font* for full glyph coverage)

**Neovim:** 0.11+ required (the kickstart config refuses to load on the older
distro package), installed from `ppa:neovim-ppa/unstable`.

**Bootstrapped (cloned/installed, not via apt):** Oh My Zsh, fzf, TPM.

**Auto-installed on first use:** ~30 Neovim plugins via lazy.nvim (pinned in
`lazy-lock.json`); `basedpyright`, `dockerls`, `lua_ls`, `stylua`, `debugpy` via
Mason; `tmux-jump` via TPM.

## Manual install (fallback)

If you'd rather not run `install.sh`, or it fails partway:

```bash
# 1. System packages
sudo apt update
sudo apt install -y software-properties-common curl
sudo add-apt-repository -y ppa:neovim-ppa/unstable
sudo apt update
sudo apt install -y git zsh tmux neovim ripgrep xclip bat zoxide nodejs npm \
  make build-essential python3 python3-venv ruby fonts-jetbrains-mono

# 2. Oh My Zsh, fzf, TPM (do this BEFORE step 3 — install.sh symlinks ~/.fzf.zsh,
#    and running fzf's installer after that would write through the symlink)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all --no-update-rc
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# 3. Symlinks only
SKIP_APT=1 SKIP_PLUGINS=1 ./install.sh

# 4. Plugins: open nvim (lazy.nvim auto-installs), and in tmux press Ctrl+a then Shift+i
```

**Debian / Raspberry Pi OS (no PPA):** install Neovim from the official tarball
instead of the PPA:

```bash
ARCH=$(uname -m); case $ARCH in aarch64) ARCH=arm64 ;; x86_64) ARCH=x86_64 ;; esac
curl -fsSL -o /tmp/nvim.tar.gz \
  https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-${ARCH}.tar.gz
mkdir -p ~/.local/nvim && tar -xzf /tmp/nvim.tar.gz -C ~/.local/nvim --strip-components=1
mkdir -p ~/.local/bin && ln -sf ~/.local/nvim/bin/nvim ~/.local/bin/nvim
```

## Testing

`./test.sh` builds a clean Ubuntu container and runs the full install end-to-end,
verifying the dotfiles install from scratch with nothing but the declared deps.

## Features

**Vim-Tmux Navigator** — `Ctrl+h/j/k/l` navigates vim splits and tmux panes seamlessly.

**Caps Lock** — tap = Escape, hold = Ctrl (set this in your OS keyboard settings).

**Tmux** (prefix `Ctrl+a`):
- `prefix + v` — split vertical
- `prefix + h` — split horizontal
- `Alt + h/l` — switch windows
- `prefix + j` — tmux-jump (jump to text in pane)

**FZF**:
- `Ctrl+p` — file search
- `Ctrl+f` — content search
- `Ctrl+r` — history

## Syncing

```bash
cd ~/dotfiles && git pull && ./install.sh
```
