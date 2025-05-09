# dotfiles

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

```sh
curl -fsSL https://raw.githubusercontent.com/lukejans/dotfiles/main/setup.sh | bash
```

> [!Warning] > **Run at your own risk! I do not take responsibility for any data loss or other issues related to using this install script.**
>
> - This script should only be run on Apple Silicon Macs.
> - That is a highly opinionated setup.
> - Old configuration files will be backed up to `$HOME`.
> - [`setup.sh`](./setup.sh) was only tested on MacOS Sequoia.
> - See [`Brewfile`](./Brewfile) for a list of programs that will be installed.
