#!/usr/bin/env bash
# Build the offline bundle inside a clean ubuntu:24.04 container and copy the
# single resulting file out to the host. Never touches your real $HOME.
#
# Works with Docker or Podman, like test.sh. Output: ./dotfiles-offline-bundle.tar

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${OUT:-$DOTFILES_DIR/dotfiles-offline-bundle.tar}"

if command -v docker >/dev/null 2>&1; then
    RUNTIME=docker
elif command -v podman >/dev/null 2>&1; then
    RUNTIME=podman
else
    echo "No container runtime found. Install one:" >&2
    echo "  sudo apt install -y podman      # rootless, no daemon (recommended)" >&2
    echo "  # or: sudo apt install -y docker.io" >&2
    exit 1
fi

echo "==> Building staging image (this runs the full install inside the container)..."
"$RUNTIME" build -f "$DOTFILES_DIR/Dockerfile.offline" -t dotfiles-offline "$DOTFILES_DIR"

echo "==> Extracting the bundle to: $OUT"
cid="$("$RUNTIME" create dotfiles-offline)"
trap '"$RUNTIME" rm "$cid" >/dev/null 2>&1 || true' EXIT
"$RUNTIME" cp "$cid:/dotfiles-offline-bundle.tar" "$OUT"

echo ""
echo "Done. Transfer this single file to the offline box:"
echo "  $OUT"
echo "Then on the offline box:"
echo "  mkdir ~/offline && tar xf $(basename "$OUT") -C ~/offline"
echo "  ~/offline/repo/restore-offline.sh"
