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
  npm run clean
}

start_xvfb() {
  # Start Xvfb only for linux platform
  if [[ "$platform" != "linux" ]]
  then
    return;
  fi

  echo "Starting Xvfb"
  export DISPLAY=:99

  # This step might fail since Xvfb might not be running
  pkill Xvfb || true
  Xvfb :99 -ac &
}

buildAndUpload() {
  local arch="$1"

  echo "Building for $platform $arch"

  echo "Running cleanup"
  npm run clean

  echo "Running bootstrap command"
  python script/bootstrap.py --target_arch="$arch"

  echo "Building electron in release mode"
  python script/build.py -c R

  echo "Creating the distribution"
  python ./script/create-dist.py

  # Need to generate the ts definitions only once
  # so doing it on the Linux platform which packages fastest
  if [[ "$platform" == "linux" ]]
  then
    echo "Generating Typescript definitions"
    npm run create-typescript-definitions
    # buildkite-agent artifact upload "out/electron.d.ts"
  fi
  echo "Uploading the shasum files"
  # Going inside the directory to avoid saving the files along with the directory name.
  # Instead of saving as 'dist/*.sha256sum' (mac/linux) or 'dist\*.sha256sum' (windows),
  # it would always save it as '*.sha256sum
  cd dist
  buildkite-agent artifact upload "*.sha256sum"
  cd ../
}

main() {
  start_xvfb

  buildAndUpload "x64"
}

main
