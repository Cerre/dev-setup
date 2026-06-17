#!/usr/bin/env bash
# Assemble a SINGLE self-contained offline-install bundle.
#
# Runs the real install, then packs everything the offline box needs into one
# tar file:
#   - debs/         the apt dependency closure (.deb files)
#   - home.tgz      the built $HOME state (plugins, grammars, Mason LSPs, fzf...)
#   - usr-local-bin/lazygit
#   - repo/         a copy of this repo (the files install.sh symlinks to)
#
# Run it in a clean ubuntu:24.04 container (see stage-offline-docker.sh) so it
# never touches your host, or directly on a matching online box. Same arch +
# release + glibc as the offline target is required.
#
# Output: ./dotfiles-offline-bundle.tar   (override with OUT=/path ./stage-offline.sh)

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGE="$(mktemp -d)"
OUT="${OUT:-$PWD/dotfiles-offline-bundle.tar}"

# Use sudo only when not already root (e.g. we're root inside the container).
SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

# Top-level apt packages (transitive deps resolved below). Mirrors install.sh.
PKGS="git zsh tmux neovim ripgrep fd-find xclip bat zoxide nodejs npm curl
software-properties-common make build-essential python3 python3-venv ruby
imagemagick fonts-jetbrains-mono"

echo "==> [1/6] Building the dotfiles environment..."
"$DOTFILES_DIR/install.sh"
# Pin/install the Neovim plugins to their locked commits.
nvim --headless "+Lazy! restore" +qa || true

echo "==> [2/6] Compiling tmux-thumbs (Rust)..."
# tmux-thumbs ships source only; TPM does not build it. It needs cargo, which is
# NOT in the runtime package set — install it here (staging only) and compile.
# The offline box receives the built binary, so it never needs cargo.
$SUDO apt-get install -y cargo
THUMBS_DIR="$HOME/.tmux/plugins/tmux-thumbs"
cargo build --release --manifest-path "$THUMBS_DIR/Cargo.toml"

echo "==> [3/6] Realizing Treesitter grammars + Mason tools (and verifying)..."
# These are async and are NOT produced by 'Lazy! restore'; this blocks until
# they are on disk and exits non-zero (failing the build) if any are missing.
nvim --headless -c "luafile $DOTFILES_DIR/offline-realize.lua"

echo "==> [4/6] Verifying compiled artifacts on disk..."
[ -x "$THUMBS_DIR/target/release/thumbs" ] || {
    echo "FATAL: tmux-thumbs binary not built at $THUMBS_DIR/target/release/thumbs" >&2
    exit 1
}
ts_parsers="$(find "$HOME/.local/share/nvim" -path '*/parser/*.so' 2>/dev/null | wc -l)"
[ "$ts_parsers" -ge 11 ] || {
    echo "FATAL: expected >=11 treesitter parsers, found $ts_parsers" >&2
    exit 1
}
# Mason launchers must exist on disk (is_installed() in Lua is unreliable).
mason_bin="$HOME/.local/share/nvim/mason/bin"
for launcher in basedpyright-langserver lua-language-server stylua docker-langserver debugpy-adapter; do
    [ -e "$mason_bin/$launcher" ] || {
        echo "FATAL: mason launcher missing: $mason_bin/$launcher" >&2
        exit 1
    }
done
echo "    tmux-thumbs binary OK; $ts_parsers treesitter parsers; all mason launchers present."

echo "==> [5/6] Downloading apt dependency closure..."
$SUDO add-apt-repository -y ppa:neovim-ppa/unstable
$SUDO apt-get update
mkdir -p "$STAGE/debs"
(
  cd "$STAGE/debs"
  # shellcheck disable=SC2046
  apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests \
    --no-conflicts --no-breaks --no-replaces --no-enhances $PKGS \
    | grep '^\w' | sort -u)
)

echo "==> [6/6] Archiving \$HOME state + lazygit + repo, then bundling..."
HOME_PATHS=(.oh-my-zsh .fzf .tmux/plugins .local/share/nvim .local/bin)
[ -d "$HOME/.local/share/fonts" ] && HOME_PATHS+=(.local/share/fonts)
tar czf "$STAGE/home.tgz" -C "$HOME" "${HOME_PATHS[@]}"

# Binaries that install.sh placed in /usr/local/bin (outside $HOME and apt):
# lazygit and the tree-sitter CLI. The offline box gets them from here.
mkdir -p "$STAGE/usr-local-bin"
for bin in lazygit tree-sitter; do
    [ -x "/usr/local/bin/$bin" ] && cp "/usr/local/bin/$bin" "$STAGE/usr-local-bin/"
done

# Include the repo (the files install.sh symlinks to).
mkdir -p "$STAGE/repo"
# Copy the working tree minus VCS/build cruft. These are the symlink targets,
# so they must live permanently on the offline box.
tar -C "$DOTFILES_DIR" \
    --exclude=.git --exclude='*.tar' --exclude='dotfiles-offline-bundle.tar' \
    -cf - . | tar -x -C "$STAGE/repo"

tar cf "$OUT" -C "$STAGE" .
rm -rf "$STAGE"

echo ""
echo "Done. Transfer this single file to the offline box:"
echo "  $OUT"
