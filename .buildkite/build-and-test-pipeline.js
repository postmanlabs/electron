function buildStepForWindows () {
  return {
    label: ':windows: :electron: Build',
    command: '.\\.buildkite\\windows\\build-and-upload',
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
  return [
    buildStepForWindows(),
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
