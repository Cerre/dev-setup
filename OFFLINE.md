# Offline / air-gapped install

This repo normally pulls from the internet during install. For an air-gapped
machine, everything is staged ahead of time into **one self-contained bundle
file**, transferred across, and restored with no network access.

The whole flow is two scripts:

```bash
# 1. ONLINE box (Docker or Podman): build the bundle in a clean container.
./stage-offline-docker.sh          # -> dotfiles-offline-bundle.tar  (one file)

# 2. Transfer that one file to the OFFLINE box, then:
mkdir ~/offline && tar xf dotfiles-offline-bundle.tar -C ~/offline
~/offline/repo/restore-offline.sh  # installs everything, no network
chsh -s "$(which zsh)"             # then log out / back in
```

The bundle contains the repo itself, so you do **not** need to transfer the git
repo separately. `install.sh` symlinks configs *into* the repo, so the repo
files must live permanently on the offline box — `restore-offline.sh` places
them at `~/dotfiles` (override with `DOTFILES_DEST=/path`).

> Verified end-to-end: `restore-offline.sh` runs on a bare `ubuntu:24.04`
> container with `--network none` and produces a working setup (41 nvim plugins,
> 11 treesitter parsers, 7 Mason tools, all CLIs on `PATH`).

---

## Requirements

The online staging box must match the offline target on **all three**:

| Attribute | Why |
|---|---|
| **CPU architecture** (e.g. both `amd64`) | the bundle ships compiled binaries + arch-specific `.deb`s |
| **Ubuntu release** (e.g. both `24.04` / noble) | the `.deb` set is release-specific |
| **glibc ≥ staging box's** | binaries compiled on staging must load on the target |

Check both boxes with:

```bash
echo "arch:    $(uname -m) / $(dpkg --print-architecture)"
echo "release: $(. /etc/os-release; echo "$VERSION_ID $VERSION_CODENAME")"
echo "glibc:   $(ldd --version | head -1 | grep -oE '[0-9]+\.[0-9]+$')"
```

Build on the box with the **older** glibc if they differ. A clean offline image
of the same release is the easy case — everything matches.

---

## What's in the bundle

`stage-offline.sh` assembles a single tar with this layout:

| Entry | Contents |
|---|---|
| `debs/` + `debs/Packages.gz` | the apt dependency closure, indexed as a local apt repo |
| `pkgs.txt` | the top-level apt package set (what restore asks apt to install) |
| `home.tgz` | the built `$HOME` state (see below) |
| `usr-local-bin/` | the `lazygit` and `tree-sitter` binaries |
| `repo/` | a copy of this repo (the symlink targets + the restore script) |

`home.tgz` captures everything that is normally fetched/compiled on first use:

- `~/.oh-my-zsh`, `~/.fzf`, `~/.tmux/plugins` (incl. the **compiled** `tmux-thumbs`
  Rust binary)
- `~/.local/share/nvim` — all ~40 lazy.nvim plugins at their `lazy-lock.json`
  commits, the **compiled treesitter grammars**, and the **Mason** tools
  (`basedpyright`, `lua-language-server`, `stylua`, `dockerfile-language-server`,
  `debugpy`)
- `~/.local/bin`, `~/.local/share/fonts` (if present)

---

## How staging works (`stage-offline.sh`)

Run inside a clean `ubuntu:24.04` container by `stage-offline-docker.sh` (so it
never touches your host). Steps:

1. **Run `install.sh`** — installs system packages, bootstraps Oh My Zsh / fzf /
   TPM, symlinks configs, restores nvim plugins to locked commits, and (new)
   installs the pinned `tree-sitter` CLI + `lazygit` binaries.
2. **Compile `tmux-thumbs`** — it ships Rust source only and TPM does not build
   it, so staging installs `cargo` and runs `cargo build --release`. (The offline
   box receives the built binary and never needs cargo.)
3. **Realize async artifacts** (`offline-realize.lua`) — `Lazy! restore` does
   *not* produce treesitter grammars or Mason tools. This installs the
   `ensure_installed` grammars via `require('nvim-treesitter').install(...)` and
   the Mason tools, **blocking on real `install:success` events** (Mason's
   `is_installed()` flips true too early and would ship half-installed packages).
4. **Verify on disk** — fail the build unless the `tmux-thumbs` binary, ≥11
   treesitter parsers, and all 5 Mason launchers are physically present.
5. **Download the apt closure + index it** — `apt-cache depends --recurse`
   over-collects (it grabs every alternative, e.g. `make` + `make-guile`), so the
   debs are published as a local repo (`dpkg-scanpackages` → `Packages.gz`) and
   apt's solver picks a consistent subset at restore time. `pkgs.txt` records the
   top-level set.
6. **Bundle** — archive `home.tgz` + `usr-local-bin/` + `repo/` + `debs/` into the
   single output file.

---

## How restore works (`restore-offline.sh`)

Runs from inside the unpacked bundle (`~/offline/repo/restore-offline.sh`), no
network. Steps:

1. **Install system packages** — point apt at *only* the local `file://` repo
   (`Dir::Etc::SourceParts=/dev/null`, so it never reaches the network) and
   `apt-get install <pkgs.txt>`. `APT::Sandbox::User=root` lets apt read the local
   repo (the unprivileged `_apt` user otherwise gets Permission denied).
2. **Restore `$HOME` + binaries** — unpack `home.tgz` into `$HOME`, install the
   `lazygit` / `tree-sitter` binaries to `/usr/local/bin`.
3. **Place the repo** — copy `repo/` to `~/dotfiles` (the permanent symlink
   targets).
4. **Symlink configs** — `SKIP_APT=1 SKIP_PLUGINS=1 install.sh` lays down the
   symlinks only; all the bootstrap/plugin dirs already exist, so nothing is
   fetched.

---

## Per-artifact approval (Artifactory / mirrors)

If your process requires approving each upstream rather than transferring a built
bundle, these are the channels and pins:

- **apt:** the package set in `install.sh` (`git zsh tmux neovim ripgrep fd-find
  xclip bat zoxide nodejs npm curl software-properties-common make
  build-essential python3 python3-venv ruby imagemagick fonts-jetbrains-mono`),
  with `neovim` from `ppa:neovim-ppa/unstable` (0.11+).
- **GitHub git clones:** Oh My Zsh, fzf, TPM, `schasse/tmux-jump`,
  `fcsonline/tmux-thumbs`, `folke/lazy.nvim`, and the ~40 plugins pinned in
  `nvim/lazy-lock.json` (the authoritative manifest).
- **GitHub release binaries:** `lazygit` (`LAZYGIT_VERSION` in `install.sh`),
  `tree-sitter` CLI (`TREE_SITTER_VERSION`).
- **crates.io:** only to build `tmux-thumbs`.
- **PyPI (via Mason):** `basedpyright`, `debugpy`.
- **npm (via Mason):** `dockerfile-language-server-nodejs`.
- **Treesitter grammars:** fetched + compiled by the `tree-sitter` CLI.

---

## Caveats

- The end-to-end test runs **as root in a container** (`$HOME=/root`, no `sudo`).
  On a real box you run as a normal user; the apt and `/usr/local/bin` steps then
  go through `sudo` (the scripts already detect this). A real-VM dry run closes
  that last gap.
- Treesitter highlighting is verified by parser *presence*, not by an interactive
  render.
- `nvim/init.lua` sets `auto_install = false` so an offline Neovim never tries to
  fetch a missing grammar. Set it back to `true` on a networked machine if you
  want grammars auto-installed.
