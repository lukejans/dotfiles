# zsh options
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt AUTO_PARAM_SLASH
setopt GLOB_DOTS

# ghostty zsh shell integration
if [[ -n ${GHOSTTY_RESOURCES_DIR} ]]; then
    builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
fi

# zsh completions
typeset -U fpath
fpath+=("${HOMEBREW_PREFIX}/share/zsh-completions")
fpath+=("${XDG_DATA_HOME}/zsh/site-functions")
# set completion cache path
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME}/zsh/zcompcache"
# enable completions
autoload -Uz compinit && compinit -d "${XDG_CACHE_HOME}/zsh/zcompdump"

# history
export HISTFILE="${XDG_STATE_HOME}/zsh/zsh_history"
export HISTSIZE=10000000
export SAVEHIST=10000000

# pager
export PAGER="less"
export LESS='-R -F -M -i --incsearch'
export LESSHISTFILE="${XDG_STATE_HOME}/lesshst"

# bat
export BAT_CONFIG_DIR="${XDG_CONFIG_HOME}/bat"
export BAT_CONFIG_PATH="${BAT_CONFIG_DIR}/bat.conf"

# fzf
export FZF_DEFAULT_COMMAND='fd --type file --hidden --color=always --strip-cwd-prefix --follow'
export FZF_DEFAULT_OPTS='
    --ansi
    --tmux 90%,90%
    --info="right"
    --preview "bat --color=always --style=full {} --terminal-width=$FZF_PREVIEW_COLUMNS"
    --preview-window "right,70%"
    --color header:italic
'
export FZF_CTRL_R_OPTS='--preview=""'

# starship
export STARSHIP_CONFIG="${XDG_CONFIG_HOME}/starship/starship.toml"

# eza
export EZA_CONFIG_DIR="${XDG_CONFIG_HOME}/eza"

# tooling
eval "$(fzf --zsh)"
eval "$(batman --export-env)"
eval "$(zoxide init --cmd cd zsh)"
eval "$("${HOME}/.local/bin/mise" activate zsh)"
eval "$(starship init zsh)"

# zsh plugins
source "${HOMEBREW_PREFIX}/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
source "${HOMEBREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# custom aliases & functions
alias ls='eza --classify --sort=type'
alias ll='eza --classify --sort=type --long --group --links --mounts --binary --modified --time-style="+%Y-%m-%d %H:%M" --git --git-repos'
alias la='eza --classify --sort=type --long --group --links --mounts --binary --modified --time-style="+%Y-%m-%d %H:%M" --git --git-repos --all'
alias lt='eza --classify --sort=type --tree --ignore-glob "node_modules|.git"'
alias ltd='eza --classify --sort=type --tree --ignore-glob "node_modules|.git" --only-dirs'
alias lldu='eza --classify --sort=type --long --group --links --mounts --binary --modified --time-style="+%Y-%m-%d %H:%M" --git --git-repos  --total-size'

alias java_sweep='find . -name "*.class" -type f -delete'
alias node_sweep="find . -type d -name node_modules -prune -exec rm -rf '{}' \;"
alias ds_sweep='find . -name ".DS_Store" -type f -delete'

# create a new directory and enter it
mkcd() {
    mkdir -p -- "${@}" && cd "${@: -1}" || return
}
