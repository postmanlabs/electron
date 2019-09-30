function buildStepForWindows () {
  return {
    label: ':windows: :electron: Build',
    command: '.\\.buildkite\\windows\\build-and-upload-release',
    agents: [
      'os=windows',
      'queue=electron-build'
    ]
  };
}

function generateReleasePipeline () {
  // Do not run the pipeline if a PR has not been raised yet
  if (process.env.BUILDKITE_PULL_REQUEST === 'false') {
    return [];
  }

  return [
    buildStepForWindows()
  ];
}

function startReleasePipeline () {
  const pipeline = generateReleasePipeline();

  console.log(JSON.stringify(pipeline, null, 4));
}

module.exports = {
  generateReleasePipeline,
  startReleasePipeline
};

!module.parent && startReleasePipeline();
