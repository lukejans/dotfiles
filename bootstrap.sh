#!/usr/bin/env bash

# MacOS Setup Script
#
# description: this script sets up a MacOS development environment by
#              installing software and tools listed in the Brewfile,
#              configuring system default settings, and linking dotfiles.
#
# author: luke janssen
# date: may 15th, 2025

{ # this ensures the entire script is downloaded before execution #

    # ---
    # setup
    # ---
    # exit on error, unset variables, and pipe failures
    set -euo pipefail

    # ---
    # exports
    # ---
    export XDG_CONFIG_HOME="${HOME}/.config"

    # ---
    # constants
    # ---
    declare REQ_SYS_RESTART=false
    declare DOTFILES_BACKUP_DIR
    declare -r DOTFILES_DIR="${HOME}/.dotfiles"
    declare -r REPO_URL="https://github.com/lukejans/dotfiles.git"

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
    printf "\n%b         .:'%b\n" "${cg}" "${ra}"
    printf "%b     __ :'__%b\n" "${cg}" "${ra}"
    printf "%b  .'\`__\`-'__\`\`.%b\n" "${cy}" "${ra}"
    printf "%b :__________.-'%b  Running \"bootstrap.sh\"\n" "${cr}" "${ra}"
    printf "%b :_________:%b\n" "${cm}" "${ra}"
    printf "%b  :_________\`-;%b\n" "${cm}" "${ra}"
    printf "%b   \`.__.-.__.'%b\n" "${cb}" "${ra}"
    printf "\nRequirements:\n"
    printf "    - signed into an Apple ID\n"
    printf "    - sudo privileges\n"

    # ---
    # helper functions
    # ---

    # brew command wrapper to ensure that brew does not interfere
    # with sudo time stamps. This issue is explained in detail with
    # [issue #17912](https://github.com/Homebrew/brew/issues/17912)
    brew() {
        script -q /dev/null "$(command -v brew)" "$@" | sed 's/\r//g'
    }

    # get confirmation from the user
    #
    # $1 - prompt / question to display to the user
    #
    # returns: 0 if confirmed, 1 if denied
    get_confirmation() {
        # prompt the user for a response
        printf "%b?%b %s %b(y/N)%b: " "${cc}" "${ra}" "${1}" "${cc}" "${ra}"

        # capture the users response from
        read -r response </dev/tty

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
    #
    # stdout: path to the backup file via stdout
    # stderr: information about the backup process
    backup() {
        # the name of the file or directory to be backed up
        local name
        name=$(basename "${1}")
        # path to a file or directory that will be backed up
        local backup
        backup="${HOME}/${name}_$(date +%Y%m%d_%H%M%S).bak"

        # make the backup
        if [[ -e ${1} ]]; then
            cp -RP "${1}" "${backup}"
            trash "${1}"
        fi

        # return the value to stdout so other operations know the
        # path to the backed up version of the file / directory.
        echo "${backup}"
    }

    # print an informational message with an arrow
    #
    # $1 - message to display
    #
    # stdout: informational message
    print_info() {
        printf "%b %s%b\n" "${arrow}" "${1}" "${ra}"
    }

    # print a success message with a check mark
    #
    # $1 - message to display
    #
    # stdout: success message
    print_success() {
        printf "%b %b%b\n" "${check}" "${1}" "${ra}"
    }

    # print an error message with a cross
    #
    # $1 - message to display
    #
    # stderr: error message
    print_error() {
        printf "%b %s%b\n" "${cross}" "${1}" "${ra}" >&2
    }

    # ---
    # homebrew
    # ---
    setup_homebrew() {
        if ! command -v brew &>/dev/null; then
            # the homebrew install command
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            # make sure the brew command is available
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            # brew is installed so make sure it's up to date
            brew update
            brew upgrade
            brew cleanup --prune=all
            brew autoremove
        fi

        # turn homebrew analytics off
        if ! brew analytics state | grep -q "disabled"; then
            brew analytics off
        fi

        # make sure we don't get "zsh compinit: insecure directories” warnings
        chmod -R go-w "$(brew --prefix)/share"
    }

    # ---
    # clone and symlink configuration files
    # ---
    clone_repo() {
        # if git is not installed, install it so we can clone the dotfiles repo
        if ! command -v git &>/dev/null; then
            brew install git
        fi

        # check if the .dotfiles directory exists already then create a backup
        if [[ -d "${DOTFILES_DIR}" ]]; then
            # backup the existing dotfiles repo before a fresh clone. This might
            # change in the future but this seemed to make the most sense due to
            # the "$DOTFILES_DIR" potentially not being a git dir and also might
            # have uncommitted changes.
            DOTFILES_BACKUP_DIR=$(backup "${DOTFILES_DIR}")
        fi

        # clone the repo
        git clone "${REPO_URL}" "${DOTFILES_DIR}"
    }

    setup_dotfiles() {
        # if the DOTFILES_BACKUP_DIR variable is set and has a value then attempt
        # to backup files listed under the "# sync" header in .gitignore.
        if [[ -n "${DOTFILES_BACKUP_DIR:-}" ]]; then
            # the repos gitignore file
            local gitignore_file="${HOME}/.dotfiles/.gitignore"

            # get the line number of the `# sync` header
            line_num=$(grep -n "^# sync" "${gitignore_file}" | cut -d ":" -f 1)

            # loop over the files / directories present in that section to copy
            for item in $(tail -n +$((line_num + 1)) "${gitignore_file}"); do

                local source="${DOTFILES_BACKUP_DIR}/${item}"
                local dest="${DOTFILES_DIR}/${item}"

                if [ -e "${source}" ]; then
                    # make sure the parent directory is present before copying
                    mkdir -p "$(dirname "${dest}")"
                    rsync -a "${source}" "$(dirname "${dest}")/"
                fi
            done
        fi

        # find all shell configuration files which is any file that start with
        # only a single dot inside of the shell and zsh directories.
        for item_src in \
            "${HOME}"/.dotfiles/zsh/.*[!.]* \
            "${HOME}"/.dotfiles/sh/.*[!.]* \
            "${HOME}"/.dotfiles/.config; do

            # the location a dotfile will be linked to
            item_dest="${HOME}/$(basename "${item_src}")"

            # if the destination file already exists, create a backup
            if [[ -e "${item_dest}" ]]; then
                # if the destination is a symlink just remove the link
                if [[ -L "${item_dest}" ]]; then
                    rm "${item_dest}"
                else
                    # the file is not a symlink so make a backup
                    backup "${item_dest}"
                fi
            fi

            # link the source item
            ln -sf "${item_src}" "${item_dest}"
        done
    }

    # ---
    # brew bundle
    # ---
    install_brew_packages() {
        # check if the full xcode toolchain was already installed. This is
        # just looking to see if metal is installed which is only installed
        # with the ide and not with the command line tools. This is here
        # because we must agree to the license on a fresh install.
        local agree_to_license=false
        if ! xcrun --find metal >/dev/null 2>&1; then
            # metal was not found so we will have to agree to the xcode ide
            # license after homebrew installs it.
            agree_to_license=true
        fi

        # install all packages if system dependencies are not up to date
        brew bundle check --global || brew bundle install --global

        # agree to the xcode license after it's installed
        if ${agree_to_license}; then
            sudo xcodebuild -license accept
        fi
    }

    # ---
    # mise toolchain setup
    # ---
    install_mise_tools() {
        # install all packages if system dependencies are not up to date
        (
            cd "${HOME}"

            # trust the global mise config on the first run
            mise trust

            # install the global mise tools
            mise install

            # additional tool versions that might not be in mise.toml
            mise install java@liberica-javafx-21
            mise install node@latest
        )
    }

    # ---
    # macOS
    # ---
    declare SELECTED_WALLPAPER

    set_mac_wallpaper() {
        local path_to_wallpaper="${DOTFILES_DIR}/desktop/wallpapers/${SELECTED_WALLPAPER}"
        # set the wallpaper
        sudo osascript -e "tell application \"System Events\" to set picture of every desktop to POSIX file \"${path_to_wallpaper}\""
    }

    choose_mac_wallpaper() {
        declare -a wallpaper_array
        declare -i i=0

        # build the wallpaper array
        for wallpaper in "${DOTFILES_DIR}"/desktop/wallpapers/*; do
            # store a wallpaper name in the array
            wallpaper_array[i]="$(basename "${wallpaper}")"
            # increment array index
            i=$((i + 1))
        done

        # calculate the length of the array
        arr_length=$((${#wallpaper_array[@]} - 1))

        # print the wallpapers with their corresponding index
        for i in "${!wallpaper_array[@]}"; do
            printf "  %b%s%b: %s\n" "${cy}" "${i}" "${ra}" "${wallpaper_array[i]}"
        done

        # wait until the user inputs a valid wallpaper index
        valid_input=false
        while [ "${valid_input}" = false ]; do
            printf "Select a wallpaper index %b(0 - %s)%b: " "${cy}" "${arr_length}" "${ra}"

            # get the users response
            read -r response </dev/tty

            # make sure the input is numeric
            if [[ "${response}" =~ ^[0-9]+$ ]]; then
                # the input is numeric so we can safely compare
                if [[ "${response}" -le ${arr_length} && "${response}" -ge 0 ]]; then
                    # the user selected a valid index
                    valid_input=true
                    SELECTED_WALLPAPER="${wallpaper_array[response]}"
                fi
            fi
        done
    }

    setup_macos_defaults() {
        REQ_SYS_RESTART=true
        # close any open System Preferences panes, to prevent them from
        # overriding settings we’re about to change
        osascript -e 'tell application "System Preferences" to quit'
        # save to disk (not to iCloud) by default
        defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
        # automatically quit printer app once the print jobs complete
        defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
        # enable auto-hide
        defaults write com.apple.dock autohide -bool "true"
        # change the dock size
        defaults write com.apple.dock tilesize -int "36"
        # change hide / show animation speed
        defaults write com.apple.dock autohide-time-modifier -float "0.45"
        # don't show recent apps
        defaults write com.apple.dock show-recents -bool "false"
        # change the animation to scale
        defaults write com.apple.dock mineffect -string "scale"
        # only show active apps
        defaults write com.apple.dock static-only -bool "true"
        # speed up Mission Control animations
        defaults write com.apple.dock expose-animation-duration -float 0.1
        # enable grouping of applications in Mission Control
        defaults write com.apple.dock expose-group-apps -bool "true"
        # don't show indicator lights for open applications in the dock
        defaults write com.apple.dock show-process-indicators -bool false
        # disable all hot corners
        # top left screen corner -> do nothing
        defaults write com.apple.dock wvous-tl-corner -int 1
        defaults write com.apple.dock wvous-tl-modifier -int 0
        # top right screen corner -> do nothing
        defaults write com.apple.dock wvous-tr-corner -int 1
        defaults write com.apple.dock wvous-tr-modifier -int 0
        # bottom left screen corner -> do nothing
        defaults write com.apple.dock wvous-bl-corner -int 1
        defaults write com.apple.dock wvous-bl-modifier -int 0
        # bottom right screen corner -> do nothing
        defaults write com.apple.dock wvous-br-corner -int 1
        defaults write com.apple.dock wvous-br-modifier -int 0
        # show file extensions
        defaults write NSGlobalDomain AppleShowAllExtensions -bool "true"
        # show the file path bar
        defaults write com.apple.finder ShowPathbar -bool "true"
        # show status bar
        defaults write com.apple.finder ShowStatusBar -bool "true"
        # hide external disks / servers from showing on desktop
        defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool "false"
        defaults write com.apple.finder ShowHardDrivesOnDesktop -bool "false"
        defaults write com.apple.finder ShowMountedServersOnDesktop -bool "false"
        defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool "false"
        # set the file view to column
        defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
        # empty bin after 30 days
        defaults write com.apple.finder FXRemoveOldTrashItems -bool "true"
        # disable the warning before emptying the trash
        defaults write com.apple.finder WarnOnEmptyTrash -bool false
        # avoid creating .DS_Store files on network or USB volumes
        defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
        defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
        # shorten the delay for spring loading
        defaults write NSGlobalDomain com.apple.springing.delay -float 0.15
        # keep folders on top when sorting by name
        defaults write com.apple.finder _FXSortFoldersFirst -bool true
        # when performing a search, search the current folder by default
        defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
        # show the ~/Library folder in finder
        sudo chflags nohidden ~/Library
        # show the /Volumes folder in finder
        sudo chflags nohidden /Volumes
        # set flashing date time separators
        defaults write com.apple.menuextra.clock FlashDateSeparators -bool "true"
        # set movement speed
        defaults write NSGlobalDomain com.apple.mouse.scaling -float "3"
        # disable click to show desktop
        defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool "false"
        # enable tap to click for this user and for the login screen
        defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
        defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
        defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
        # enable full keyboard access for all controls (tab selection)
        defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
        # keyboard repeat
        defaults write NSGlobalDomain KeyRepeat -int 1
        defaults write NSGlobalDomain InitialKeyRepeat -int 10
        # require password immediately after sleep or screen saver begins
        defaults write com.apple.screensaver askForPassword -int 1
        defaults write com.apple.screensaver askForPasswordDelay -int 0
        # enable subpixel font rendering on non-Apple LCDs
        defaults write NSGlobalDomain AppleFontSmoothing -int 1
        # enable HiDPI display modes
        sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true
        # save screenshots to ~/Pictures/screen-captures
        mkdir -p "${HOME}/Pictures/screen-captures"
        defaults write com.apple.screencapture location -string "${HOME}/Pictures/screen-captures"
        # save screenshots in PNG format
        defaults write com.apple.screencapture type -string "png"
        # disable automatic emoji substitution in Messages.app
        defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false
        # prevent time machine from prompting to use new hard drives as backup volume
        defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
        # enable Secure Keyboard Entry in Terminal.app
        defaults write com.apple.terminal SecureKeyboardEntry -bool true
        # disable the annoying line marks in Terminal.app
        defaults write com.apple.Terminal ShowLineMarks -int 0
    }

    setup_macos_fonts() {
        # create the users Fonts directory if it doesn't exist
        if [ ! -d "${HOME}/Library/Fonts" ]; then
            mkdir -p "${HOME}/Library/Fonts"
        fi

        # copy fonts to the user Fonts directory
        cp "${DOTFILES_DIR}"/desktop/fonts/*.ttf "${HOME}"/Library/Fonts/
    }

    # ---
    # restart system
    # ---
    restart_system() {
        print_info "Installation complete!"

        if ${REQ_SYS_RESTART} && get_confirmation "Restart your computer now"; then
            # visual countdown with milliseconds
            # start from 3000 milliseconds (3 seconds)
            for ((i = 3000; i >= 0; i -= 100)); do
                # calculate seconds and milliseconds
                seconds=$((i / 1000))
                milliseconds=$((i % 1000))

                # format to show as X.X (seconds.milliseconds)
                printf "\rRestarting in %d.%02d..." "${seconds}" "$((milliseconds / 100))"

                # sleep for 100ms (the gap between updates)
                sleep 0.10
            done
            printf "\r%-40s\n" "Goodbye!" # make sure the line is clear
            sleep 0.1                     # make sure goodbye is displayed
            # execute restart
            sudo shutdown -r now
        else
            print_error "Restart cancelled!"
            printf "Some of these changes require a system restart to take effect.\n"
        fi
    }

    # ---
    # main function
    # ---
    main() {
        # confirm installation
        if ! get_confirmation "Proceed with installation"; then
            # abort install
            print_error "Installation aborted!"
            exit 0
        fi

        # validate sudo access
        sudo -v || {
            print_error "Failed to obtain sudo access"
            exit 1
        }

        # keep sudo alive
        {
            while kill -0 $$; do
                # refresh sudo access and break out of the loop if the
                # sudo timestamp fails to refresh.
                sudo -n true || break
                sleep 30
            done
            # discard all output and run as a background process
        } &>/dev/null &

        local sudo_keep_alive_pid=$!
        # we must disown the background process so that when we kill
        # it or bash terminates it, the process won't output anything.
        disown ${sudo_keep_alive_pid}

        # ---
        # script execution order
        # ---

        # clone the repo first so that when we ask the user for confirmation
        # with other install options we can properly check and access the
        # respective files / directories.
        print_info "Cloning the dotfiles repository..."
        clone_repo &>/dev/null
        print_success "Dotfiles repository successfully cloned."

        # ask the user what optionally installation steps they would like for
        # the script to run but don't run them right away.
        local do_wallpaper_setup=false
        local do_defaults_setup=false
        local do_fonts_setup=false

        if get_confirmation "Setup macOS wallpaper"; then
            do_wallpaper_setup=true
            choose_mac_wallpaper
        fi

        if get_confirmation "Setup macOS defaults"; then
            do_defaults_setup=true
        fi

        if get_confirmation "Setup macOS fonts"; then
            do_fonts_setup=true
        fi

        # run dependency installation steps
        print_info "Setting up homebrew..."
        setup_homebrew &>/dev/null
        print_success "Homebrew setup complete!"

        print_info "Setting up dotfiles..."
        setup_dotfiles &>/dev/null
        print_success "Dotfiles setup complete!"

        print_info "Installing packages with brew..."
        install_brew_packages &>/dev/null
        print_success "Packages installed with brew!"

        print_info "Installing tools with mise..."
        install_mise_tools &>/dev/null
        print_success "Tools installed with mise!"

        # run optional installation steps
        ${do_wallpaper_setup} && {
            print_info "Setting up macOS wallpaper..."
            set_mac_wallpaper &>/dev/null
            print_success "Wallpaper setup complete!"
        }
        ${do_defaults_setup} && {
            print_info "Setting up macOS defaults..."
            setup_macos_defaults &>/dev/null
            print_success "Defaults setup complete!"
        }
        ${do_fonts_setup} && {
            print_info "Setting up macOS fonts..."
            setup_macos_fonts &>/dev/null
            print_success "Fonts setup complete!"
        }

        # clean up sudo keep alive. This background process will be terminated
        # when it notices the script is no longer running but this is here to
        # explicitly kill the process as we know the script is done running.
        kill ${sudo_keep_alive_pid} 2>/dev/null

        restart_system
    }

    # run the main function
    main

} # this ensures the entire script is downloaded before execution #
