#!/usr/bin/env zsh

# create a new directory and enter it
mkcd() {
    mkdir -p -- "${@}" && cd "${@: -1}"
}

# fzf preview
fz() {
    fzf --style full \
        --border --padding 1,2 \
        --border-label ' Fzf Search ' \
        --input-label ' Input ' \
        --header-label ' File Type ' \
        --preview 'fzf-preview.sh {}' \
        --preview-window 'right,70%,wrap' \
        --bind 'result:transform-list-label:
            if [[ -z $FZF_QUERY ]]; then
              echo " $FZF_MATCH_COUNT items "
            else
              echo " $FZF_MATCH_COUNT matches for [$FZF_QUERY] "
            fi
            ' \
        --bind 'focus:transform-preview-label:[[ -n {} ]] && printf " Previewing [%s] " {}' \
        --bind 'focus:+transform-header:file --brief {} || echo "No file selected"' \
        --bind 'ctrl-r:change-list-label( Reloading the list )+reload(sleep 2; git ls-files)' \
        --color 'border:#aaaaaa,label:#cccccc' \
        --color 'preview-border:#9999cc,preview-label:#ccccff' \
        --color 'list-border:#669966,list-label:#99cc99' \
        --color 'input-border:#996666,input-label:#ffcccc' \
        --color 'header-border:#6699cc,header-label:#99ccff'
}

# fzf preview and open a selected file in $EDITOR
fzo() {
    local selected_file
    selected_file=$(fz)
    if [ -n "${selected_file}" ]; then
        ${EDITOR-nano} "${selected_file}"
    fi
}

# yazi
y() {
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "${@}" --cwd-file="${tmp}"
    if cwd="$(command cat -- "${tmp}")" && [ -n "${cwd}" ] && [ "${cwd}" != "${PWD}" ]; then
        builtin cd -- "${cwd}" || exit
    fi
    rm -f -- "${tmp}"
}

# arduino uno compile
uno_compile() {
    arduino-cli compile -v --fqbn arduino:avr:uno "${1}"
}

# arduino uno upload
uno_upload() {
    arduino-cli upload -v -p /dev/cu.usbmodem2101 --fqbn arduino:avr:uno "${1}"
}
