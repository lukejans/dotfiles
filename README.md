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

This is a dotfiles repository that contains configuration files and scripts for setting up a MacOS development environment. This script is built to be run on a fresh MacOS installation but it can also be run to sync up your existing configuration files and dependencies.

## Install

To bootstrap your MacOS development environment, execute the [`bootstrap.sh`](./bootstrap.sh) script by running the following command:

```sh
curl -fsSL https://raw.githubusercontent.com/lukejans/dotfiles/main/bootstrap.sh | bash
```

The script is sensible enough to just run but if you would like to change the default behavior or inspect it, just redirect the output to a file like so:

```sh
curl -fsSL https://raw.githubusercontent.com/lukejans/dotfiles/main/bootstrap.sh > bootstrap.sh
```

In the script every main installation function has variables at the top of its body where you can change basic installation instructions such as installing node v18 instead of v22.

> [!note]
>
> - The bootstrap script should only be run on Apple Silicon Macs and was only tested on macOS Sequoia 15.4.1 arm64.
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
$ brew bundle dump --global --force
```
