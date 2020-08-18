function waitStep() {
  return {
    wait: true
  }
}

function buildStepForWindows () {
  return {
    label: ':windows: :electron: Build',
    timeout_in_minutes: 300,
    command: '.\\src\\buildkite-upload-script\\electron\\.buildkite\\windows\\build-and-test',
    agents: [
      'os=windows',
      'queue=electron-build-v9'
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
    timeout_in_minutes: 300,
    command: [`.buildkite/nix/build-and-test.sh ${platform}`],
    agents: [
      `os=${platform}`,
      'queue=electron-build-v7.2'
    ]
  };
}

function generateBuildPipeline () {
  return [
    buildStepForWindows(),
    // buildStepForNix('linux'),
    // buildStepForNix('darwin'),
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
