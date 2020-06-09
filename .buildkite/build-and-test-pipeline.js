function waitStep() {
  return {
    wait: true
  }
}

function buildStepForWindows () {
  return {
    label: ':windows: :electron: Build',
    timeout_in_minutes: 60,
    command: '.\\src\\electron\\.buildkite\\windows\\build-and-upload-release',
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
    command: [`.buildkite/nix/build-and-upload-release.sh ${platform}`],
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
    command: '.\\src\\electron\\.buildkite\\windows\\run-tests',
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
      'queue=electron-build-v7.2'
    ]
  };
}

function generateBuildPipeline () {
  // Do not run the pipeline if a PR has not been raised yet
  // if (process.env.BUILDKITE_PULL_REQUEST === 'false') {
  //   return [];
  // }

  return [
    // buildStepForWindows(),
    buildStepForNix('linux'),
    // buildStepForNix('darwin'),
    waitStep(),
    // testStepForWindows(),
    testStepForNix('linux'),
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
