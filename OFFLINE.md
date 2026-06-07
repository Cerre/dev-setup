# Offline / air-gapped install

This repo normally pulls from the internet during install. In an air-gapped
environment every artifact must be staged ahead of time (and, in your case,
go through an approval process first).

This document is the **bill of materials**: every external artifact, its source,
and its pinned version, grouped by channel. After dropping `markdown-preview.nvim`
and re-adding `tmux-thumbs`, the install touches **six** network channels:

1. apt (Ubuntu archive + Neovim PPA)
2. GitHub git clones
3. GitHub release binaries
4. npm registry
5. PyPI
6. crates.io (only to build `tmux-thumbs`)

> There is no longer an npm *build* step (that was `markdown-preview.nvim`).
> The crates.io channel is back solely to build `tmux-thumbs`; see the
> tmux-thumbs note under §2 for how to satisfy it offline.

---

## 1. apt — system packages

Top-level packages (transitive dependencies are resolved by apt):

```
git zsh tmux neovim ripgrep xclip bat zoxide nodejs npm curl
software-properties-common make build-essential python3 python3-venv ruby
fonts-jetbrains-mono
```

- **`neovim`** comes from `ppa:neovim-ppa/unstable` (0.11+), *not* the Ubuntu
  archive. You must approve/mirror that PPA, or stage the `.deb` directly.

**Staging:** on an internet-connected Ubuntu box of the **same release and CPU
architecture**, download the packages plus their dependency closure:

```bash
sudo add-apt-repository -y ppa:neovim-ppa/unstable && sudo apt-get update
mkdir debs && cd debs
apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests \
  --no-conflicts --no-breaks --no-replaces --no-enhances \
  git zsh tmux neovim ripgrep xclip bat zoxide nodejs npm curl \
  software-properties-common make build-essential python3 python3-venv ruby \
  fonts-jetbrains-mono | grep '^\w' | sort -u)
```

Transfer the `debs/` directory, then on the offline box: `sudo dpkg -i debs/*.deb`
(or serve it as a local apt repo).

---

## 2. GitHub — git clones

| Repo | Pin | Where it lands |
|---|---|---|
| `ohmyzsh/ohmyzsh` | latest (unpinned) | `~/.oh-my-zsh` |
| `junegunn/fzf` | latest (unpinned) | `~/.fzf` |
| `tmux-plugins/tpm` | latest (unpinned) | `~/.tmux/plugins/tpm` |
| `schasse/tmux-jump` | latest (unpinned) | `~/.tmux/plugins/tmux-jump` |
| `fcsonline/tmux-thumbs` | latest (unpinned) | `~/.tmux/plugins/tmux-thumbs` |
| `folke/lazy.nvim` | see `lazy-lock.json` | `~/.local/share/nvim/lazy/lazy.nvim` |
| **~30 Neovim plugins** | **pinned in `nvim/lazy-lock.json`** | `~/.local/share/nvim/lazy/<plugin>` |

`nvim/lazy-lock.json` is the authoritative, commit-pinned manifest for the
Neovim plugins — submit it as-is for approval.

**`tmux-thumbs` compiles from Rust** on first install — it needs `cargo`
(install `rustc`/`cargo`, or `~/.cargo/bin` via rustup, and the crates it pulls
from crates.io). In a fully air-gapped setup either pre-build it on a connected
host and copy `~/.tmux/plugins/tmux-thumbs`, or vendor its crates. Its clipboard
hooks shell out to `xclip` and `xdg-open`.

**Treesitter grammars** are also git-fetched and compiled (needs the C compiler
from `build-essential`). The config installs these languages:

```
bash c diff html lua luadoc markdown markdown_inline query vim vimdoc
```

(Plus any others on first edit, because `auto_install = true` in
`nvim/init.lua`. For a strict air-gap, set `auto_install = false` so Neovim never
tries to fetch a missing grammar.)

**Staging:** clone each repo on the online machine and copy it to the matching
path above. Because `lazy-lock.json` pins commits, place the plugin repos under
`~/.local/share/nvim/lazy/` and run `nvim --headless "+Lazy! restore" +qa`
offline — lazy will check out the pinned commits without fetching.

---

## 3. GitHub — release binaries (prebuilt)

| Artifact | Source | Notes |
|---|---|---|
| `fzf` binary | `junegunn/fzf` releases | fetched by `~/.fzf/install`; match OS/arch |
| `lua-language-server` | `LuaLS/lua-language-server` releases | via Mason |
| `stylua` | `JohnnyMorganz/StyLua` releases | via Mason |
| JetBrainsMono Nerd Font | `ryanoasis/nerd-fonts` releases | *optional* — only if you want the patched Nerd Font instead of the apt `fonts-jetbrains-mono` package |

---

## 4. npm registry

| Package | Installed by |
|---|---|
| `dockerfile-language-server-nodejs` | Mason (`dockerls`) |

---

## 5. PyPI

| Package | Installed by |
|---|---|
| `basedpyright` | Mason |
| `debugpy` | mason-nvim-dap |

---

## Mason note

Items in channels 3–5 are all pulled by **Mason** into
`~/.local/share/nvim/mason/`. Two ways to satisfy them offline:

- **Pre-populate** `~/.local/share/nvim/mason/` from a machine where you ran
  `:Mason` online, and copy it across; or
- **Skip Mason** entirely: install `basedpyright`, `lua-language-server`,
  `stylua`, `debugpy`, and `dockerfile-language-server-nodejs` through your
  approved apt/pip/npm mirrors and point Neovim at them directly (drop the
  `ensure_installed` lists in `nvim/init.lua` and `nvim/lua/custom/plugins/debug.lua`).

---

## Pragmatic approach: golden-image transfer

If your process allows transferring a built home directory rather than approving
each upstream individually, the simplest path is:

1. On an **online** machine with the **same Ubuntu release and architecture**,
   run `./install.sh` and open `nvim` once (let Mason + Treesitter finish).
2. Archive the produced state:
   ```bash
   tar czf dotfiles-bundle.tgz \
     ~/.oh-my-zsh ~/.fzf ~/.tmux/plugins \
     ~/.local/share/nvim ~/.local/bin \
     ~/.local/share/fonts /var/cache/apt/archives/*.deb
   ```
3. On the **offline** machine: install the `.deb`s, unpack the archive into
   `$HOME`, clone this repo, and run `SKIP_APT=1 SKIP_PLUGINS=1 ./install.sh`
   to lay down the symlinks.

Everything in the bundle is version-locked to what you approved and tested.
