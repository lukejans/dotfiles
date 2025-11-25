#!/usr/bin/env zsh

# cd
alias dwn="cd ~/Downloads"
alias dsk="cd ~/Desktop"
alias pic="cd ~/Pictures"
alias pro="cd ~/Code/projects"

# ls
alias ls='eza --classify'
alias ll='ls --long --group --links --mounts --binary --modified --time-style="+%Y-%m-%d %H:%M" --git --git-repos'
alias lldu='ll --total-size'
alias la='ll --all'
alias ladu='la --total-size'
alias llt='ll --tree --ignore-glob "node_modules"'
alias lltdu='llt --total-size'
alias lat='llt --all --ignore-glob "node_modules|.git"'
alias ltd='ls --tree --only-dirs --ignore-glob "node_modules"'
alias lltd='ll --tree --only-dirs --ignore-glob "node_modules"'
alias lltddu='lltd --total-size'
alias latd='ltd --all --ignore-glob "node_modules|.git"'
alias latddu='latd --total-size'

# cat - note that bat can safely override cat as it can
#       detect when its being used non-interactively and
#       so will use the default cat like behavior.
alias cat='bat'

# trash - my saving grace
alias rm='trash'

# grep
alias grep='grep --color=always'

# python
alias py='python3'
alias pip='pip3'

# find and delete
alias java_sweep='find . -name "*.class" -type f -delete'
alias node_sweep="find . -type d -name node_modules -prune -exec rm -rf '{}' \;"
alias ds_sweep='find . -name ".DS_Store" -type f -delete'

# macOS apple script shortcuts
alias theme="osascript -e 'tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode'"
alias stfu="osascript -e 'set volume output muted true'"
alias pumpitup="osascript -e 'set volume output volume 100'"

# ip address
alias localip="ipconfig getifaddr en0"

# misc
alias leetcode='leetgo'
