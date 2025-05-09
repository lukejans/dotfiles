#!/usr/bin/env zsh

git_prompt_info() {
    # check if the current dir is a git repository
    git rev-parse --is-inside-work-tree &>/dev/null || return

    local branch=""
    local git_info=""

    # get current branch name
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    # get git status
    local git_status=$(git status --porcelain 2>/dev/null)

    # start building the git info string
    git_info="$branch"

    # Add status icon indicators
    #   [+]- staged files ready to commit
    #   [~]- modified files (uncommitted changes)
    #   [?]- untracked files
    #   [$]- stashes present
    #   [↑]- commits ahead of remote
    #   [↓]- commits behind remote
    local status_indicators=""

    # check for staged files
    if echo "$git_status" | grep -q "^[MADRC]"; then
        status_indicators+="+"
    fi

    # check for modified files
    if echo "$git_status" | grep -q "^.[MD]"; then
        status_indicators+="~"
    fi

    # check for untracked files
    if echo "$git_status" | grep -q "^??"; then
        status_indicators+="?"
    fi

    # check for stashes
    if [[ $(git stash list 2>/dev/null | wc -l | tr -d ' ') -gt 0 ]]; then
        status_indicators+="\$"
    fi

    # check how many commits ahead or behind the local branch is
    # from it's remote branch and update the status indicator
    local upstream_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    if [[ -n "$upstream_branch" ]]; then
        local counts=$(git rev-list --left-right --count HEAD...@{u} 2>/dev/null)
        local ahead_count=$(echo "$counts" | cut -f1)
        local behind_count=$(echo "$counts" | cut -f2)

        if [[ $ahead_count -gt 0 ]]; then
            status_indicators+="↑"
        fi

        if [[ $behind_count -gt 0 ]]; then
            status_indicators+="↓"
        fi
    fi

    # add status indicators
    if [[ -n "$status_indicators" ]]; then
        git_info+="[$status_indicators]"
    fi
    echo ":($git_info)"
}
