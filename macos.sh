#!/usr/bin/env bash

#         .:'
#     __ :'__
#  .'`__`-'__``.
# :__________.-'      lukejans
# :_________:     macos.sh defaults
#  :_________`-;
#   `.__.-.__.'

# close any open System Preferences panes, to prevent them from
# overriding settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# --- general
# save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
# automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# --- dock
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

# --- finder
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
# show the ~/Library folder
sudo chflags nohidden ~/Library
# show the /Volumes folder
sudo chflags nohidden /Volumes

# --- menubar
# set flashing date time separators
defaults write com.apple.menuextra.clock FlashDateSeparators -bool "true"

# --- mouse
# set movement speed
defaults write NSGlobalDomain com.apple.mouse.scaling -float "3"
# disable click to show desktop
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool "false"

# --- trackpad
# enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# --- keyboard
# enable full keyboard access for all controls (tab selection)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
# keyboard repeat
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# --- screen
# set wallpaper to mac-bg1.jpg
sudo osascript -e "tell application \"System Events\" to set picture of every desktop to POSIX file \"${HOME}/.dotfiles/desktop-assets/images/mac-bg1.jpg\""
# require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0
# enable subpixel font rendering on non-Apple LCDs
# reference: https://github.com/kevinSuttle/macOS-Defaults/issues/17#issuecomment-266633501
defaults write NSGlobalDomain AppleFontSmoothing -int 1
# enable HiDPI display modes
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true
# save screenshots to ~/Pictures
mkdir -p "${HOME}/Pictures/screen-captures"
defaults write com.apple.screencapture location -string "${HOME}/Pictures"
# save screenshots in PNG format
defaults write com.apple.screencapture type -string "png"

# --- messages
# disable automatic emoji substitution
defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false

# --- time machine
# prevent time machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# --- terminal
# enable Secure Keyboard Entry in Terminal.app
# see: https://security.stackexchange.com/a/47786/8918
defaults write com.apple.terminal SecureKeyboardEntry -bool true
# disable the annoying line marks
defaults write com.apple.Terminal ShowLineMarks -int 0
