function waitStep() {
  return {
    wait: true
  }
}

function buildStepForWindows () {
  return {
    label: ':windows: :electron: Build',
    timeout_in_minutes: 300,
    command: '.\\src\\buildkite-upload-script\\electron\\.buildkite\\windows\\electron-test',
    agents: [
      'os=windows',
      'queue=electron-test-v9'
    ]
  };
}

/**
 * Returns the build step for darwin
 * @param {String} platform 'darwin'
 */
function buildStepForLinux (platform) {
  if(!process.env.BUILDKITE_BRANCH){
    return [];
  }

  return {
    label: `:${platform}: :electron: Build`,
    timeout_in_minutes: 300,
    command: [`.buildkite/nix/electron-test.sh ${platform}`],
    agents: [
      `os=${platform}`,
      'queue=electron-test-v9'
    ]
  };
}

/**
 * Returns the build step for linux or darwin
 * @param {String} platform can be 'linux' or 'darwin'
 */
function buildStepForDarwin (platform) {
  if(!process.env.BUILDKITE_BRANCH){
    return [];
  }

  return {
    label: `:${platform}: :electron: Build`,
    timeout_in_minutes: 300,
    command: [`.buildkite/nix/electron-test.sh ${platform}`],
    agents: [
      `os=${platform}`,
      'queue=electron-build-v7'
    ]
  };
}

function generateBuildPipeline () {
  return [
    // buildStepForWindows(),
    buildStepForLinux('linux'),
    // buildStepForDarwin('darwin'),
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
