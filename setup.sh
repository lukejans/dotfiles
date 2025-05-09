#!/usr/bin/env bash

# MacOS Setup Script
#
# description: this script sets up a MacOS environment by installing
#              software listed in the Brewfile, configuring system
#              default settings, and linking dotfiles.
#
# author: luke janssen
# date: may 9th, 2025

{ # this ensures the entire script is downloaded #

  # ---
  # setup
  # ---
  # exit on error, unset variables, and pipe failures
  set -euo pipefail

  # ---
  # constants
  # ---
  declare -r node_version=22
  declare -r dotfiles_dir="$HOME/.dotfiles"

  # colors
  cr="\033[31;1m" # bold red
  cg="\033[32;1m" # bold green
  cy="\033[33;1m" # bold yellow
  cb="\033[34;1m" # bold blue
  cm="\033[35;1m" # bold magenta
  cc="\033[36;1m" # bold cyan
  ra="\033[0m"    # reset bold and colors
  rb="\033[0;1m"  # make bold, reset colors
  # symbols
  arrow="${cb}==>${rb}"
  check="${cg}✓${rb}"
  cross="${cr}x${rb}"

  # print install banner
  echo -e "
${cg}         .:'${ra}
${cg}     __ :'__${ra}
${cy}  .'\`__\`-'__\`\`.${ra}
${cr} :__________.-'${ra}  Running lukejans'
${cm} :_________:${ra}        MacOS setup
${cm}  :_________\`-;${ra}
${cb}   \`.__.-.__.'${ra}

This script will:
  - Install Xcode command line tools
  - Install Homebrew & programs listed inside of Brewfile
  - Clone This repo to '~/.dotfiles'
  - Symlink config files to the user home directory
  - Setup a Node.js environment with nvm and pnpm
  - Set some MacOS system settings / preferences
  - Setup a Java environment

Requirements:
  - stable internet connection
  - sudo privileges
"

  # ---
  # helper functions
  # ---

  # get confirmation from the user
  #
  # $1 - prompt / question to display to the user
  get_confirmation() {
    # prompt the user for a response
    printf "%b?%b %s %b(y/N)%b: " "$cc" "$ra" "$1" "$cc" "$ra"

    # capture the users response from
    read -n 1 -r response </dev/tty
    echo

    # check if the confirmation was positive by using a regex
    # that looks for a single "y" or "Y" character.
    if [[ "$response" =~ ^[Yy]$ ]]; then
      # user confirmed
      return 0
    else
      # user denied
      return 1
    fi
  }

  # backup existing files or directories
  #
  # $1 - the path to a file or directory
  backup() {
    # the name of the file or directory to be backed up
    local name
    name=$(basename "$1")
    # path to a file or directory that will be backed up
    local backup
    backup="${HOME}/${name}_$(date +%c).bak"

    # make the backup
    if [[ -e $1 ]]; then
      cp -RP "$1" "$backup"
      trash "$1"
    fi

    printf "Backed up %b'%s'%b to %b'%s'%b." "$cy" "$name" "$ra" "$cy" "$backup" "$ra"
  }

  print_info() {
    printf "%b %s\n" "$arrow" "$1"
  }

  print_success() {
    printf "%b %s\n" "$check" "$1"
  }

  print_error() {
    printf "%b %s\n" "$cross" "$1" >&2
  }

  # ---
  # confirm installation
  # ---
  if ! get_confirmation "Continue"; then
    # abort install
    print_error "Installation aborted."
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
  # xcode command line tools
  # ---
  print_info "Checking if Xcode command line tools are installed..."

  if ! xcode-select -p &>/dev/null; then
    printf "No xcode installation was found.\n"
    printf "Confirm the install request in the popup...\n"

    # install xcode
    xcode-select --install

    # loop until the installer has actually put the tools on disk
    until xcode-select -p &>/dev/null; do
      sleep 5
    done

    print_success "Successfully installed xcode command line tools."
  else
    printf "An xcode installation found was found.\n"
  fi

  # ---
  # homebrew
  # ---
  print_info "Checking for a homebrew installation..."

  if ! command -v brew &>/dev/null; then
    printf "Homebrew not found.\n"

    # the homebrew install command
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    printf "Homebrew installation complete.\n"
    printf "Running. %b\$(/opt/homebrew/bin/brew shellenv)%b to setup Homebrew.\n" "$cc" "$ra"

    # add homebrew to PATH for the current session
    eval "$(/opt/homebrew/bin/brew shellenv)"

    # turn homebrew analytics off on fresh installs
    if brew analytics state | grep -q "disabled"; then
      printf "Disabling brew analytics...\n"
      brew analytics off
    fi
  else
    printf "Homebrew installation found.\n"
    # brew is installed so make sure it's up to date
    brew update && brew upgrade && brew cleanup && brew autoremove
  fi

  # ---
  # clone and symlink configuration files
  # ---
  print_info "Cloning the dotfiles repository..."

  # if git is not installed, install it so we can clone the dotfiles repo
  if ! command -v git &>/dev/null; then
    printf "No git installation found.\n"
    brew install git
  else
    printf "Git installation found.\nUsing %b%s%b\n" "$cc" "$(which git)" "$ra"
  fi

  # check if the .dotfiles directory exists already then create a backup
  if [[ -d "$dotfiles_dir" ]]; then
    backup "$dotfiles_dir"
  fi

  # clone the repo
  git clone https://github.com/lukejans/dotfiles.git "$dotfiles_dir"

  # find all shell configuration files which is any file that start with
  # only a single dot inside of the shell and zsh directories.
  for item in \
    "$HOME"/.dotfiles/shell/zsh/.*[!.]* \
    "$HOME"/.dotfiles/shell/sh/.*[!.]* \
    "$HOME"/.dotfiles/.config; do

    # look in the home directory for the file. Note that this is here mostly for
    # backing up files that are not from previous dotfiles installations. If there
    # the file found was a previous dotfile installation we are essentially just
    # duplicating a file because the link will be overwritten with the git clone.
    existing_item="$HOME/$(basename "$item")"

    # back up existing configuration files
    if [[ -e "$existing_item" ]]; then
      backup "$existing_item"
    fi

    # link new shell file
    ln -sf "$item" "$existing_item"
    printf "Linked %b'%s'%b to %b'%s'%b." "$cy" "$item" "$ra" "$cy" "$existing_item" "$ra"
  done

  print_success "Cloned and linked all configuration files."

  # ---
  # brew bundle
  # ---
  print_info "Installing Homebrew packages from Brewfile..."
  brew bundle --file "$dotfiles_dir/Brewfile"

  # ---
  # node
  # see: https://nodejs.org/en/download
  # ---
  print_info "Setting up Node.js environment..."

  # install nvm if its not already installed
  if [[ ! -d "$HOME/.nvm" ]]; then
    printf "Installing nvm...\n"
    export NVM_DIR="$HOME/.nvm" && (
      git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
      cd "$NVM_DIR"
      git checkout "$(git describe --abbrev=0 --tags --match 'v[0-9]*' "$(git rev-list --tags --max-count=1)")"
    )
  fi
  # make sure nvm is loaded without restarting the shell
  \. "$NVM_DIR/nvm.sh"

  # make sure v22 is installed and the default node version
  printf "Installing node v%s...\n" "$node_version"
  nvm install $node_version
  printf "Setting Node.js v%s as default...\n" "$node_version"
  nvm alias default $node_version
  nvm use $node_version

  # enable pnpm via corepack
  printf "Enabling pnpm via corepack..."
  corepack enable
  corepack prepare pnpm@latest --activate

  # setup pnpm home directory if not set
  if [[ -z "${PNPM_HOME:-}" ]]; then
    printf "Setting up PNPM_HOME environment variable...\n"
    export PNPM_HOME="$HOME/Library/pnpm"
    case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
    esac
  else
    printf "PNPM_HOME is already configured.\n"
  fi

  # install global packages with pnpm
  printf "Installing global Node.js packages..."
  pnpm add --global "live-server"
  pnpm add --global "prettier"
  pnpm add --global "eslint"

  print_success "Node.js environment successfully setup."

  # ---
  # macOS
  # ---
  # set preferences
  print_info "Setting MacOS system preferences..."
  bash "$dotfiles_dir/scripts/macos.sh"
  printf "MacOS system preferences set.\n"

  # add fonts to the font book
  print_info "Adding fonts to the font book..."
  if [ ! -d "$HOME/Library/Fonts" ]; then
    printf "No fonts directory found.\n"
    mkdir -p "$HOME/Library/Fonts"
    printf "Created user fonts directory.\n"
  else
    printf "User fonts directory already exists.\n"
  fi

  # copy fonts to the user fonts directory
  cp "$dotfiles_dir"/assets/fonts/*.ttf "$HOME"/Library/Fonts/
  print_success "Fonts copied to user fonts directory."

  # ---
  # restart system
  # ---
  printf "%bInstallation complete!%b" "$cg" "$ra"
  printf "  - todo: add java versions to jenv"
  printf "  - warn: system restart required"

  if get_confirmation "Restart your computer now"; then
    # visual countdown
    for i in {5..1}; do
      printf "\r%b Restarting in %s..." "$arrow" "$i"
      sleep 1
    done
    printf "\rGoodBye!\n"
    sleep 0.25
    # execute restart
    sudo shutdown -r now
  else
    print_error "Restart cancelled!"
    printf "Please restart manually at your convenience!\n"
  fi

} # this ensures the entire script is downloaded #
