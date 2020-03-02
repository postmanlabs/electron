function waitStep() {
  return {
    wait: true
  }
}

function buildStepForWindows () {
  return {
    label: ':windows: :electron: Build',
    timeout_in_minutes: 60,
    command: '.\\.buildkite\\windows\\build-and-upload-debug',
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
  return {
    label: `:${platform}: :electron: Build`,
    timeout_in_minutes: 60,
    command: [
      'gn gen out/Debug --args="import(\"//electron/build/args/debug.gn\")"',
      'gn gen out/Debug "--args=import(\"%BUILD_CONFIG_PATH%\")',
      'gn check out/Debug //electron:electron_lib',
      'gn check out/Debug //electron:electron_app',
      'gn check out/Debug //electron:manifests',
      'gn check out/Debug //electron/shell/common/api:mojo',
      'ninja -C out/Debug electron:electron_app',
      'gn gen out/ffmpeg "--args=import(\"//electron/build/args/ffmpeg.gn\")',
      'ninja -C out/ffmpeg electron:electron_ffmpeg_zip',
      'ninja -C out/Debug electron:electron_dist_zip',
      'ninja -C out/Debug electron:electron_mksnapshot_zip',
      'ninja -C out/Debug electron:electron_chromedriver_zip',
      'ninja -C out/Debug third_party/electron_node:headers',
      'buildkite-agent artifact upload src/out/Debug/dist.zip',
      'buildkite-agent artifact upload src/out/Debug/chromedriver.zip',
      'buildkite-agent artifact upload src/out/ffmpeg/ffmpeg.zip',
      '7z a src/out/Debug/node_headers.zip src/out/Debug/gen/node_headers',
      'buildkite-agent artifact upload src/out/Debug/node_headers.zip',
      'buildkite-agent artifact upload src/out/Debug/mksnapshot.zip',
      'buildkite-agent artifact upload src/out/Debug/electron.lib'
    ],
    agents: [
      `os=${platform}`,
      'queue=electron-build-v7'
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
    buildStepForNix('darwin'),
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
