#!/usr/bin/env bash

# Any subsequent commands which fail will cause the shell script to exit immediately
set -euo pipefail

# When the script exits or errors out, make sure to do the cleanup
trap cleanup EXIT

cleanup() {
  echo "Clean up directory"
  rm -rf dist/
}

sanity() {
  if [[ ! -d "src/electron" ]]
  then
    echo "Not in the right directory: $PWD, expected to src/electron to exist"
    exit 1
  fi
}

upload_SHA_file_and_release() {
  echo "--- Switching directory src/electron"
  cd src/electron

  echo "--- npm i"
  npm i

  echo "--- Creating directory dist"
  mkdir dist || true

  echo "--- Downloading SHA files"
  buildkite-agent artifact download "*.sha256sum" dist/

  echo "Releasing"
  node script/release/release.js --skipVersionCheck

  echo "Removed unsaved changes"
  git stash save --keep-index --include-untracked
  git stash drop
}

main() {
  sanity
  
  echo "Upload SHA file"
  upload_SHA_file_and_release
}

main
