# configuration directory
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"

# zsh
export SHELL_SESSIONS_DISABLE=1

# homebrew
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1
export HOMEBREW_DISPLAY_INSTALL_TIMES=1
export HOMEBREW_CLEANUP_MAX_AGE_DAYS=30
export HOMEBREW_BUNDLE_NO_DESCRIBE=1
export HOMEBREW_BUNDLE_DUMP_NO_CARGO=1
export HOMEBREW_BUNDLE_DUMP_NO_NPM=1
export HOMEBREW_BUNDLE_DUMP_NO_GO=1
export HOMEBREW_BUNDLE_DUMP_NO_UV=1

# editor
export VISUAL="zed --wait"
export EDITOR="nano"

# rust
export CARGO_HOME="${XDG_DATA_HOME}/cargo"
export RUSTUP_HOME="${XDG_DATA_HOME}/rustup"

# python
export PYTHON_HISTORY="${XDG_STATE_HOME}/python/python_history"

# go
export GOPATH="${XDG_DATA_HOME}/go"
export GOENV="${XDG_CONFIG_HOME}/go/env"

# node
export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME}/npm/npmrc"
export NPM_CONFIG_CACHE="${XDG_CACHE_HOME}/npm"

# biome
# export BIOME_CONFIG_PATH="${XDG_CONFIG_HOME}/biome/biome.json"
