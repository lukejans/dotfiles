# --- homebrew
# ensure homebrew installed binaries are found
# see: https://brew.sh
eval "$(/opt/homebrew/bin/brew shellenv)"

# --- ssh
# load all identities used in the keychain to the ssh-agent and only add the
# identities if they aren't already loaded. Note that this current setup is
# using the agent that is automatically setup by launchd. This is generally
# okay but launchd will not run it's agent when the shell is spawned from an
# ssh connection. If you often do remote work, you may want to launch your
# own ssh agent before loading your keys using the below command:
#
# ```sh
# eval "$(ssh-agent -s)"
# ```
if ! ssh-add -l &>/dev/null; then
    ssh-add --apple-load-keychain &>/dev/null
fi

# --- mise
# this sets up non-interactive sessions so language servers that are launched
# by an IDE have access to the correct environment variables and binaries.
eval "$(mise activate zsh --shims)"

# --- pnpm
export PNPM_HOME="${HOME}/Library/pnpm"
# add pnpm to path if its not already there
if [[ ":${PATH}:" != *":${PNPM_HOME}:"* ]]; then
    export PATH="${PNPM_HOME}:${PATH}"
fi

# --- personal bin
export PATH="${HOME}/.dotfiles/bin:${PATH}"
