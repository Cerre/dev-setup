FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root

# Install prerequisites (matches README)
RUN apt-get update && \
    apt-get install -y software-properties-common curl && \
    add-apt-repository -y ppa:neovim-ppa/unstable && \
    apt-get update && \
    apt-get install -y git zsh tmux neovim ripgrep xclip bat zoxide nodejs npm && \
    rm -rf /var/lib/apt/lists/*

# Oh My Zsh (unattended)
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# fzf (unattended)
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && \
    ~/.fzf/install --all

# TPM
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Copy dotfiles and install
COPY . /root/dotfiles
RUN cd /root/dotfiles && ./install.sh

WORKDIR /root
RUN chsh -s /bin/zsh
CMD ["zsh"]
