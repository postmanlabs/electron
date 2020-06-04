function waitStep() {
  return {
    wait: true
  }
}

function buildStepForWindows () {
  return {
    label: ':windows: :electron: Build',
    timeout_in_minutes: 60,
    command: '.\\.buildkite\\windows\\build-and-upload-release',
    agents: [
      'os=windows',
      'queue=electron-build-v7'
    ]
  };
}

/**
 * Returns the build step for linux or darwin
 * @param {String} platform can be 'linux' or 'darwin'
 */
function buildStepForNix (platform) {
  if(!process.env.BUILDKITE_BRANCH){
    return [];
  }

  return {
    label: `:${platform}: :electron: Build`,
    timeout_in_minutes: 60,
    command: [
      'pwd',
      'cd src/electron',
      `git fetch && git checkout ${process.env.BUILDKITE_BRANCH}`,
      'gclient sync -f',
      'cd ..',
      'gn gen out/Release --args="import(\"//electron/build/args/release.gn\")"',
      'gn check out/Release //electron:electron_lib',
      'gn check out/Release //electron:electron_app',
      'gn check out/Release //electron:manifests',
      'gn check out/Release //electron/shell/common/api:mojo',
      'ninja -C out/Release electron',
      'electron/script/copy-debug-symbols.py --target-cpu="x64" --out-dir=out/Release/debug --compress',
      'electron/script/strip-binaries.py --target-cpu="x64"',
      'electron/script/add-debug-link.py --target-cpu="x64" --debug-dir=out/Release/debug',
      'electron/script/strip-binaries.py -d out/Release',
      'ninja -C out/Release electron:electron_dist_zip',
      'ninja -C out/Release chrome/test/chromedriver',
      'electron/script/strip-binaries.py --target-cpu="x64" --file $PWD/out/Release/chromedriver',
      'ninja -C out/Release electron:electron_chromedriver_zip',
      'ninja -C out/Release electron:electron_mksnapshot',
      'electron/script/strip-binaries.py --file $PWD/out/Release/mksnapshot',
      'electron/script/strip-binaries.py --file $PWD/out/Release/v8_context_snapshot_generator',
      'ninja -C out/Release electron:electron_mksnapshot_zip',
      'gn gen out/ffmpeg --args="import("//electron/build/args/ffmpeg.gn")"',
      'ninja -C out/ffmpeg electron:electron_ffmpeg_zip',
    ],
    agents: [
      `os=${platform}`,
      'queue=electron-build-v7.2'
    ]
  };
}

function testStepForWindows () {
  return {
    label: ':windows: :electron: Test',
    timeout_in_minutes: 60,
    command: '.\\.buildkite\\windows\\run-tests',
    agents: [
      'os=windows',
      'queue=electron-build-v7'
    ]
  };
}

function testStepForNix (platform) {
  return {
    label: `:${platform}: :electron: Test`,
    timeout_in_minutes: 60,
    command: [`.buildkite/nix/run-tests.sh ${platform}`],
    agents: [
      `os=${platform}`,
      'queue=electron-build'
    ]
  };
}

function generateBuildPipeline () {
  // Do not run the pipeline if a PR has not been raised yet
  // if (process.env.BUILDKITE_PULL_REQUEST === 'false') {
  //   return [];
  // }

  return [
    buildStepForWindows(),
    // buildStepForNix('linux'),
    // buildStepForNix('darwin'),
    waitStep(),
    testStepForWindows(),
    // testStepForNix('linux'),
    // testStepForNix('darwin'),
  ];
}

function startBuildPipeline () {
  const pipeline = generateBuildPipeline();

  console.log(JSON.stringify(pipeline, null, 4));
}

module.exports = {
  generateBuildPipeline,
  startBuildPipeline
};

!module.parent && startBuildPipeline();
