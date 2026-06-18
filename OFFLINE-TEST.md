# Testing the offline bundle in Docker (before touching the VM)

Validate the air-gapped install on any online machine with Docker — **including
an Ubuntu 22.04 host**. A `FROM ubuntu:24.04` container brings its own 24.04
userland + glibc 2.39, so it faithfully mirrors a 24.04 VM regardless of the
host's release; Docker only shares the (newer-is-fine) host kernel. The restore
itself runs with `--network none`, proving it needs no internet.

> This tests the bundle from a GitHub release. To rebuild the bundle from source
> instead, see [OFFLINE.md](OFFLINE.md) (`./stage-offline-docker.sh`).

## 1. Check Docker

```bash
docker run --rm hello-world >/dev/null 2>&1 && echo "docker OK" || echo "fix docker first"
# if missing: sudo apt install -y docker.io && sudo usermod -aG docker $USER  (then log out/in)
```

## 2. Download the bundle

```bash
mkdir -p ~/offline-test && cd ~/offline-test
curl -fLO https://github.com/Cerre/dev-setup/releases/download/offline-bundle-v1/dotfiles-offline-bundle.tar
curl -fLO https://github.com/Cerre/dev-setup/releases/download/offline-bundle-v1/dotfiles-offline-bundle.tar.sha256
sha256sum -c dotfiles-offline-bundle.tar.sha256     # must print: ... OK
```

## 3. Build a "VM-like" image (24.04 + sudo + non-root user)

A non-root user with `sudo` mirrors a real provisioned box more closely than
running as root.

```bash
cd ~/offline-test
cat > Dockerfile.vmtest <<'EOF'
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y sudo && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash dev && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev
USER dev
WORKDIR /home/dev
EOF
docker build -t vm-like -f Dockerfile.vmtest .
```

## 4. Run the air-gapped restore + verify

`--network none` guarantees nothing is fetched.

```bash
cd ~/offline-test
docker run --rm --network none \
  -v "$PWD/dotfiles-offline-bundle.tar:/tmp/bundle.tar:ro" \
  vm-like bash -c '
set -e
mkdir ~/offline && tar xf /tmp/bundle.tar -C ~/offline
~/offline/repo/restore-offline.sh > ~/r.log 2>&1; echo "restore exit: $?"
for b in nvim tmux zsh lazygit tree-sitter rg fdfind batcat convert; do
  command -v $b >/dev/null || echo "MISSING: $b"; done
nvim --headless -c "lua io.write(\"plugins=\"..#require(\"lazy\").plugins())" -c "qa"; echo
echo "ts=$(find ~/.local/share/nvim -path "*/parser/*.so" | wc -l) mason=$(ls ~/.local/share/nvim/mason/bin | wc -l)"
echo "===== PASS ====="'
```

**Success looks like:**

```
restore exit: 0
plugins=41
ts=11 mason=7
===== PASS =====
```

No `MISSING:` lines, `restore exit: 0`, and `PASS` at the end → it works
air-gapped, and a 24.04 VM will behave the same.

## 5. (Optional) Poke around live

```bash
cd ~/offline-test
docker run --rm -it --network none \
  -v "$PWD/dotfiles-offline-bundle.tar:/tmp/bundle.tar:ro" \
  vm-like bash -c 'mkdir ~/offline && tar xf /tmp/bundle.tar -C ~/offline && ~/offline/repo/restore-offline.sh >/dev/null 2>&1; exec zsh'
# inside: try `nvim` (then :Lazy, :Mason, :checkhealth), and `tmux`
```

## If it fails

```bash
cd ~/offline-test
docker run --rm --network none -v "$PWD/dotfiles-offline-bundle.tar:/tmp/bundle.tar:ro" \
  vm-like bash -c 'mkdir ~/offline && tar xf /tmp/bundle.tar -C ~/offline; ~/offline/repo/restore-offline.sh; echo "EXIT:$?"; tail -30 ~/r.log 2>/dev/null'
```

Capture the `EXIT:` value and the tail of the log.

## What this does NOT cover (only happens on the real VM)

- `chsh -s "$(which zsh)"` + the login-shell switch (no real login session in a
  container).
- Desktop integration (Ghostty / GNOME keybinding / VS Code) — guarded steps in
  `install.sh` that are skipped unless those tools exist. Irrelevant on a headless
  server.
- The VM's pre-existing package state — the container is a clean baseline.

## Then: the real VM (no Docker)

```bash
mkdir ~/offline && tar xf dotfiles-offline-bundle.tar -C ~/offline
~/offline/repo/restore-offline.sh
chsh -s "$(which zsh)"     # then log out / back in
```
