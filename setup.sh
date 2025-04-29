#!/usr/bin/env bash

# setup for MacOS
#
# -- lukejans setup.sh

{ # this ensures the entire script is downloaded #

  # ---
  # setup
  # ---
  # exit on error, unset variables, and pipe failures
  set -euo pipefail

  # colors
  cg="\033[1;32m" # green
  cy="\033[1;33m" # yellow
  cr="\033[1;31m" # red
  cb="\033[1;34m" # blue
  cm="\033[1;35m" # purple/magenta
  cc="\033[1;36m" # cyan (uncommented this)
  r="\033[0m"     # reset
  # symbols
  arrow='➜'
  check='✓'
  cross='✗'
  qmark='?'

  # print install banner
  echo -e "
${cg}           .:'${r}
${cg}     __ :'__${r}
${cy}  .'\`__\`-'__\`\`.${r}
${cr} :__________.-'${r}  Running lukejans'
${cm} :_________:${r}        macOS setup
${cm}  :_________\`-;${r}
${cb}   \`.__.-.__.'${r}

This script will:
  - install additional software
  - install lukejans' dotfiles
  - setup your shell environment
"

  # ---
  # confirm installation
  # ---
  echo -e "${cc}${qmark}${r} Continue ${cc}(y/N)${r} \c"
  read -n 1 -r </dev/tty
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    # abort install
    echo -e "${cr}${cross}${r} Installation aborted."
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
  echo -e "${cg}${arrow}${r} Checking if Xcode command line tools are installed..."
  if ! xcode-select -p &>/dev/null; then
    echo "Xcode not found. You'll be prompted to install it..."
    xcode-select --install
    # loop until the installer has actually put the tools on disk
    until xcode-select -p &>/dev/null; do
      sleep 5
    done
    echo -e "${cg}${check}${r} Xcode command line tools successfully installed."
  else
    echo -e "${cg}${check}${r} Xcode installation found."
  fi

  # ---
  # homebrew
  # ---
  echo -e "${cg}${arrow}${r} Checking for a homebrew installation..."
  if ! command -v brew &>/dev/null; then
    echo "Homebrew not found."
    echo "Installing homebrew..."
    # the brew install command
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # add homebrew to PATH for the current session
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo -e "${cg}${check}${r} Homebrew installation complete."
  else
    echo -e "${cg}${check}${r} Homebrew installation found."
    echo -e "${cg}${arrow}${r} Updating Homebrew..."
    # brew is installed so make sure it's up to date
    brew update && brew upgrade && brew cleanup
  fi

  # ---
  # clone .dotfiles
  # ---
  echo -e "${cg}${arrow}${r} Cloning dotfiles repository to \"$DOTFILES_DIR\"..."
  # file path of the dotfiles directory
  DOTFILES_DIR="$HOME/.dotfiles"

  # check if .config directory exists already
  if [[ -d "$DOTFILES_DIR" ]]; then
    # create a backup of the existing .dotfiles directory
    backup_dir=$HOME/.dotfiles$(date +%c).bak
    cp -RL "$DOTFILES_DIR" "$backup_dir"
    trash "$DOTFILES_DIR"
    echo -e "${cg}${check}${r} Backed up old \".dotfiles\" directory to \"$backup_dir\"."
  fi
  # install git so we can clone the dotfiles repo
  echo -e "${cg}${arrow}${r} Installing git to clone dotfiles repository..."
  brew install git
  # clone the repo
  git clone https://github.com/lukejans/dotfiles.git "$DOTFILES_DIR"
  echo -e "${cg}${check}${r} Dotfiles repository cloned."

  # ---
  # brew bundle
  # ---
  echo -e "${cg}${arrow}${r} Installing Homebrew packages from Brewfile..."
  brew bundle --verbose --file "$DOTFILES_DIR/Brewfile"
  echo -e "${cg}${check}${r} Homebrew packages installed."

  # ---
  # symlink config directory
  # ---
  echo -e "${cg}${arrow}${r} Linking \".config\" directory..."
  # check if .config directory exists
  if [[ -d "$HOME/.config" ]]; then
    # backup existing .config directory
    backup_dir=$HOME/.config$(date +%c).bak
    cp -RL "$HOME/.config" "$backup_dir"
    trash "$HOME/.config"
    echo -e "${cg}${check}${r} Backed up existing .config directory to \"$backup_dir\"."
  fi
  # create the link for the entire .config directory
  ln -sf "$DOTFILES_DIR/.config" "$HOME/.config"
  echo -e "${cg}${check}${r} Linked \"$HOME/.config\" directory to \"$HOME/.config\"."

  # ---
  # symlink zsh files
  # ---
  echo -e "${cg}${arrow}${r} Linking zsh configuration files..."
  # backup existing files if they're not symlinks
  for file in "$DOTFILES_DIR"/.config/zsh/*.z; do
    # backup existing zshell configuration files
    if [[ -f "$file" ]]; then
      backup_file="$file$(date +%c).bak"
      cp -RL "$file" "$backup_file"
      echo "${cg}${check}${r} Backed up existing \"$(basename "$file")\" to \"$backup_file\"."
    fi
    # link newly cloned zshell file
    ln -sf "$file" "$HOME/$(basename "$file")"
  done
  echo -e "${cg}${check}${r} Linked zsh configuration files."

  # ---
  # node
  # see: https://nodejs.org/en/download
  # ---
  echo -e "${cg}${arrow}${r} Setting up Node.js environment..."
  # install nvm
  # check and install nvm if needed
  if [[ ! -d "$HOME/.nvm" ]]; then
    echo -e "${cg}${arrow}${r} Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  fi

  # load nvm without restarting the shell
  export NVM_DIR="$HOME/.nvm"
  \. "$NVM_DIR/nvm.sh"
  # make sure v22 is installed and the default node version
  echo -e "${cg}${arrow}${r} Checking for Node.js v22..."
  nvm install 22
  echo -e "${cg}${arrow}${r} Setting Node.js v22 as default..."
  nvm alias default 22
  nvm use 22

  # enable pnpm via corepack
  echo -e "${cg}${arrow}${r} Enabling pnpm via corepack..."
  corepack enable
  corepack prepare pnpm@latest --activate
  # setup pnpm home directory if not set
  if [[ -z "${PNPM_HOME:-}" ]]; then
    echo -e "${cg}${arrow}${r} Setting up PNPM_HOME environment variable..."
    export PNPM_HOME="/Users/lukejans/Library/pnpm"
    case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
    esac
  else
    echo "PNPM_HOME is already configured."
  fi

  # install global packages with pnpm
  echo -e "${cg}${arrow}${r} Installing global Node.js packages..."
  pnpm add --global "live-server"
  pnpm add --global "prettier"
  pnpm add --global "eslint"

  echo "Node.js environment:"
  echo -e "  - ${cg}${check}${r} nvm: $(nvm -v)"
  echo -e "  - ${cg}${check}${r} node: $(node -v)"
  echo -e "  - ${cg}${check}${r} pnpm: $(pnpm -v)"

  # ---
  # macOS
  # ---
  # set preferences
  echo -e "${cg}${arrow}${r} Setting macOS system preferences..."
  source "$DOTFILES_DIR/macos.sh"
  echo -e "${cg}${check}${r} macOS system preferences set."

  # add fonts to the font book
  echo -e "${cg}${arrow}${r} Adding fonts to the font book..."
  if [ ! -d "$HOME/Library/Fonts" ]; then
    echo "No fonts directory found."
    mkdir -p "$HOME/Library/Fonts"
    echo "Created user fonts directory."
  else
    echo "User fonts directory already exists."
  fi
  cp "$DOTFILES_DIR/assets/fonts/*.ttf" "$HOME/Library/Fonts/"
  echo -e "${cg}${check}${r} Fonts copied to user fonts directory."

  # ---
  # installation end
  # ---
  end_time=$(date +%s)
  install_time=$((end_time - start_time))

  # ---
  # restart system
  # ---
  echo -e "\n${cc}Installation complete!${r}"
  echo -e "  - ${cy}setup time${r}: ${install_time}s"
  echo -e "  - ${cc}todo${r}: add java versions to jenv"
  echo -e "  - ${cr}warn${r}: system restart required"
  echo -e "${cc}${qmark}${r} Restart your computer now ${cc}(y/N)${r} \c"
  read -n 1 -r </dev/tty
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    # visual countdown
    for i in {5..1}; do
      echo -ne "\r${cm}${arrow}${r}Restarting in $i..."
      sleep 1
    done
    echo "\rGoodBye!"
    # execute restart
    sudo shutdown -r now
  else
    echo -e "${cc}${cross}${r} Restart cancelled!"
    echo -e "Please restart manually at your convenience\!\n "
  fi

} # this ensures the entire script is downloaded #
