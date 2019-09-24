function buildStepForWindows () {
  return {
    label: ':windows: :electron:',
    command: '.\\.buildkite\\windows\\build',
    agents: [
      'os=windows',
      'queue=electron-build'
    ]
  };
}

function generateBuildPipeline () {
  return [
    buildStepForWindows()
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
