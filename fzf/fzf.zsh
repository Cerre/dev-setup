# Setup fzf
# ---------
if [[ ! "$PATH" == */home/filip/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/filip/.fzf/bin"
fi

source <(fzf --zsh)
