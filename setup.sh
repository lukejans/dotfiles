#!/usr/bin/env bash

# MacOS Setup Script
#
# description: This script sets up a macOS environment by installing
#              software listed in the Brewfile, configuring system
#              default settings, and linking dotfiles.
#
# author: luke janssen
# date: may 6th 2025

{ # this ensures the entire script is downloaded #

  # ---
  # setup
  # ---
  # exit on error, unset variables, and pipe failures
  set -euo pipefail

  # colors
  cr="\033[31m" # red
  cg="\033[32m" # green
  cy="\033[33m" # yellow
  cb="\033[34m" # blue
  cm="\033[35m" # magenta
  cc="\033[36m" # cyan
  r="\033[0m"   # reset
  b="\033[1m"   # bold
  # symbols
  arrow="\033[1;34m==>\033[0m" # bold blue arrow
  check="\033[1;32m✓\033[0m"   # bold green check
  cross="\033[1;31mx\033[0m"   # bold red cross
  qmark="\033[1;36m?\033[0m"   # bold cyan question mark

  # print install banner
  echo -e "
${cg}${b}          .:'${r}
${cg}${b}     __ :'__${r}
${cy}${b}  .'\`__\`-'__\`\`.${r}
${cr}${b} :__________.-'${r}  Running lukejans'
${cm}${b} :_________:${r}        macOS setup
${cm}${b}  :_________\`-;${r}
${cb}${b}   \`.__.-.__.'${r}

This script will:
  - install packages from homebrew
  - setup configuration files
"

  # ---
  # helper functions
  # ---
  backup() {
    # the first parameter is the path to the file or directory
    # that needs to be backed up and the second is where you want
    # that backup to be placed.
    local backup name
    name=$(basename "$1")
    backup="${HOME}/${name}_$(date +%c).bak"

    # make the backup
    cp -RL "$1" "$backup"
    trash "$1"

    echo -e "Backed up ${cy}\"$name\"${r} to ${cy}\"$backup\"${r}."
  }

  # ---
  # confirm installation
  # ---
  echo -e "${qmark} Continue ${cc}${b}(y/N)${r} \c"
  read -n 1 -r </dev/tty
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    # abort install
    echo -e "${cross} Installation aborted."
    exit 0
  fi

  # ---
  # sudo
  # ---
  # validate sudo access
  sudo -v
  # keep sudo alive
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &

  # ---
  # installation start
  # ---
  start_time=$(date +%s)

  # ---
  # xcode command line tools
  # ---
  echo -e "${arrow} Checking if Xcode command line tools are installed..."
  if ! xcode-select -p &>/dev/null; then
    echo "Xcode not found. You'll be prompted to install it..."
    xcode-select --install
    # loop until the installer has actually put the tools on disk
    until xcode-select -p &>/dev/null; do
      sleep 5
    done
    echo -e "${check} Xcode command line tools successfully installed."
  else
    echo -e "Xcode installation found."
  fi

  # ---
  # homebrew
  # ---
  echo -e "${arrow} Checking for a homebrew installation..."
  if ! command -v brew &>/dev/null; then
    echo "Homebrew not found."

    # the homebrew install command
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # add homebrew to PATH for the current session
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo "Homebrew installation complete."
  else
    echo "Homebrew installation found."
    # brew is installed so make sure it's up to date
    brew update && brew upgrade && brew cleanup
  fi

  # ---
  # clone and symlink configuration files
  # ---
  # file path of the dotfiles directory
  DOTFILES_DIR="$HOME/.dotfiles"

  echo -e "${arrow} Cloning the dotfiles repository to \"$DOTFILES_DIR\"..."

  # if git is not installed, install it so we can clone the dotfiles repo
  if ! command -v git &>/dev/null; then
    echo "Installing git to clone dotfiles repository..."
    brew install git
  fi

  # check if the .dotfiles directory exists already then create a backup
  if [[ -d "$DOTFILES_DIR" ]]; then
    backup "$DOTFILES_DIR"
  fi

  # clone the repo
  git clone https://github.com/lukejans/dotfiles.git "$DOTFILES_DIR"

  # find all shell configuration files which is any file that start with
  # only a single dot inside of the shell and zsh directories.
  for item in \
    "$HOME"/.dotfiles/shell/zsh/.*[!.]* \
    "$HOME"/.dotfiles/shell/sh/.*[!.]* \
    "$HOME"/.dotfile/.config; do

    # look in the home directory for the file. Note that this is here mostly for
    # backing up files that are not from previous dotfiles installations. If there
    # the file found was a previous dotfile installation we are essentially just
    # duplicating a file because the link will be overwritten with the git clone.
    existing_item="$HOME/$(basename "$item")"

    # back up existing configuration files
    if [[ -f "$existing_item" ]]; then
      backup "$existing_item"
    fi

    # link new shell file
    ln -sf "$item" "$existing_item"
    echo -e "Linked ${cy}\"$item\"${r} to ${cy}\"$existing_item\"${r}."
  done

  echo -e "${check} Cloned and linked all configuration files."

  # ---
  # brew bundle
  # ---
  echo -e "${arrow} Installing Homebrew packages from Brewfile..."
  brew bundle --verbose --file "$DOTFILES_DIR/Brewfile"

  # ---
  # node
  # see: https://nodejs.org/en/download
  # ---
  echo -e "${arrow} Setting up Node.js environment..."

  # install nvm if its not already installed
  if [[ ! -d "$HOME/.nvm" ]]; then
    echo -e "${arrow} Installing nvm..."
    export NVM_DIR="$HOME/.nvm" && (
      git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
      cd "$NVM_DIR"
      git checkout "$(git describe --abbrev=0 --tags --match 'v[0-9]*' "$(git rev-list --tags --max-count=1)")"
    )
  fi
  # make sure nvm is loaded without restarting the shell
  \. "$NVM_DIR/nvm.sh"

  # make sure v22 is installed and the default node version
  echo -e "${arrow} Checking for Node.js v22..."
  nvm install 22
  echo -e "${arrow} Setting Node.js v22 as default..."
  nvm alias default 22
  nvm use 22

  # enable pnpm via corepack
  echo -e "${arrow} Enabling pnpm via corepack..."
  corepack enable
  corepack prepare pnpm@latest --activate

  # setup pnpm home directory if not set
  if [[ -z "${PNPM_HOME:-}" ]]; then
    echo -e "${arrow} Setting up PNPM_HOME environment variable..."
    export PNPM_HOME="/Users/lukejans/Library/pnpm"
    case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
    esac
  else
    echo "PNPM_HOME is already configured."
  fi

  # install global packages with pnpm
  echo -e "${arrow} Installing global Node.js packages..."
  pnpm add --global "live-server"
  pnpm add --global "prettier"
  pnpm add --global "eslint"

  echo "Node.js environment:"
  echo -e "  - ${check} nvm: $(nvm -v)"
  echo -e "  - ${check} node: $(node -v)"
  echo -e "  - ${check} pnpm: $(pnpm -v)"

  # ---
  # macOS
  # ---
  # set preferences
  echo -e "${arrow} Setting macOS system preferences..."
  bash "$DOTFILES_DIR/macos.sh"
  echo -e "macOS system preferences set."

  # add fonts to the font book
  echo -e "${arrow} Adding fonts to the font book..."
  if [ ! -d "$HOME/Library/Fonts" ]; then
    echo "No fonts directory found."
    mkdir -p "$HOME/Library/Fonts"
    echo "Created user fonts directory."
  else
    echo "User fonts directory already exists."
  fi

  # copy fonts to the user fonts directory
  cp "$DOTFILES_DIR"/assets/fonts/*.ttf "$HOME"/Library/Fonts/
  echo -e "Fonts copied to user fonts directory."

  # ---
  # installation end
  # ---
  end_time=$(date +%s)
  install_time=$((end_time - start_time))

  # ---
  # restart system
  # ---
  echo -e "\n${cg}Installation complete!${r}"
  echo -e "  - time: ${install_time}s"
  echo -e "  - todo: add java versions to jenv"
  echo -e "  - warn: system restart required"
  echo -e "${qmark} Restart your computer now ${cc}${b}(y/N)${r} \c"
  read -n 1 -r </dev/tty
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    # visual countdown
    for i in {5..1}; do
      echo -ne "\r${arrow}Restarting in $i..."
      sleep 1
    done
    echo "\rGoodBye!"
    # execute restart
    sudo shutdown -r now
  else
    echo -e "${cross} Restart cancelled!"
    echo -e "Please restart manually at your convenience!\n"
  fi

} # this ensures the entire script is downloaded #
