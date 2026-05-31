FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root

# install.sh handles everything: system packages, Neovim PPA, Oh My Zsh, fzf,
# TPM, symlinks, and plugin installation. Running it here is also our end-to-end
# test that a clean Ubuntu box can install the dotfiles from scratch (see test.sh).
COPY . /root/dotfiles
RUN /root/dotfiles/install.sh

WORKDIR /root
RUN chsh -s /bin/zsh
CMD ["zsh"]
