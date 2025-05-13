# shellcheck shell=zsh
#  ______
# | $_   |  lukejans
# |______|   .zshrc

# --- set interactive options
# don't add duplicate commands to the history
setopt HIST_IGNORE_DUPS
# make the history append to the file during session
setopt INC_APPEND_HISTORY

# --- set interactive env variables
export HISTFILE="${HOME}/.zsh_history"
export HISTSIZE=10000000
export SAVEHIST=10000000

# bat
export BAT_CONFIG_DIR="${XDG_CONFIG_HOME}/bat"
export BAT_CONFIG_PATH="${BAT_CONFIG_DIR}/bat.conf"
# use bat as the man pager for colorized man pages
export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"

# tmux
export TMUX_DIR="${XDG_CONFIG_HOME}/tmux"
export TMUX_CONF="${TMUX_DIR}/tmux.conf"
export TMUX_CONF_LOCAL="${TMUX_DIR}/tmux.conf.local"

# starship
export STARSHIP_CONFIG="${HOME}/.config/starship/starship.toml"
export STARSHIP_CACHE="${HOME}/.cache/starship"

# --- tab completions
# completions that homebrew manages
if type brew &>/dev/null; then
  # homebrew builtin completions:
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
  # additional completions (zsh-users):
  FPATH="$(brew --prefix)/share/zsh-completions:${FPATH}"
fi
# personal completions
FPATH="${HOME}/.dotfiles/completions:${FPATH}"
# setup zsh completions
autoload -Uz compinit # enable completions system
compinit              # initialize all completions on $FPATH

# --- custom aliases & functions
source "${HOME}/.dotfiles/.config_shell/zsh/aliases.zsh"
source "${HOME}/.dotfiles/.config_shell/zsh/functions.zsh"

# --- load plugins
eval "$(starship init zsh)"
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(mise activate zsh)"

# --- zsh plugins
source "$(brew --prefix)/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# pnpm: performant node package manager
export PNPM_HOME="${HOME}/Library/pnpm"
# add pnpm to path if its not already there
if [[ ":${PATH}:" != *":${PNPM_HOME}:"* ]]; then
  export PATH="${PNPM_HOME}:${PATH}"
fi
