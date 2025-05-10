#!/usr/bin/env zsh

#  ______
# | $_   |   lukejans
# |______|  aliases.zsh

# cd
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias pp="cd ~/Code/projects/personal"

# ls
alias ls='ls -FG'
alias ll='ls -lFG'
alias la='ls -lAFG'
alias lsd="ll | grep --color=never '^d'"

# git
alias gs='git status'
alias gp='git pull'
alias ga='git add .'

# cat - note that bat can safely override cat as it can
#       detect when its being used non-interactively and
#       so will use the default cat like behavior.
alias cat='bat'

# grep
alias grep='grep --color=always'

# python
alias py='python3'
alias pip='pip3'

# java
alias jinfo='echo -e "Java Binary Path: $(readlink -f "$(jenv which java)")\nJAVA_HOME: $JAVA_HOME"'
alias jsweep='find . -name "*.class" -type f -exec trash {} \;'

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
