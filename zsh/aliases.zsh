#!/usr/bin/env zsh

# cd
alias dwn="cd ~/Downloads"
alias dsk="cd ~/Desktop"
alias pic="cd ~/Pictures"
alias pro="cd ~/Code/projects"

# ls
alias ls='ls -FG'
alias ll='ls -lFG'
alias la='ls -lAFG'
alias lsd="ll | grep --color=never '^d'"

# cat - note that bat can safely override cat as it can
#       detect when its being used non-interactively and
#       so will use the default cat like behavior.
alias cat='bat'

# grep
alias grep='grep --color=always'

# python
alias py='python3'
alias pip='pip3'

# find and delete
alias java_sweep='find . -name "*.class" -type f -delete'
alias node_sweep="find . -type d -name node_modules -prune -exec rm -rf '{}' \;"
alias ds_sweep='find . -name ".DS_Store" -type f -delete'

# because im used to neofetch
alias neofetch='fastfetch'

# macOS apple script shortcuts
alias theme="osascript -e 'tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode'"
alias stfu="osascript -e 'set volume output muted true'"
alias pumpitup="osascript -e 'set volume output volume 100'"

# quick file share mount to my Mac Mini
alias mount_impala='mount_smbfs //lukejans@impala-m1.local/lukejans ~/Servers/impala-m1'
alias umount_impala='umount ~/Servers/impala-m1'

# reload the shell
alias reload="exec ${SHELL} -l"

# ip address
alias localip="ipconfig getifaddr en0"
