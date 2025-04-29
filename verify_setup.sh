#!/usr/bin/env bash

# verify setup.sh SHA256 hash against the one on github
#
# -- lukejans verify_setup.sh

# create a temporary file
SETUP_SCRIPT=$(mktemp)

# download the script
echo "Downloading setup script..."
curl -fsSL https://raw.githubusercontent.com/lukejans/dotfiles/main/setup.sh -o "$SETUP_SCRIPT"

# get the SHA256 hash of the file from github
echo "Verifying file integrity..."
GITHUB_SHA=$(curl -s https://api.github.com/repos/lukejans/dotfiles/contents/setup.sh |
  grep sha | head -1 |
  sed 's/.*: "\(.*\)",/\1/' |
  xargs -I {} echo {} |
  base64 --decode |
  shasum -a 256 |
  cut -d ' ' -f1)

# calculate the hash of the downloaded file
LOCAL_SHA=$(shasum -a 256 "$SETUP_SCRIPT" | cut -d ' ' -f1)

# compare the hashes
if [ "$GITHUB_SHA" = "$LOCAL_SHA" ]; then
  # execute the setup script after verification
  echo "File integrity verified! Executing setup script..."
  echo
  bash "$SETUP_SCRIPT"
else
  echo -e "\033[1;31mERROR:\033[0m Downloaded file does not match the original on GitHub."
  echo "This could be due to a network error or tampering."
  echo -e "Download hash: \033[1;36m${LOCAL_SHA}\033[0m"
  echo -e "Expected hash: \033[1;36m${GITHUB_SHA}\033[0m"
fi

# clean up
rm "$SETUP_SCRIPT"
