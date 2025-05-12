# dotfiles

> Configuration files and scripts for setting up a MacOS development environment.

```txt
        .:'       lukejans@ostrich-m3
    __ :'__       -------------------
 .'`__`-'__``.    OS: macOS Sequoia 15.4.1 arm64
:__________.-'    Host: MacBook Air (13-inch, M3, 2024)
:_________:       Kernel: Darwin 24.4.0
 :_________`-;    Shell: zsh 5.9
  `.__.-.__.'     DE: Aqua
                  WM: Quartz Compositor 278.4.7
                  Terminal: ghostty 1.1.3
                  CPU: Apple M3 (8) @ 4.06 GHz
                  GPU: Apple M3 (10) @ 1.34 GHz [Integrated]
                  Memory: 16.00 GiB
                  Disk (/): 460.43 GiB - apfs
                  Locale: en_US.UTF-8
```

## Install

To bootstrap your MacOS development environment, execute the [`bootstrap.sh`](./bootstrap.sh) script by running the following command:

```sh
curl -fsSL https://raw.githubusercontent.com/lukejans/dotfiles/main/bootstrap.sh | bash
```

> [!note]
>
> - Only run on Apple Silicon Macs (aarch64).
> - I've only tested [`bootstrap.sh`](./bootstrap.sh) on macOS Sequoia 15.4.1.
> - All configuration files you were previously using that this script intends to overwrite will be backed up to `$HOME`.

## Homebrew

```txt
 .oOOoO.
 |=====|_      lukejans
 |||||||_)  homebrew setup
 |||||||
 `--=--'
```

See [`Brewfile`](./.config/homebrew/Brewfile) for a list of programs that will be installed by `bootstrap.sh`. This file was created by running the following command:

```sh
brew bundle dump --global --force
```

## Version Management

```txt
// ""--.._
||  (_)  _ "-._       lukejans
||    _ (_)    '-.  mise-en-place
||   (_)   __..-'
 \\__..--""
```

This setup uses [mise](https://mise.jdx.dev/) for version management. Note that I'm still planning a way to automate the install of all mise tools, but you can still run the following after the install script runs and you restart your system:

```sh
cd $HOME && mise install
```
