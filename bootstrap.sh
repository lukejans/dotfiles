#!/usr/bin/env bash

# MacOS Setup Script
#
# description: this script sets up a MacOS development environment by
#              installing software and tools listed in the Brewfile,
#              configuring system default settings, and linking dotfiles.
#
# author: luke janssen
# date: july 1st, 2025

{ # this ensures the entire script is downloaded before execution #

    # ---
    # exports
    # ---
    export XDG_CONFIG_HOME="${HOME}/.config"

    # ---
    # script globals
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

    # ---
    # helper functions
    # ---

    # brew command wrapper
    #
    # ensures that brew does not reset the sudo time stamp. Homebrew resets
    # sudo timestamps on every brew command to prevent privilege escalation
    # attacks. However this makes brew really annoying in shell scripts that
    # require sudo for the duration of their execution. This is explained in
    # detail with issue linked below. Sadly this solution breaks all output.
    #
    # - https://github.com/Homebrew/brew/issues/17912
    # - https://stackoverflow.com/questions/1401002/how-to-trick-an-application-into-thinking-its-stdout-is-a-terminal-not-a-pipe
    brew() {
        script -q /dev/null "$(command -v brew)" "$@" | col -b | tr -d '\000-\037\177'
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

        # print information about the backup process to stderr. I know this
        # doesn't semantically make sense, but it's the only way I could figure
        # out how to easily separate output.
        printf "Backed up %b'%s'%b to %b'%s'%b.\n" "${cy}" "${name}" "${ra}" "${cy}" "${backup}" "${ra}" >&2

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
        if ! type -P brew &>/dev/null; then
            # the homebrew install command
            printf "Homebrew not found... Installing homebrew.\n"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            # make sure the brew command is available
            eval "$(/opt/homebrew/bin/brew shellenv)" || return 1
        else
            printf "Homebrew installation found\n"
            printf "Running %bbrew%b %bupdate%b, %bcleanup%b and %bautoremove%b\n" "${cg}" "${ra}" "${cy}" "${ra}" "${cy}" "${ra}" "${cy}" "${ra}"
            # brew is installed so make sure it's up to date
            {
                brew update
                brew cleanup --prune=all
                brew autoremove
            } &>/dev/null
        fi

        # turn homebrew analytics off
        brew analytics off &>/dev/null

        # make sure we don't get "zsh compinit: insecure directories” warnings
        chmod -R go-w "$(brew --prefix)/share"
    }

    install_brew_packages() {
        # check if the full xcode toolchain was already installed. This is
        # just looking to see if metal is installed which is only installed
        # with the ide and not with the command line tools. This is here
        # because we must agree to the license on a fresh install.
        local agree_to_license=false
        if ! xcrun --find metal &>/dev/null; then
            # metal was not found so we will have to agree to the xcode ide
            # license after homebrew installs it.
            agree_to_license=true
        fi

        # install / update all brew packages
        brew bundle install --global &>/dev/null

        # agree to the xcode license after it's installed
        if ${agree_to_license}; then
            sudo xcodebuild -license accept
        fi
    }

    # ---
    # clone and symlink configuration files
    # ---
    clone_repo() {
        # if git is not installed, install it so we can clone the dotfiles repo
        if ! type -P git &>/dev/null; then
            brew install git &>/dev/null
        fi

        # check if the .dotfiles directory exists already then create a backup
        if [[ -d "${DOTFILES_DIR}" ]]; then
            # backup any existing directory with the same name at the same location
            # before cloning the repo.
            DOTFILES_BACKUP_DIR=$(backup "${DOTFILES_DIR}")
        fi

        # clone the repo
        git clone "${REPO_URL}" "${DOTFILES_DIR}" || return 1
    }

    setup_dotfiles() {
        # if the DOTFILES_BACKUP_DIR variable is set and has a value then attempt
        # to backup files listed under the "# ----<sync>----" header in .gitignore.
        if [[ -n "${DOTFILES_BACKUP_DIR:-}" ]]; then
            # the repos gitignore file
            local gitignore_file="${HOME}/.dotfiles/.gitignore"

            # get the line number of the `# ----<sync>----` header
            line_num=$(grep -n "^# ----<sync>----" "${gitignore_file}" | cut -d ":" -f 1)

            # loop over the files / directories present in that section to copy
            for item in $(tail -n +$((line_num + 1)) "${gitignore_file}"); do

                local source="${DOTFILES_BACKUP_DIR}/${item}"
                local dest="${DOTFILES_DIR}/${item}"

                if [ -e "${source}" ]; then
                    # make sure the parent directory is present before copying
                    mkdir -p "$(dirname "${dest}")"
                    rsync -a "${source}" "$(dirname "${dest}")/"
                    printf "Copied %b'%s'%b to the new clone\n" "${cc}" "${item}" "${ra}"
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
            item="$(basename "${item_src}")"
            item_dest="${HOME}/${item}"

            # if the destination file already exists, create a backup
            if [[ -e "${item_dest}" ]]; then
                # if the destination is a symlink just remove the link
                if [[ -L "${item_dest}" ]]; then
                    rm "${item_dest}"
                else
                    # the file is not a symlink so make a backup
                    backup "${item_dest}" >/dev/null # discard only stdout
                fi
            fi

            # link the source item
            ln -sfF "${item_src}" "${item_dest}"
            printf "linked %b'%s'%b to %b\$HOME%b\n" "${cc}" "${item}" "${ra}" "${cr}" "${ra}"
        done
    }

    # ---
    # mise toolchain setup
    #
    # https://mise.jdx.dev/
    # ---
    install_mise_tools() {
        # install all packages if system dependencies are not up to date
        (
            cd "${HOME}" || return 1

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
    # macOS Defaults
    #
    # https://macos-defaults.com/
    # ---
    setup_macos_defaults() {
        REQ_SYS_RESTART=true
        # ensure system settings is closed so these changes get applied
        osascript -e 'tell application "System Preferences" to quit'

        # dock defaults:
        # enable auto-hide
        defaults write com.apple.dock autohide -bool "true"
        # change the dock size
        defaults write com.apple.dock tilesize -int "36"
        # change hide / show animation speed
        defaults write com.apple.dock autohide-time-modifier -float "0.35"
        # turn off auto hide delay
        defaults write com.apple.dock "autohide-delay" -float "0"
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
        # disable hot corners
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
        # restart Dock
        killall Dock

        # finder defaults:
        # show file path bar
        defaults write com.apple.finder ShowPathbar -bool "true"
        # show status bar
        defaults write com.apple.finder ShowStatusBar -bool "true"
        # set the file view to column
        defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
        # keep folders on top when sorting by name
        defaults write com.apple.finder _FXSortFoldersFirst -bool true
        # when performing a search, search the current folder by default
        defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
        # save to disk by default (not to iCloud)
        defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool "false"

        # desktop defaults (finder):
        defaults write com.apple.finder "_FXSortFoldersFirstOnDesktop" -bool "true"
        # don't show hard disks
        defaults write com.apple.finder "ShowHardDrivesOnDesktop" -bool "false"
        # avoid creating .DS_Store files on network or USB volumes
        defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
        defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
        # restart Finder
        killall Finder

        # menubar defaults:
        # set flashing date time separators
        defaults write com.apple.menuextra.clock "FlashDateSeparators" -bool "true"
        # restart system ui server
        killall SystemUIServer

        # mouse defaults:
        # set tracking speed
        defaults write NSGlobalDomain com.apple.mouse.scaling -float "3"
        # set movement speed
        defaults write NSGlobalDomain com.apple.mouse.scaling -float "3"

        # trackpad defaults:
        # enable tap to click for this user and for the login screen
        defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
        defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
        defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

        # keyboard defaults:
        # keyboard repeat
        defaults write NSGlobalDomain KeyRepeat -int 1
        defaults write NSGlobalDomain InitialKeyRepeat -int 10

        # require password immediately after sleep or screen saver begins
        defaults write com.apple.screensaver askForPassword -int 1
        defaults write com.apple.screensaver askForPasswordDelay -int 0

        # time machine defaults:
        # prevent time machine from prompting to use new hard drives as backup volume
        defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

        # terminal defaults:
        # enable secure keyboard entry
        defaults write com.apple.terminal SecureKeyboardEntry -bool true
        # disable the annoying line marks in Terminal.app
        defaults write com.apple.Terminal ShowLineMarks -int 0
    }

    # ---
    # restart system
    # ---
    restart_system() {
        print_info "Installation complete!"

        if ${REQ_SYS_RESTART}; then
            # if a system restart is required, ask for confirmation before restarting
            if get_confirmation "Restart your computer now"; then
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
        fi
    }

    # ---
    # main function
    # ---
    main() {
        # print install banner
        printf "\n%b         .:'%b\n" "${cg}" "${ra}"
        printf "%b     __ :'__%b\n" "${cg}" "${ra}"
        printf "%b  .'\`__\`-'__\`\`.%b  Running: \"bootstrap.sh\"\n" "${cy}" "${ra}"
        printf "%b :__________.-'%b  Requirements:\n" "${cr}" "${ra}"
        printf "%b :_________:%b        - signed into an Apple ID\n" "${cm}" "${ra}"
        printf "%b  :_________\`-;%b     - sudo privileges\n" "${cm}" "${ra}"
        printf "%b   \`.__.-.__.'%b\n\n" "${cb}" "${ra}"

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

        # ask the user what optionally installation steps they would like for
        # the script to run but don't run them right away.
        local do_defaults_setup=false

        if get_confirmation "Setup macOS defaults"; then
            do_defaults_setup=true
        fi

        # run dependency installation steps
        print_info "Setting up homebrew..."
        if setup_homebrew; then
            print_success "Homebrew setup complete!"
        else
            print_error "Homebrew setup failed!"
            exit 1
        fi

        # clone the repo once git is available
        print_info "Cloning the dotfiles repository..."
        if clone_repo; then
            print_success "Repository successfully cloned."
        else
            print_error "Failed to clone dotfiles repository."
            exit 1
        fi

        print_info "Setting up dotfiles..."
        if setup_dotfiles; then
            print_success "Dotfiles setup complete!"
        else
            print_error "Dotfiles setup failed!"
            exit 1
        fi

        print_info "Installing packages with brew..."
        if install_brew_packages; then
            print_success "Packages installed with brew!"
        else
            print_error "Packages installation failed!"
            exit 1
        fi

        print_info "Installing tools with mise..."
        if install_mise_tools; then
            print_success "Tools installed with mise!"
        else
            print_error "Tools installation failed!"
            exit 1
        fi

        # run optional installation steps
        ${do_defaults_setup} && {
            print_info "Setting up macOS defaults..."
            setup_macos_defaults
            print_success "Defaults setup complete!"
        }

        # clean up sudo keep alive. This background process will be terminated
        # when it notices the script is no longer running but this is here to
        # explicitly kill the process as we know the script is done running.
        kill ${sudo_keep_alive_pid}

        restart_system
    }

    # run the main function
    main

} # this ensures the entire script is downloaded before execution #
