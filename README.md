# Dotfiles

> [!WARNING]
> Only use this setup on macOS (arm64). This is a personal setup and is only public so my new machines can easily `git clone` over https with no auth.

## Bootstrap

Complete the below steps in a single shell session to ensure that all necessary commands are on path during setup.

```sh 
# 1. Install Xcode Command Line Tools
# IMPORTANT: wait for the install to complete (opens in another window)
xcode-select --install

# 2. Clone this repo so it sits at `~/.config`
# IMPORTANT: ensure `~/.config/` does not yet exist.
git clone https://github.com/lukejans/dotfiles.git ~/.config

# 3. Install `mise`: https://mise.jdx.dev
curl -fsSL https://mise.run | sh
# activate for this session
eval "$(~/.local/bin/mise activate zsh)"
# verify install
mise --version

# 4. Install `brew`: https://brew.sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# activate for this session
eval "$(/opt/homebrew/bin/brew shellenv)"
# verify install
brew --version

# 5. Run bootstrap. 
# REQUIRED: sign-in to the App Store with an appleID so `mas` can install apps from the App Store 
mise --yes bootstrap

# 6. Complete the Xcode setup now that Xcode.app is installed
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept

# 7. Restart to ensure all changes are applied
sudo shutdown -r now
```

## SSH

Generate ssh keys and add them to the macOS keychain. For Github, register the keys to the necessary account in [settings: SSH and GPG keys](https://github.com/settings/keys).

```sh
ssh-keygen -t ed25519 -C "<comment|email>" -f ~/.ssh/auth_key_ed25519
ssh-keygen -t ed25519 -C "<comment|email>" -f ~/.ssh/signing_key_ed25519

ssh-add --apple-use-keychain ~/.ssh/auth_key_ed25519
ssh-add --apple-use-keychain ~/.ssh/signing_key_ed25519
```

Update `~/.ssh/config` to ensure the key is used for the intended domain.

```ini
Host example.com
    HostName example.com
    User git
    UseKeychain yes
    AddKeysToAgent yes
    IdentityFile ~/.ssh/auth_key_ed25519
    IdentitiesOnly yes
```

## Git

Set user information and signing-key path in `config.local`, which is included last in `include.path` so local settings take precedence.

```ini
# ~/.config/git/config.local
[user]
    name = Fname Lname
    email = example@mail.com
    signingkey = ~/.ssh/signing_key_ed25519
```

### Workflow Defaults

- _merge into main_: create a merge commit even when fast-forwarding is possible.
- _commit_: SSH-signed commits instead of leaving them unsigned.
- _push_: always use ssh for push and send reachable annotated tags.
- _fetch_: prune stale remote-tracking refs instead of keeping them.
- _conflicts_: show the common ancestor using `zdiff3`.

```text
$ git switch main && git merge feature

Before:
A---B             main
     \
      C---D       feature

Git default (fast-forward):
A---B---C---D     main, feature

This config (--no-ff on main):
A---B-------M     main
     \     /
      C---D       feature
```
