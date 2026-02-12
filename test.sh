#!/usr/bin/env bash
set -e
docker build -t dotfiles-test . && docker run --rm -it dotfiles-test
