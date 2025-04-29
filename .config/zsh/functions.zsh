#!/usr/bin/env zsh

#  ______
# | $_   |    lukejans
# |______|  functions.zsh

# create a new directory and enter it
mkd() {
  mkdir -p "$@" && cd "$_"
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
  if [ -n "$selected_file" ]; then
    $EDITOR "$selected_file"
  fi
}

# yazi
y() {
  local tmp
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd" || exit
  fi
  rm -f -- "$tmp"
}

# git commit
gc() {
  if [ -z "$1" ]; then
    git commit
  else
    git commit -m "$1"
  fi
}

# arduino uno compile
uno_compile() {
  arduino-cli compile -v --fqbn arduino:avr:uno "$1"
}

# arduino uno upload
uno_upload() {
  arduino-cli upload -v -p /dev/cu.usbmodem2101 --fqbn arduino:avr:uno "$1"
}

# upgrade nvm
nvm_upgrade() {
  # start timer to track upgrade time
  start_time=$(date +%s)
  # official nvm manual upgrade
  (
    cd "$NVM_DIR"
    git fetch --tags origin
    git checkout "$(git describe --abbrev=0 --tags --match 'v[0-9]*' "$(git rev-list --tags --max-count=1)")"
  ) && \. "$NVM_DIR/nvm.sh"
  # end timer
  end_time=$(date +%s)
  # calculate elapsed time (seconds)
  elapsed_time=$((end_time - start_time))
  echo "Time taken to upgrade nvm: ${elapsed_time} seconds"
}

# workaround for `fast-syntax-highlighting` freezing when running `$ whatis`
# see: https://github.com/zdharma-continuum/fast-syntax-highlighting/issues/27#issuecomment-1267278072
whatis() {
  if [[ -v THEFD ]]; then
    :
  else
    command whatis "$@"
  fi
}

# find new MacOS defaults settings
# see: https://github.com/yannbertrand/macos-defaults/tree/main
defaults_diff() {
  echo -n -e "\033[1m? Insert diff name (to store it for future usage)\033[0m "
  read name
  name=${name:-default}
  echo "Saving plist files to '$(pwd)/diffs/${name}' folder."

  mkdir -p diffs/$name
  defaults read >diffs/$name/old.plist
  defaults -currentHost read >diffs/$name/host-old.plist

  echo -e "\n\033[1;33m \033[0m Change settings and press any key to continue"

  read -s -k 1
  defaults read >diffs/$name/new.plist
  defaults -currentHost read >diffs/$name/host-new.plist

  echo -e "\033[1;32m->\033[0m Here is your diff\n\n"
  git --no-pager diff --no-index diffs/$name/old.plist diffs/$name/new.plist
  echo -e '\n\n\033[1;32m->\033[0m and here with the `-currentHost` option\n\n'
  git --no-pager diff --no-index diffs/$name/host-old.plist diffs/$name/host-new.plist

  echo -e "\n\n\033[1;32m->\033[0m Commands to print the diffs again"
  echo -e "$ git --no-pager diff --no-index diffs/${name}/old.plist diffs/${name}/new.plist"
  echo -e "$ git --no-pager diff --no-index diffs/${name}/host-old.plist diffs/${name}/host-new.plist"
}
