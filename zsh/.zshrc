# shellcheck disable=SC1091
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

# --- tab completions
# completions that homebrew manages
if type brew &>/dev/null; then
    # homebrew builtin completions:
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
    # additional completions (zsh-users):
    FPATH="$(brew --prefix)/share/zsh-completions:${FPATH}"
fi
# personal completions
FPATH="${HOME}/.dotfiles/zsh/completions:${FPATH}"
FPATH="${HOME}/.local/share/zsh/completions:${FPATH}"
# setup zsh completions
autoload -Uz compinit # enable completions system
compinit              # initialize all completions on $FPATH

# --- command prompt
# enable vcs_info
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ':(%b)'

precmd() {
    vcs_info
}

setopt PROMPT_SUBST

# build prompt: user@host in colours, then cwd, git‑branch, then $
PS1='%B%n%F{red}@%f%m ''%F{blue}%c%f''%F{red}${vcs_info_msg_0_}%f%F{green} $%f %b'

# --- custom aliases & functions
source "${HOME}/.dotfiles/zsh/aliases.zsh"
source "${HOME}/.dotfiles/zsh/functions.zsh"

# --- load plugins
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(mise activate zsh)"

# --- zsh plugins
source "$(brew --prefix)/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
source "$(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh"
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
