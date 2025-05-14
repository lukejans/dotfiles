#!/usr/bin/env bash

# MacOS Setup Script
#
# description: this script sets up a MacOS environment by installing
#              software listed in the Brewfile, configuring system
#              default settings, and linking dotfiles.
#
# author: luke janssen
# date: may 9th, 2025

# TODO:
#   - java environment with jenv
#   - find a way to handle brew caveats

{ # this ensures the entire script is downloaded before execution #

  # ---
  # setup
  # ---
  # exit on error, unset variables, and pipe failures
  set -euo pipefail

  # ---
  # constants
  # ---
  declare -r DOTFILES_DIR="${HOME}/.dotfiles"

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
  printf "
%b         .:'%b
%b     __ :'__%b
%b  .'\`__\`-'__\`\`.%b
%b :__________.-'%b  Running lukejans'
%b :_________:%b        MacOS setup
%b  :_________\`-;%b
%b   \`.__.-.__.'%b

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
" "${cg}" "${ra}" "${cg}" "${ra}" "${cy}" "${ra}" "${cr}" "${ra}" "${cm}" "${ra}" "${cm}" "${ra}" "${cb}" "${ra}"

  # ---
  # helper functions
  # ---

  # get confirmation from the user
  #
  # $1 - prompt / question to display to the user
  get_confirmation() {
    # prompt the user for a response
    printf "%b?%b %s %b(y/N)%b: " "${cc}" "${ra}" "${1}" "${cc}" "${ra}"

    # capture the users response from
    read -n 1 -r response </dev/tty
    echo

    # check if the confirmation was positive by using a regex
    # that looks for a single "y" or "Y" character.
    if [[ "${response}" =~ ^[Yy]$ ]]; then
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
    name=$(basename "${1}")
    # path to a file or directory that will be backed up
    local backup
    backup="${HOME}/${name}_$(date +%c).bak"

    # make the backup
    if [[ -e ${1} ]]; then
      cp -RP "${1}" "${backup}"
      trash "${1}"
    fi

    printf "Backed up %b'%s'%b to %b'%s'%b.\n" "${cy}" "${name}" "${ra}" "${cy}" "${backup}" "${ra}"
  }

  print_info() {
    printf "%b %s\n" "${arrow}" "${1}"
  }

  print_success() {
    printf "%b %b\n" "${check}" "${1}"
  }

  print_error() {
    printf "%b %s\n" "${cross}" "${1}" >&2
  }

  # ---
  # homebrew
  # note: homebrew will install xcode command line tools if needed
  # ---
  setup_homebrew() {
    print_info "Checking for a homebrew installation..."

    if ! command -v brew &>/dev/null; then
      printf "Homebrew not found.\n"
      print_info "Installing Homebrew (this will also install Xcode Command Line Tools if needed)..."

      # the homebrew install command
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

      printf "Verifying Homebrew installation...\n"

      # make sure the brew command is available
      if ! command -v brew &>/dev/null; then
        # set the path for this session if brew exists but isn't in PATH yet
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
          # add homebrew to $PATH for the current session
          printf "Adding %b\$(/opt/homebrew/bin/brew shellenv)%b to \$PATH.\n" "${cc}" "${ra}"
          eval "$(/opt/homebrew/bin/brew shellenv)"
        else
          print_error "Homebrew installation failed or wasn't added to PATH"
          return 1
        fi
      fi

      print_success "Homebrew installation complete."
    else
      printf "Homebrew installation found.\n"
      # brew is installed so make sure it's up to date
      brew update && brew upgrade && brew cleanup && brew autoremove
    fi

    # turn homebrew analytics off
    if ! brew analytics state | grep -q "disabled"; then
      printf "Disabling brew analytics...\n"
      brew analytics off
    fi

    # make sure we don't get "zsh compinit: insecure directories” warnings
    chmod -R go-w "$(brew --prefix)/share"
  }

  # ---
  # clone and symlink configuration files
  # ---
  clone_and_symlink_dotfiles() {
    print_info "Cloning the dotfiles repository..."

    # if git is not installed, install it so we can clone the dotfiles repo
    if ! command -v git &>/dev/null; then
      printf "No git installation found.\n"
      brew install git
    else
      printf "Git installation found.\nUsing %b%s%b\n" "${cc}" "$(which git)" "${ra}"
    fi

    # check if the .dotfiles directory exists already then create a backup
    if [[ -d "${DOTFILES_DIR}" ]]; then
      backup "${DOTFILES_DIR}"
    fi

    # clone the repo
    git clone https://github.com/lukejans/dotfiles.git "${DOTFILES_DIR}"

    # find all shell configuration files which is any file that start with
    # only a single dot inside of the shell and zsh directories.
    for item in \
      "${HOME}"/.dotfiles/zsh/.*[!.]* \
      "${HOME}"/.dotfiles/sh/.*[!.]* \
      "${HOME}"/.dotfiles/.config; do

      # look in the home directory for the file. Note that this is here mostly for
      # backing up files that are not from previous dotfiles installations. If there
      # the file found was a previous dotfile installation we are essentially just
      # duplicating a file because the link will be overwritten with the git clone.
      existing_item="${HOME}/$(basename "${item}")"

      # back up existing configuration files
      if [[ -e "${existing_item}" ]]; then
        backup "${existing_item}"
      fi

      # link new shell file
      ln -sf "${item}" "${existing_item}"
      printf "Linked %b'%s'%b to %b'%s'%b.\n" "${cy}" "${item}" "${ra}" "${cy}" "${existing_item}" "${ra}"
    done

    print_success "Cloned and linked all configuration files."
  }

  # ---
  # brew bundle
  # ---
  install_brew_packages() {
    print_info "Installing Homebrew packages from Brewfile..."
    # install all packages if system dependencies are not up to date
    brew bundle check --global || brew bundle install --global

    # display a summary of installed packages
    print_info "Summarizing installed packages..."
    brew list --versions | sort

    print_success "Homebrew packages installed successfully."
  }

  # ---
  # mise toolchain setup
  # ---
  install_mise_packages() {
    print_info "Installing mise packages..."
    # install all packages if system dependencies are not up to date
    (
      cd "${HOME}"
      mise install
    )
    print_success "mise packages installed successfully."
  }

  # ---
  # macOS
  # ---
  setup_macos() {
    # set defaults and system preferences
    print_info "Setting MacOS system preferences..."
    sudo bash "${DOTFILES_DIR}/scripts/macos.sh"
    printf "MacOS system preferences set.\n"

    # add fonts to the font book
    print_info "Adding fonts to the font book..."
    if [ ! -d "${HOME}/Library/Fonts" ]; then
      printf "No fonts directory found.\n"
      mkdir -p "${HOME}/Library/Fonts"
      printf "Created user fonts directory.\n"
    else
      printf "User fonts directory already exists.\n"
    fi

    # copy fonts to the user fonts directory
    cp "${DOTFILES_DIR}"/desktop/fonts/*.ttf "${HOME}"/Library/Fonts/
    print_success "Fonts copied to user fonts directory."
  }

  # ---
  # zen browser setup
  # ---
  zen_browser_setup() {
    # this function will setup the zen browser custom css
    print_info "setting up zen browser custom css"

    local ZEN_DIR="${HOME}/Library/Application Support/zen"
    local ZEN_CSS="${DOTFILES_DIR}/desktop/zen-browser/userChrome.css"

    # make sure zen is actually installed
    if [[ -d "${ZEN_DIR}" ]]; then

      # look for the (release) profile inside the zen profiles
      for profile in "${ZEN_DIR}/Profiles/"*; do
        # link the css file to the (release) profile
        if [[ -d "${profile}" && "$(basename "${profile}")" == *"(release)"* ]]; then
          printf "Linking %s to the zen (release) profile\n" "$(basename "${ZEN_CSS}")"
          # make sure the chrome directory exists before linking
          mkdir -p "${profile}/chrome"
          ln -sf "${ZEN_CSS}" "${profile}/chrome/userChrome.css"
          break
        fi
      done
    else
      # zen browser may not be installed or setup properly
      printf "Zen browser is not installed so %s was not symlinked\n" "$(basename "${ZEN_CSS}")"
    fi
  }

  # ---
  # restart system
  # ---
  restart_system() {
    printf "%bInstallation complete!%b\n" "${cg}" "${ra}"
    printf "  - warn: system restart required\n"
    printf "  - todo: setup ssh keys\n"
    printf "  - todo: create a ~/.config/git/config.local\n"

    if get_confirmation "Restart your computer now"; then
      # visual countdown
      for i in {5..1}; do
        printf "\r%b Restarting in %s...\n" "${arrow}" "${i}"
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
  }

  # ---
  # main function
  # ---
  main() {
    # confirm installation
    if ! get_confirmation "Continue"; then
      # abort install
      print_error "Installation aborted."
      exit 0
    fi

    # validate sudo access
    sudo -v
    # keep sudo alive
    while true; do
      # refresh sudo timestamp
      sudo -n true
      # wait 60 seconds before the next loop
      sleep 60
      # exit if the script is done running
      kill -0 "$$" || exit
      # discard all output and run as a background process
    done &>/dev/null &

    # run installation steps
    setup_homebrew
    clone_and_symlink_dotfiles
    install_brew_packages
    install_mise_packages
    setup_macos
    zen_browser_setup
    restart_system
  }

  # run the main function
  main

} # this ensures the entire script is downloaded before execution #
