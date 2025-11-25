# homebrew
# ensure homebrew installed binaries are found
# see: https://brew.sh
eval "$(/opt/homebrew/bin/brew shellenv)"

# ssh
# load all identities used in the keychain to the ssh-agent. Note that if
# you want to use signing keys and what not from your local machine on a
# remote host you will need to forward the agent to the host.
#
# ```sh
# eval "$(ssh-agent -s)"
# ```
if ! ssh-add -l &>/dev/null; then
    ssh-add --apple-load-keychain &>/dev/null
fi

# mise
# this sets up non-interactive sessions so language servers that are launched
# by an IDE have access to the correct environment variables and binaries.
eval "$(mise activate zsh --shims)"

# pnpm
export PNPM_HOME="${HOME}/Library/pnpm"
# add pnpm to path if its not already there
if [[ ":${PATH}:" != *":${PNPM_HOME}:"* ]]; then
    export PATH="${PNPM_HOME}:${PATH}"
fi

# personal bin
export PATH="${HOME}/.dotfiles/bin:${PATH}"
