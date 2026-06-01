#!/usr/bin/env bash
# Build the dotfiles in a clean container and drop into the resulting shell.
# Works with either Docker or Podman (rootless) — whichever is installed.
set -e

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

"$RUNTIME" build -t dotfiles-test . && "$RUNTIME" run --rm -it dotfiles-test
