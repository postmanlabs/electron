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

download_and_extract_artifact() {
  echo "Downloading and extracting the artifact D-$platform.zip"
  buildkite-agent artifact download "out/D-$platform.zip" .
  unzip -o "out/D-$platform.zip"
}

run_tests() {
  echo "Running lint"
  npm run lint

  echo "Running tests"
  python script/test.py --ci --rebuild_native_modules
  python script/verify-ffmpeg.py
}

main() {
  start_xvfb

  echo "Cleaning up"
  npm run clean-build

  download_and_extract_artifact

  echo "Bootstrapping"
  python script/bootstrap.py --dev

  run_tests
}

main
