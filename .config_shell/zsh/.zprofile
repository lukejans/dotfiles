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
