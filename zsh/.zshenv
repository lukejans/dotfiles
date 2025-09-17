# configuration directory
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"

# dotnet
export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec"
export MONO_GAC_PREFIX="/opt/homebrew"

# use zed as the default editor
export EDITOR="zed"

# use a terminal based editor for git. This will take priority
# over $EDITOR and terminal based editors are better for ssh.
export GIT_EDITOR="micro"
