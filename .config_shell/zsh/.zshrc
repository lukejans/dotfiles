#  ______
# | $_   |  lukejans
# |______|   .zshrc

# --- set interactive options
# don't add duplicate commands to the history
setopt HIST_IGNORE_DUPS
# make the history append to the file during session
setopt INC_APPEND_HISTORY

# --- set interactive env variables
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000000
export SAVEHIST=10000000

# --- tab completions
if type brew &>/dev/null; then
  # homebrew builtin completions:
  # this checks if homebrew is present before adding its
  # completions to FPATH.
  #   - packaged with homebrew
  #   - see: https://docs.brew.sh/Shell-Completion
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

  # additional zsh completions:
  #   - brew installed
  #   - see: https://github.com/zsh-users/zsh-completions
  FPATH="$(brew --prefix)/share/zsh-completions:${FPATH}"
fi
autoload -Uz compinit # enable completions system
compinit              # initialize all completions on $FPATH

# --- custom aliases & functions
source "$HOME/.dotfiles/.config_shell/zsh/aliases.zsh"
source "$HOME/.dotfiles/.config_shell/zsh/functions.zsh"

# --- plugins
# starship command prompt:
#   - brew installed
#   - see: https://github.com/starship/starship
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
export STARSHIP_CACHE="$HOME/.cache/starship"
eval "$(starship init zsh)"
# fzf:
#   - brew installed
#   - see: https://github.com/junegunn/fzf
eval "$(fzf --zsh)"
# zoxide:
#   - brew installed
#   - see: https://github.com/ajeetdsouza/zoxide
eval "$(zoxide init --cmd cd zsh)"
# bat (interactive tool settings)
export BAT_CONFIG_DIR="$XDG_CONFIG_HOME/bat"
export BAT_CONFIG_PATH="$BAT_CONFIG_DIR/bat.conf"
# use bat as the man pager for colorized man pages
export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
# tmux
export TMUX_DIR="$XDG_CONFIG_HOME/tmux"
export TMUX_CONF="$TMUX_DIR/tmux.conf"
export TMUX_CONF_LOCAL="$TMUX_DIR/tmux.conf.local"

# --- zsh plugins
# fast-syntax-highlighting
#   - brew installed
#   - see: https://github.com/zdharma-continuum/fast-syntax-highlighting
source "$(brew --prefix)/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
# zsh-autosuggestions:
#   - brew installed
#   - see: https://github.com/zsh-users/zsh-autosuggestions
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# --- node
# nvm: node version manager
#   - git installed
#   - see: https://github.com/nvm-sh/nvm
#   - note: consider lazy loading nvm as its the heaviest part
#           of the configuration.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# deeper shell integration
autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "$nvmrc_path")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# pnpm: performant node package manager
#   - corepack enabled
#   - see: https://pnpm.io
#   - note: the guide on node.js downloads page was followed
export PNPM_HOME="/Users/lukejans/Library/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

# --- java
# -> openjdk (brew installed)
# -> java (macOS pre-bundled)
# -> liberica (brew tap)
# jenv: (java version manager)
#   see: https://github.com/jenv/jenv
#   installs:
#     openjdk64-21.0.7 -> Liberica JDK 21
#     openjdk64-23.0.1 -> OpenJDK 23
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

# --- c
# add homebrew include directory to header search path
CPATH="$(brew --prefix)/include${CPATH+:$CPATH}"
export CPATH
# add homebrew library directory to library search path (for linking)
LIBRARY_PATH="$(brew --prefix)/lib${LIBRARY_PATH+:$LIBRARY_PATH}"
export LIBRARY_PATH
