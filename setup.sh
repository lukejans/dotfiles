#!/usr/bin/env bash

# setup for MacOS
#
# -- lukejans setup.sh

# exit on error
set -e

# colors used
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
RESET="\033[0m"

# print install banner
echo
echo -e "${GREEN}         .:'${RESET}"
echo -e "${GREEN}     __ :'__${RESET}"
echo -e "${YELLOW}  .'\`__\`-'__\`\`.${RESET}"
echo -e "${RED} :__________.-'${RESET}  Running lukejans'"
echo -e "${MAGENTA} :_________:${RESET}        macOS setup"
echo -e "${CYAN}  :_________\`-;${RESET}"
echo -e "${RESET}   \`.__.-.__.'${RESET}"
echo

# confirm installation prompt
echo "This script will: "
echo "  - install additional software"
echo "  - install lukejans' dotfiles"
echo "  - setup your shell environment"
echo

read -p "Continue? (y/N) " -n 1 -r

echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Installation aborted."
  exit 0
fi

# sudo is required for some commands
sudo -v

# keep sudo alive
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

# start an install timer
start_time=$(date +%s)

# --- xcode command line tools
if ! xcode-select -p &>/dev/null; then
  echo -e "${GREEN}->${RESET} Installing Xcode command line tools..."
  xcode-select --install
  # loop until the installer has actually put the tools on disk
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
fi

# --- homebrew
if ! command -v brew &>/dev/null; then
  echo -e "${GREEN}->${RESET} Installing \`\$ brew\`..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # add Homebrew to PATH for the current session
  eval "$(/opt/homebrew/bin/brew shellenv)"

  # install git immediately to clone the dotfiles repo
  echo -e "${GREEN}->${RESET} Installing git..."
  brew install git
fi

# --- clone the most recent version of the .dotfiles repo
DOTFILES_DIR="$HOME/.dotfiles"
if [[ -d "$DOTFILES_DIR" ]]; then
  echo -e "${GREEN}->${RESET} Dotfiles directory exists, updating..."
  cd "$DOTFILES_DIR" && git pull
else
  echo -e "${GREEN}->${RESET} Downloading dotfiles repository..."
  git clone https://github.com/lukejans/dotfiles.git "$DOTFILES_DIR"
fi

# --- install homebrew packages
echo -e "${GREEN}->${RESET} Installing Homebrew packages from Brewfile..."
brew bundle --file "$DOTFILES_DIR/Brewfile"

# --- symlink general configuration files
echo -e "${GREEN}->${RESET} Linking \`.config\` directory..."
# check if .config directory exists and is not a symlink
if [[ -d "$HOME/.config" && ! -L "$HOME/.config" ]]; then
  echo "Backing up existing config directory to $HOME/.config.bak"
  # if there is already a `.config.bak` folder move the old backup
  # to the trash so we don't overwrite before creating a new backup
  if [[ -d "$HOME/.config.bak" ]]; then
    echo "Trashing existing backup..."
    if command -v trash &>/dev/null; then
      trash "$HOME/.config.bak"
    else
      mv "$HOME/.config.bak" "$HOME/.Trash"
    fi
  fi
  # create the backup
  mv "$HOME/.config" "$HOME/.config.bak"
elif [[ -L "$HOME/.config" ]]; then
  # remove the old link
  rm "$HOME/.config"
fi
# create the link for the entire `.config` directory
ln -sf "$DOTFILES_DIR/.config" "$HOME/.config"
echo -e "Linked \`.config\` directory to \`$HOME/.config\`"

# --- symlink zsh configuration files
echo -e "${GREEN}->${RESET} Linking zsh configuration files..."
# Backup existing files if they're not symlinks
for file in ".zshrc" ".zshenv" ".profile"; do
  if [[ -f "$HOME/$file" && ! -L "$HOME/$file" ]]; then
    echo "Backing up existing $file to $HOME/${file}.bak"
    mv "$HOME/$file" "$HOME/${file}.bak"
  fi
done
ln -sf "$DOTFILES_DIR/.config/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/.config/zsh/.zshenv" "$HOME/.zshenv"
ln -sf "$DOTFILES_DIR/.config/shell/.profile" "$HOME/.profile"
echo "Linked zsh configuration files"

# --- node
# see: https://nodejs.org/en/download
echo -e "${GREEN}->${RESET} Setting up Node.js environment..."
# check and install nvm if needed
if [[ ! -d "$HOME/.nvm" ]]; then
  echo "Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
else
  echo "nvm is already installed."
fi

# load nvm without restarting the shell
export NVM_DIR="$HOME/.nvm"
\. "$NVM_DIR/nvm.sh"

# check if we have Node.js v22 installed
if ! nvm ls 22 | grep -q "v22"; then
  echo "Installing Node.js v22..."
  nvm install 22
else
  echo "Node.js v22 is already installed."
fi

# make sure v22 is the default
if [[ "$(nvm current)" != "v22"* ]]; then
  echo "Setting Node.js v22 as default..."
  nvm alias default 22
  nvm use 22
fi

# enable and prepare pnpm via corepack
if ! command -v pnpm &>/dev/null; then
  echo "Setting up pnpm via corepack..."
  corepack enable
  corepack prepare pnpm@latest --activate
else
  # update pnpm if it's already installed
  echo "Updating pnpm to latest version..."
  corepack prepare pnpm@latest --activate
fi

echo "Node.js environment:"
echo "  - nvm version: $(nvm -v)"
echo "  - node version: $(node -v)"
echo "  - pnpm version: $(pnpm -v)"

# install global npm packages
install_if_missing() {
  local package=$1
  if ! pnpm list -g "$package" &>/dev/null; then
    echo "Installing $package globally..."
    pnpm add -g "$package"
  else
    echo "$package is already installed."
  fi
}
echo "Installing global Node.js packages..."
install_if_missing "live-server"
install_if_missing "prettier"
install_if_missing "eslint"

# --- apply macOS preferences
echo -e "${GREEN}->${RESET} Applying macOS preferences..."
source "$DOTFILES_DIR/macos.sh"

# --- add fonts to the font book
if [ ! -d "$HOME/Library/Fonts" ]; then
  echo -e "${GREEN}->${RESET} Creating user fonts directory..."
  mkdir -p "$HOME/Library/Fonts"
else
  echo "User fonts directory already exists."
  echo -e "${GREEN}->${RESET} Adding fonts to the font book..."
  cp $DOTFILES_DIR/assets/fonts/*.ttf "$HOME/Library/Fonts/"
fi

# --- set zsh as default shell if it's not already
if [[ "$SHELL" != *"zsh"* ]]; then
  echo -e "${GREEN}->${RESET} Setting Zsh as default shell..."
  chsh -s "$(command -v zsh)"
fi

# end install timer
end_time=$(date +%s)
install_time=$((end_time - start_time))

# --- installation complete info and restart prompt
echo -e "\n${CYAN}Installation complete!${RESET}"
echo -e "  - setup time: ${YELLOW}${install_time}s${RESET}"
echo "  - todo: add java versions to jenv"
echo "  - system restart required"
read -p "Restart your computer now? (y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  # visual countdown
  for i in {5..1}; do
    echo -ne "\rRestarting in $i..."
    sleep 1
  done
  echo -e "\rRestarting now!"

  # execute restart
  sudo shutdown -r now
else
  echo -e "\nRestart cancelled!"
  echo -e "Please restart manually at your convenience.\n "
fi
