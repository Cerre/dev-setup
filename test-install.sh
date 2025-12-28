#!/usr/bin/env bash

set -e

echo "=== Dotfiles Installation Test ==="
echo ""
echo "This will build a Docker container to test your dotfiles installation"
echo "in a clean Ubuntu 22.04 environment."
echo ""

# Build the Docker image
echo "Building test container..."
docker build -f Dockerfile.test -t dotfiles-test .

echo ""
echo "=== Build Complete ==="
echo ""
echo "To test your dotfiles, run one of these commands:"
echo ""
echo "  # Start an interactive shell:"
echo "  docker run -it --rm dotfiles-test"
echo ""
echo "  # Test tmux:"
echo "  docker run -it --rm dotfiles-test tmux"
echo ""
echo "  # Test a specific command:"
echo "  docker run -it --rm dotfiles-test zsh -c 'rg --version'"
echo ""
echo "  # Quick test - verify symlinks:"
echo "  docker run --rm dotfiles-test zsh -c 'ls -la ~/.zshrc ~/.tmux.conf ~/.ripgreprc'"
echo ""
