# shellcheck shell=zsh
#  ______
# | $_   |  lukejans
# |______| .zprofile

# --- homebrew
# ensure homebrew installed binaries are found
# see: https://brew.sh
eval "$(/opt/homebrew/bin/brew shellenv)"

# --- ssh
# load all identities used in the keychain to the ssh-agent
# and only add the identities if they aren't already loaded
if ! ssh-add -l &>/dev/null; then
    ssh-add --apple-load-keychain &>/dev/null
fi

# --- mise
# this sets up non-interactive sessions
eval "$(mise activate zsh --shims)"

# --- pnpm
export PNPM_HOME="${HOME}/Library/pnpm"
# add pnpm to path if its not already there
if [[ ":${PATH}:" != *":${PNPM_HOME}:"* ]]; then
    export PATH="${PNPM_HOME}:${PATH}"
fi

# --- personal bin
export PATH="${HOME}/.local/bin:${PATH}"
