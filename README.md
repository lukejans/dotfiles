<div align="center">
    <h1>dotfiles</h1>
    <pre>
          .:'
      __ :'__
   .'`__`-'__``.
  :__________.-'
  :_________:
   :_________`-;
    `.__.-.__.'

MacOS development
environment setup
</pre>

</div>
> Configuration files and scripts for setting up a MacOS development environment.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/lukejans/dotfiles/main/bootstrap.sh | bash
```

> [!note]
>
> - The setup script was only built to run on Apple Silicon Macs (aarch64).
> - I've only tested [`bootstrap.sh`](./scripts/bootstrap.sh) on macOS Sequoia 15.4.1.
> - All configuration files this script intends to overwrite will be backed up to `$HOME`.
