#!/usr/bin/env zsh

# create a new directory and enter it
mkcd() {
    mkdir -p -- "${@}" && cd "${@: -1}"
}

# fzf preview and open a selected file in $EDITOR
fzo() {
    local selected_file
    selected_file=$(fzf)
    if [ -n "${selected_file}" ]; then
        if [ -n "${SSH_CLIENT}" ] || [ -n "${SSH_TTY}" ]; then
            ${GIT_EDITOR-nano} "${selected_file}"
        else
            ${EDITOR-nano} "${selected_file}"
        fi
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
