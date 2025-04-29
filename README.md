# Dotfiles

> My MacOS setup

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

Running the below command in your terminal will execute the [setup.sh](./setup.sh) install script.

```sh
curl -fsSL https://raw.githubusercontent.com/lukejans/dotfiles/main/verify_setup.sh | bash
```

This script will confirm you want to proceed with the install before doing anything. If you confirm it will attempt to do the following:

- 🛠️ Install Xcode command line tools
- 🍺 Install Homebrew & programs listed inside of [Brewfile](./Brewfile)
- 😊 Download This repo to `$HOME/.dotfiles`
- 🔗 Symlink config files to `$HOME` and `$HOME/.config`
- 🌱 Setup a Node.js environment (v22.xx.x), (`nvm`, `pnpm`)
- 📦 Install some npm packages
- ✨ Set some MacOS system settings

## ⚠️ Warnings

> **Run at your own risk! I do not take responsibility for any data loss or other issues related to using this install script.**

- Use only on apple silicon Macs as I have not added checks for different homebrew paths.
- I create backups of configurations this script replaces but in some cases an old `.config.bak` may end up in `~/.Trash`
- `setup.sh` was written for the latest version of MacOS and may or may not work on earlier versions.
