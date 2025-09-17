# shellcheck disable=SC1091,SC2016

# set interactive options
# don't add duplicate commands to the history
setopt HIST_IGNORE_DUPS
# make the history append to the file during session
setopt INC_APPEND_HISTORY

# set interactive env variables
# pager
export PAGER="less"
export LESS='-R -F -M -i --incsearch'
export LESSHISTFILE="${XDG_STATE_HOME}/lesshst"

# history
export HISTFILE="${XDG_STATE_HOME}/zsh_history"
export HISTSIZE=10000000
export SAVEHIST=10000000

# bat
export BAT_CONFIG_DIR="${XDG_CONFIG_HOME}/bat"
export BAT_CONFIG_PATH="${BAT_CONFIG_DIR}/bat.conf"
# use bat as the man pager for colorized man pages
export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"

# fzf
export FZF_DEFAULT_COMMAND='fd --type file --hidden --color=always --strip-cwd-prefix --follow'
export FZF_DEFAULT_OPTS='
    --ansi
    --tmux 90%,90%
    --info="right"
    --preview "bat --color=always --style=full {} --terminal-width=$FZF_PREVIEW_COLUMNS"
    --bind "focus:transform-header:file --brief {}"
    --preview-window "right,55%"
    --color header:italic
'
# --color=fg:#d0d0d0,fg+:#d0d0d0,bg:#121212,bg+:#262626
# --color=hl:#5f87af,hl+:#5fd7ff,info:#afaf87,marker:#87ff00
# --color=prompt:#d7005f,spinner:#af5fff,pointer:#af5fff,header:#87afaf
# --color=border:#262626,label:#aeaeae,query:#d9d9d9
# --preview-window="border-rounded"

# tmux
export TMUX_DIR="${XDG_CONFIG_HOME}/tmux"
export TMUX_CONF="${TMUX_DIR}/tmux.conf"
export TMUX_CONF_LOCAL="${TMUX_DIR}/tmux.conf.local"

# eza
# man eza_colors(5) for more info
export EZA_COLORS="di=34:cm=0;2:sc=0:cd=33;1;3;4:bd=35;1;3;4:ur=0:uw=0:ux=0:gr=0:gw=0:gx=0:tr=0:tw=0:tx=0:ex=31;1:uu=0:gu=0:da=0;2;3:lc=31:lm=31;1;4:nb=0;2:nk=32:nt=31;1;3;4:im=0:vi=0:mu=0:lo=0:co=35;3:tm=0:bu=0;3:sc=0:do=0:gm=33:Go=35:Gm=35"
# ls colors for backward compatibility
export LS_COLORS="${EZA_COLORS}"

# tab completions
# completions that homebrew manages
if type brew &>/dev/null; then
    # homebrew builtin completions:
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
    # additional completions (zsh-users):
    FPATH="$(brew --prefix)/share/zsh-completions:${FPATH}"
fi
# personal completions
FPATH="${HOME}/.local/share/zsh/completions:${FPATH}"
# setup zsh completions
autoload -Uz compinit # enable completions system
compinit              # initialize all completions on $FPATH

# custom aliases & functions
source "${HOME}/.dotfiles/zsh/aliases.zsh"
source "${HOME}/.dotfiles/zsh/functions.zsh"

# zsh plugins
source "$(brew --prefix)/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# --- load plugins
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(mise activate zsh)"
eval "$(starship init zsh)"
