#!/usr/bin/env bash

# Any subsequent commands which fail will cause the shell script to exit immediately
set -euo pipefail

# When the script exits or errors out, make sure to do the cleanup
trap cleanup EXIT

# platform should be one of "linux" or "darwin"
declare platform="$1"
declare GN_EXTRA_ARGS="cc_wrapper=\"${PWD}/electron/external_binaries/sccache\""

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
  # We should be in src directory
  if [[ ! -d "electron" ]]
  then
    echo "Not in the right directory: $PWD, expected to be in src"
    exit 1
  fi
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

  echo "Running gn checks"
  gn gen out/Debug --args="import(\"//electron/build/args/debug.gn\") $GN_EXTRA_ARGS"
  gn check out/Debug //electron:electron_lib
  gn check out/Debug //electron:electron_app
  gn check out/Debug //electron:manifests
  gn check out/Debug //electron/shell/common/api:mojo

  echo "Starting ninja build"
  ninja -C out/Debug electron:electron_app

  gn gen out/ffmpeg "--args=import(\"//electron/build/args/ffmpeg.gn\") $GN_EXTRA_ARGS"

  ninja -C out/ffmpeg electron:electron_ffmpeg_zip
  ninja -C out/Debug electron:electron_dist_zip
  ninja -C out/Debug electron:electron_mksnapshot_zip
  ninja -C out/Debug electron:electron_chromedriver_zip

  echo "Uploading artifacts"
  buildkite-agent artifact upload out/Debug/dist.zip
  buildkite-agent artifact upload out/Debug/chromedriver.zip
  buildkite-agent artifact upload out/ffmpeg/ffmpeg.zip
  buildkite-agent artifact upload out/Debug/mksnapshot.zip

  # # Need to generate the ts definitions only once
  # # so doing it on the Linux platform which packages fastest
  # if [[ "$platform" == "linux" ]]
  # then
  #   echo "Generating Typescript definitions"
  #   npm run create-typescript-definitions
  #   # buildkite-agent artifact upload "out/electron.d.ts"
  # fi

  # echo "Uploading artifacts to GitHub"
  # python ./script/upload.py

  # echo "Uploading the shasum files"
  # # Going inside the directory to avoid saving the files along with the directory name.
  # # Instead of saving as 'dist/*.sha256sum' (mac/linux) or 'dist\*.sha256sum' (windows),
  # # it would always save it as '*.sha256sum
  # cd dist
  # buildkite-agent artifact upload "*.sha256sum"
  # cd ../
}

main() {
  sanity
  start_xvfb

  buildAndUpload "x64"
}

main
