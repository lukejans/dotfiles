# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# ssh
if ! ssh-add -l &>/dev/null; then
    (ssh-add --apple-load-keychain &>/dev/null &)
fi

# mise
eval "$("${HOME}/.local/bin/mise" activate zsh --shims)"
