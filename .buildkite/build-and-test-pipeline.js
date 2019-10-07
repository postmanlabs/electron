function waitStep() {
  return {
    wait: true
  }
}

function buildStepForWindows () {
  return {
    label: ':windows: :electron: Build',
    timeout_in_minutes: 60,
    command: '.\\.buildkite\\windows\\build-and-upload',
    agents: [
      'os=windows',
      'queue=electron-build'
    ]
  };
}

function buildStepForLinux () {
  return {
    label: ':linux: :electron: Build',
    timeout_in_minutes: 60,
    command: [
      'npm run clean',
      'python script/bootstrap.py --dev',
      'python script/build.py -c D',
      'zip -ryq out/D-linux.zip out/D',
      'buildkite-agent artifact upload "out/D-linux.zip"',
      'npm run clean-build'
    ],
    agents: [
      'os=linux',
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

function testStepForLinux () {
  return {
    label: ':linux: :electron: Test',
    timeout_in_minutes: 60,
    command: ['.buildkite/linux/run-tests.sh'],
    agents: [
      'os=linux',
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
    buildStepForLinux(),
    waitStep(),
    testStepForWindows(),
    testStepForLinux()
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
