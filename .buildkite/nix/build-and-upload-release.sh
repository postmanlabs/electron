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
  echo "Building for $platform x64"

  echo "--- Running gn checks"
  gn gen out/Release --args="import(\"//electron/build/args/release.gn\") $GN_EXTRA_ARGS"
  gn check out/Release //electron:electron_lib
  gn check out/Release //electron:electron_app
  gn check out/Release //electron:manifests
  gn check out/Release //electron/shell/common/api:mojo

  echo "--- Electron build"
  ninja -C out/Release electron

  echo "--- Strip Electron binaries (Linux)"
  if [[ "$platform" == "linux" ]]
  then
    electron/script/copy-debug-symbols.py --target-cpu="x64" --out-dir=out/Release/debug --compress
    electron/script/strip-binaries.py --target-cpu="x64"
    electron/script/add-debug-link.py --target-cpu="x64" --debug-dir=out/Release/debug
  fi

  echo "--- Electron build dist"
  ninja -C out/Release electron:electron_dist_zip
  if [[ "$platform" == "linux" ]]
    target_os=linux
  else
    target_os=mac
  fi
  electron/script/zip_manifests/check-zip-manifest.py out/Release/dist.zip electron/script/zip_manifests/dist_zip.$target_os.x64.manifest
  # check size here
  buildkite-agent artifact upload out/Release/dist.zip

  echo "--- Build chromedriver.zip"
  ninja -C out/Release chrome/test/chromedriver
  [[ "$platform" == "linux" ]] && electron/script/strip-binaries.py --target-cpu="x64" --file $PWD/out/Release/chromedriver
  ninja -C out/Release electron:electron_chromedriver_zip
  buildkite-agent artifact upload out/Release/chromedriver.zip

  echo "--- Build Node.js headers"
  ninja -C out/Release third_party/electron_node:headers
  zip -ryq out/Release/node_headers.zip out/Release/gen/node_headers
  buildkite-agent artifact upload out/Release/node_headers.zip

  echo "--- Publish Electron Dist"
  # Upload to GitHub release
  # script/release/uploaders/upload.py

  echo "--- ffmpeg GN gen"
  gn gen out/ffmpeg --args="import(\"//electron/build/args/ffmpeg.gn\") $GN_EXTRA_ARGS"
  ninja -C out/ffmpeg electron:electron_ffmpeg_zip
  buildkite-agent artifact upload out/ffmpeg/ffmpeg.zip

  echo "--- mksnapshot build"
  ninja -C out/Release electron:electron_mksnapshot
  if [[ "$platform" == "linux" ]]
  then
    electron/script/strip-binaries.py --file $PWD/out/Release/clang_x64_v8_arm64/mksnapshot
  fi
  ninja -C out/Release electron:electron_mksnapshot_zip
  buildkite-agent artifact upload out/Release/mksnapshot.zip

  echo "--- Generate breakpad symbols"
  ninja -C out/Release electron:electron_symbols

  echo "--- zip symbols"
  electron/script/zip-symbols.py -b "$PWD/out/Release"

  echo "--- Generate type declarationsp (Linux)"
  if [[ "$platform" == "linux" ]]
  then
    cd electron
    node script/yarn create-typescript-definitions
    cd ../
  fi

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

  buildAndUpload
}

main
