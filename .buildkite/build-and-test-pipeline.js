function waitStep() {
  return {
    wait: true
  }
}

function buildStepForWindows () {
  return {
    label: ':windows: :electron: Build',
    command: '.\\.buildkite\\windows\\build-and-upload-debug',
    agents: [
      'os=windows',
      'queue=electron-build'
    ]
  };
}

function testStepForWindows () {
  return {
    label: ':windows: :electron: Test',
    command: '.\\.buildkite\\windows\\run-tests',
    agents: [
      'os=windows',
      'queue=electron-build'
    ]
  };
}

function generateBuildPipeline () {
  // Do not run the pipeline if a PR has not been raised yet
  if (process.env.BUILDKITE_PULL_REQUEST === 'false') {
    return [];
  }

  return [
    buildStepForWindows(),
    waitStep(),
    testStepForWindows()
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
