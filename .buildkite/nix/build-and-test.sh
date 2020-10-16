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
  # gclient sync -f

  echo "--- Swtiching directory <pipeline>/src"
  cd ..
  
  export CHROMIUM_BUILDTOOLS_PATH="$PWD/buildtools"
  export GN_EXTRA_ARGS="cc_wrapper=\"${PWD}/electron/external_binaries/sccache\""
  export SCCACHE_BUCKET="electronjs-sccache-ci"
  export SCCACHE_TWO_TIER=true

  echo "Values"
  echo $GN_EXTRA_ARGS
  echo $CHROMIUM_BUILDTOOLS_PATH

  echo "--- Running cleanup old files"
  rm -rf out

  
  if [[ "$platform" == "darwin" ]]
  then
    echo "--- Running gn checks"
    gn gen out/Release --args="import(\"//electron/build/args/release.gn\") $GN_EXTRA_ARGS"
  else
    echo "--- Running gn checks"
    gn gen out/Release --args="import(\"//electron/build/args/release.gn\") $GN_EXTRA_ARGS"
  fi
  
  gn check out/Release //electron:electron_lib
  gn check out/Release //electron:electron_app
  gn check out/Release //electron:manifests
  gn check out/Release //electron/shell/common/api:mojo

  echo "--- Electron build"
  ninja -C out/Release electron -j 50

  if [[ "$platform" == "linux" ]]
    echo "--- Strip Electron binaries (Linux)"
  then
    electron/script/copy-debug-symbols.py --target-cpu="x64" --out-dir=out/Release/debug --compress
    electron/script/strip-binaries.py -d out/Release
    electron/script/add-debug-link.py --target-cpu="x64" --debug-dir=out/Release/debug
  fi

  echo "--- Build Electron distributed binary"
  ninja -C out/Release electron:electron_dist_zip -j 50

  if [[ "$platform" == "linux" ]]
  then
    target_os=linux
  else
    target_os=mac
  fi

  echo "--- Build chromedriver"
  ninja -C out/Release chrome/test/chromedriver -j 50
  [[ "$platform" == "linux" ]] && electron/script/strip-binaries.py --target-cpu="x64" --file $PWD/out/Release/chromedriver
  ninja -C out/Release electron:electron_chromedriver_zip -j 50

  echo "--- Build ffmpeg"
  gn gen out/ffmpeg --args="import(\"//electron/build/args/ffmpeg.gn\")"
  ninja -C out/ffmpeg electron:electron_ffmpeg_zip -j 50
  

  echo "--- Build mksnapshot"
  ninja -C out/Release electron:electron_mksnapshot -j 50

  if [[ "$platform" == "linux" ]]
  then
    electron/script/strip-binaries.py --file $PWD/out/Release/mksnapshot
    electron/script/strip-binaries.py --file $PWD/out/Release/v8_context_snapshot_generator
  fi
  ninja -C out/Release electron:electron_mksnapshot_zip -j 50
  
  if [[ "$platform" == "linux" ]]
  echo "--- Generate type declaration files [Linux]"
  then
    cd electron
    node script/yarn create-typescript-definitions
    cd ../
  fi

  echo "--- Upload artifacts"
  cd out
  buildkite-agent artifact upload Release/dist.zip 
  buildkite-agent artifact upload Release/chromedriver.zip 
  buildkite-agent artifact upload ffmpeg/ffmpeg.zip 
  buildkite-agent artifact upload Release/mksnapshot.zip 

  cd ..

  if [[ "$platform" == "linux" ]]
  then
    buildkite-agent artifact upload electron/electron-api.json 
    buildkite-agent artifact upload electron/electron.d.ts
  fi
}

main() {
  sanity
  buildAndUpload
}

main
