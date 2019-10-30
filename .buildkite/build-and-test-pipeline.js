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
      'queue=electron-build'
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
      'npm run clean',
      'python script/bootstrap.py --dev',
      'python script/build.py -c D', // build in Debug mode
      `zip -ryq out/D-${platform}.zip out/D`,
      `buildkite-agent artifact upload "out/D-${platform}.zip"`,
      'npm run clean-build'
    ],
    agents: [
      `os=${platform}`,
      'queue=electron-build'
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
      'queue=electron-build'
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
    buildStepForNix('linux'),
    buildStepForNix('darwin'),
    waitStep(),
    testStepForWindows(),
    testStepForNix('linux'),
    testStepForNix('darwin'),
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
