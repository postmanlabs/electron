function waitStep() {
  return {
    wait: true
  }
}

function buildStepForWindows (arch) {
  if(arch === 'ia32') {
    return {
      label: ':windows: :electron: Build',
      timeout_in_minutes: 500,
      command: '.\\src\\buildkite-upload-script\\electron\\.buildkite\\windows\\build-and-test ia32',
      agents: [
        'os=windows',
        'queue=electron-build-v11'
      ]
    };
  }
  else {
    return {
      label: ':windows: :electron: Build',
      timeout_in_minutes: 500,
      command: '.\\src\\buildkite-upload-script\\electron\\.buildkite\\windows\\build-and-test x64',
      agents: [
        'os=windows',
        'queue=electron-build-v11'
      ]
    };
  }
}

/**
 * Returns the build step for linux or darwin
 * @param {String} platform can be 'linux' or 'darwin'
 */
function buildStepForNix (platform, arch) {
  if(!process.env.BUILDKITE_BRANCH){
    return [];
  }

  if(platform === 'darwin' && arch === 'arm64' ) {
    return {
      label: `:${platform}: :electron: Build`,
      timeout_in_minutes: 500,
      command: [`.buildkite/nix/build-and-test.sh ${platform} ${arch}`],
      agents: [
        `os=${platform}`,
        'queue=electron-arm-v11'
      ]
    };
  }
  else {
    return {
      label: `:${platform}: :electron: Build`,
      timeout_in_minutes: 500,
      command: [`.buildkite/nix/build-and-test.sh ${platform} ${arch}`],
      agents: [
        `os=${platform}`,
        'queue=electron-build-v11'
      ]
    };
  }
}

function generateBuildPipeline () {
  return [
    buildStepForWindows('ia32'),
    buildStepForWindows('x64'),
    buildStepForNix('linux', 'x64'),
    buildStepForNix('darwin', 'x64'),
    buildStepForNix('darwin', 'arm64')
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
