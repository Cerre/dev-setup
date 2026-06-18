#!/usr/bin/env bash
# Restore the offline bundle on the OFFLINE (bare) machine.
#
# This script ships INSIDE the bundle (under repo/). Usage:
#   mkdir ~/offline && tar xf dotfiles-offline-bundle.tar -C ~/offline
#   ~/offline/repo/restore-offline.sh
#
# It reads the sibling debs/, home.tgz and lazygit from the unpacked bundle,
# installs the system packages, restores the built $HOME state, places the repo
# permanently, then lays down the config symlinks with no network access.
#
# The repo lands in ~/dotfiles by default (override with DOTFILES_DEST=/path).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../<unpacked>/repo
BUNDLE_ROOT="$(dirname "$SCRIPT_DIR")"                       # .../<unpacked>
DEST="${DOTFILES_DEST:-$HOME/dotfiles}"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

if [ ! -d "$BUNDLE_ROOT/debs" ]; then
    echo "error: $BUNDLE_ROOT/debs not found." >&2
    echo "Unpack the bundle first:  tar xf dotfiles-offline-bundle.tar -C <dir>" >&2
    echo "then run <dir>/repo/restore-offline.sh" >&2
    exit 1
fi

echo "==> [1/4] Installing system packages from the local apt repo..."
# Publish the staged .debs as a local (file://) apt repo and let apt's solver
# pick a consistent subset for the top-level packages. Installing every .deb
# directly would deadlock: --recurse staged conflicting alternatives (make vs
# make-guile, libluajit vs libluajit2, ...). We point apt at ONLY this repo
# (SourceParts=/dev/null) so it never reaches the network.
offline_list="$(mktemp)"
echo "deb [trusted=yes] file://$BUNDLE_ROOT/debs ./" > "$offline_list"
# APT::Sandbox::User=root: apt normally drops to the unprivileged _apt user to
# fetch, which then can't read a local file:// repo (Permission denied). For a
# trusted local repo, fetch as root instead.
apt_opts=(
    -o "Dir::Etc::SourceList=$offline_list"
    -o "Dir::Etc::SourceParts=/dev/null"
    -o "APT::Sandbox::User=root"
)
$SUDO apt-get "${apt_opts[@]}" update
# shellcheck disable=SC2046
$SUDO apt-get "${apt_opts[@]}" install -y $(cat "$BUNDLE_ROOT/pkgs.txt")
rm -f "$offline_list"

echo "==> [2/4] Restoring built \$HOME state + /usr/local/bin binaries..."
tar xzf "$BUNDLE_ROOT/home.tgz" -C "$HOME"
if [ -d "$BUNDLE_ROOT/usr-local-bin" ]; then
    for bin in "$BUNDLE_ROOT"/usr-local-bin/*; do
        [ -e "$bin" ] || continue   # nothing staged
        $SUDO install "$bin" "/usr/local/bin/$(basename "$bin")"
    done
fi

echo "==> [3/4] Placing the repo at $DEST (symlink targets)..."
mkdir -p "$DEST"
cp -a "$SCRIPT_DIR/." "$DEST/"

echo "==> [4/4] Symlinking configs (no network)..."
SKIP_APT=1 SKIP_PLUGINS=1 "$DEST/install.sh"

echo ""
echo "Done. Final steps:"
echo "  chsh -s \"\$(which zsh)\"   # then log out / back in"
echo "  open nvim — plugins, LSPs, and grammars are already in place."
