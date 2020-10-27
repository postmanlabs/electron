#!/usr/bin/env bash

# Any subsequent commands which fail will cause the shell script to exit immediately
set -euo pipefail

# When the script exits or errors out, make sure to do the cleanup
trap cleanup EXIT

# platform should be one of "linux" or "darwin"
declare platform="$1"

cleanup() {
  echo "running cleanup"
  # Try stopping Xvfb only for Linux platform
  if [[ "$platform" == "linux" ]]
  then
    # This step might fail since Xvfb might not be running
    pkill Xvfb || true
  fi
}

sanity() {
  if [[ ! -d "src/electron" ]]
  then
    echo "Not in the right directory: $PWD, expected to src/electron to exist"
    exit 1
  fi
}

buildAndUpload() {
  echo "Building for $platform x64"
  pwd
  echo "--- Swtiching directory <pipeline>/src/electron"
  cd src/electron

  echo "Cleaning .git files before running gclient sync"

  # Removing these two files help us to remove the changes made by builds which 
  # failed/terminated/exits before completion of the builds steps. 
  cd ..
  rm -rf .git/rebase-apply
  rm -rf third_party/electron_node/.git/rebase-apply
  cd electron
  
  echo "--- Removing and adding origin"
  git remote remove origin
  git remote add origin https://github.com/postmanlabs/electron
  
  echo "--- Setting upstream branch"
  git fetch
  git checkout $BUILDKITE_BRANCH
  git branch --set-upstream-to origin/$BUILDKITE_BRANCH

  echo "git reset --hard origin"
  git reset --hard origin/$BUILDKITE_BRANCH
  
  echo "--- Running gclient sync step"
  gclient sync -f

  echo "--- Swtiching directory <pipeline>/src"
  cd ..
  
  export CHROMIUM_BUILDTOOLS_PATH="$PWD/buildtools"
  export GN_EXTRA_ARGS="cc_wrapper=\"${PWD}/electron/external_binaries/sccache\""
  export SCCACHE_BUCKET="electronjs-sccache-ci"
  export SCCACHE_TWO_TIER=true

  echo "--- Running cleanup old files"
  rm -rf out

  echo "--- Running gn checks"
  gn gen out/Testing --args="import(\"//electron/build/args/testing.gn\") $GN_EXTRA_ARGS"

  echo "--- Electron build"
  ninja -C out/Testing electron -j 10

  echo "--- Electron testing bianries"
  ninja -C out/Testing third_party/electron_node:headers

  echo "--- Electron shell_browser_ui_unittests bianry"
  ninja -C out/Testing shell_browser_ui_unittests

  echo "--- Switch to directory <pipeline>/src/electron"
  cd electron

  echo "--- Running unit test"
  xvfb-run --auto-servernum --server-args='-screen 0, 1280x1024x24' node ./script/spec-runner.js

  cd ..
}

main() {
  sanity
  buildAndUpload
}

main
